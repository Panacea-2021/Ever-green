import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/evergreen_repository.dart';
import '../../../core/models/backend_models.dart' hide TaskStatus;
import '../domain/models/task_item.dart';

/// Tickets from `user/getAllTasks` (already scoped per role by the backend)
/// as [TaskItem]s, with loading / error state. Screens that need a spinner or
/// retry watch this; refresh with `ref.invalidate(tasksProvider)`.
final taskItemsProvider = Provider.autoDispose<AsyncValue<List<TaskItem>>>((ref) {
  return ref
      .watch(tasksProvider)
      .whenData((tasks) => tasks.map(TaskItem.fromService).toList());
});

/// Single source of truth for tasks across the app's feature set (SLA,
/// escalation, approvals, ratings, performance, search): the current ticket
/// list, empty while loading or on error.
final taskProvider = Provider.autoDispose<List<TaskItem>>((ref) {
  return ref.watch(taskItemsProvider).valueOrNull ?? const [];
});

/// Tasks that are overdue (past SLA, not closed).
final overdueTasksProvider = Provider.autoDispose<List<TaskItem>>((ref) {
  final tasks = ref.watch(taskProvider);
  return tasks.where((t) => t.isOverdue()).toList()
    ..sort((a, b) => a.slaDeadline.compareTo(b.slaDeadline));
});

/// Tasks flagged as escalated to a Manager.
final escalatedTasksProvider = Provider.autoDispose<List<TaskItem>>((ref) {
  return ref.watch(taskProvider).where((t) => t.escalated).toList();
});

/// Splits tickets into the Ticket Queue tabs (see [TaskItem.queueBucket]).
/// Unassigned: overdue, then highest priority, then oldest first. Awaiting:
/// longest-waiting first (most at risk of breaching the acceptance window).
/// Assigned: highest priority, then oldest first.
Map<QueueBucket, List<TaskItem>> queueBuckets(
  Iterable<TaskItem> tasks, [
  DateTime? now,
]) {
  final buckets = {for (final b in QueueBucket.values) b: <TaskItem>[]};
  for (final t in tasks) {
    final b = t.queueBucket;
    if (b != null) buckets[b]!.add(t);
  }
  int byPriorityThenAge(TaskItem a, TaskItem b) {
    if (a.priority.rank != b.priority.rank) {
      return b.priority.rank - a.priority.rank;
    }
    return a.createdAt.compareTo(b.createdAt);
  }

  buckets[QueueBucket.unassigned]!.sort((a, b) {
    final ao = a.isOverdue(now) ? 1 : 0;
    final bo = b.isOverdue(now) ? 1 : 0;
    if (ao != bo) return bo - ao;
    return byPriorityThenAge(a, b);
  });
  buckets[QueueBucket.awaiting]!.sort(
    (a, b) => b
        .pendingAcceptanceMinutes(now)
        .compareTo(a.pendingAcceptanceMinutes(now)),
  );
  buckets[QueueBucket.assigned]!.sort(byPriorityThenAge);
  return buckets;
}

final _queueBucketsProvider =
    Provider.autoDispose<Map<QueueBucket, List<TaskItem>>>((ref) {
  return queueBuckets(ref.watch(taskProvider));
});

/// Tickets with no Service Engineer yet (not completed / closed), overdue
/// and highest priority first.
final unassignedTasksProvider = Provider.autoDispose<List<TaskItem>>((ref) {
  return ref.watch(_queueBucketsProvider)[QueueBucket.unassigned]!;
});

/// Count of unassigned tickets, for badges on the home/queue entry points.
final unassignedCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(unassignedTasksProvider).length;
});

/// Tickets assigned to a Service Engineer but not yet accepted or started
/// (still open), longest-waiting first.
final awaitingAcceptanceProvider = Provider.autoDispose<List<TaskItem>>((ref) {
  return ref.watch(_queueBucketsProvider)[QueueBucket.awaiting]!;
});

/// Tickets a Service Engineer has accepted or started and not finished.
final assignedQueueProvider = Provider.autoDispose<List<TaskItem>>((ref) {
  return ref.watch(_queueBucketsProvider)[QueueBucket.assigned]!;
});

/// Tickets assigned but NOT accepted within the acceptance window — the
/// "mostly we will reassign" bucket.
final acceptanceOverdueProvider = Provider.autoDispose<List<TaskItem>>((ref) {
  return ref.watch(taskProvider).where((t) => t.isAcceptanceOverdue()).toList();
});

/// Per-technician performance stats derived from the task list.
class TechnicianStats {
  final String name;
  final int? technicianId;
  final int active; // open/hold/in-progress assigned
  final int completed;
  final double avgResolutionHours;
  final double avgRating;

  const TechnicianStats({
    required this.name,
    this.technicianId,
    required this.active,
    required this.completed,
    required this.avgResolutionHours,
    required this.avgRating,
  });

  /// Simple over-load heuristic used by the assignment guard.
  bool get isOverloaded => active >= 3;
}

final technicianStatsProvider = Provider.autoDispose<List<TechnicianStats>>((ref) {
  final tasks = ref.watch(taskProvider);
  final byTech = <int, List<TaskItem>>{};
  for (final t in tasks) {
    final id = t.technicianId;
    if (id == null || !t.hasAssignee) continue;
    byTech.putIfAbsent(id, () => []).add(t);
  }
  final stats = <TechnicianStats>[];
  byTech.forEach((id, list) {
    final completed = list.where((t) => t.isClosed).toList();
    final active = list.where((t) => !t.isClosed).length;
    final resolutions =
        completed.map((t) => t.resolutionHours).whereType<int>().toList();
    final ratings = completed.map((t) => t.rating).whereType<int>().toList();
    stats.add(
      TechnicianStats(
        name: list.first.assignee,
        technicianId: id,
        active: active,
        completed: completed.length,
        avgResolutionHours: resolutions.isEmpty
            ? 0
            : resolutions.reduce((a, b) => a + b) / resolutions.length,
        avgRating: ratings.isEmpty
            ? 0
            : ratings.reduce((a, b) => a + b) / ratings.length,
      ),
    );
  });
  stats.sort((a, b) => b.active.compareTo(a.active));
  return stats;
});

/// Screenshots a technician has picked for a ticket (local file paths, keyed
/// by task id). They are uploaded with the work report on "Complete Work".
final pendingScreenshotsProvider =
    StateProvider<Map<String, List<String>>>((ref) => const {});

final taskActionsProvider = Provider<TaskActions>((ref) => TaskActions(ref));

/// Ticket mutations against the EverGreen backend. Every call throws a
/// [FailureException] on failure and refreshes [tasksProvider] on success.
class TaskActions {
  TaskActions(this._ref);

  final Ref _ref;

  EvergreenRepository get _repo => _ref.read(evergreenRepositoryProvider);

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final result = unwrap(await _repo.api.post<dynamic>(path, data: body));
    _ref.invalidate(tasksProvider);
    return result;
  }

  int _taskUserLink(TaskItem t) {
    final id = t.taskUserId;
    if (id == null) {
      throw const RepositoryException('This ticket has no assignment record');
    }
    return id;
  }

  Future<List<String>> _upload(List<String> paths, String folder) async {
    final urls = <String>[];
    for (final p in paths) {
      urls.add(await _repo.uploadFile(p, folderName: folder));
    }
    return urls;
  }

  /// A due date is due by the end of that local day.
  static String _date(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59).toUtc().toIso8601String();

  /// Creates a ticket; the backend generates the ticket number.
  Future<void> create({
    required int equipmentId,
    required String name,
    required String description,
    required CallType callType,
    required int clientId,
    TaskPriority? priority,
    DateTime? dueDate,
    List<String> imagePaths = const [],
  }) async {
    final images = await _upload(imagePaths, 'tasks');
    await _post('user/createTask', {
      'equipment_link': equipmentId,
      'name': name,
      'description': description,
      'call_type': callType.key,
      'client_link': clientId,
      'images': images,
      if (priority != null) 'priority': priority.key,
      if (dueDate != null) 'due_date': _date(dueDate),
    });
  }

  /// Body of an individual ticket: no company or equipment, just the person
  /// and address the work is for.
  static Map<String, dynamic> individualTaskBody({
    required String name,
    required String description,
    CallType? callType,
    TaskPriority? priority,
    required String contactName,
    required String contactPhone,
    required String address,
    List<String> images = const [],
  }) =>
      {
        'name': name,
        'description': description,
        if (callType != null) 'call_type': callType.key,
        if (priority != null) 'priority': priority.key,
        'contact_name': contactName,
        'contact_phone': contactPhone,
        'address': address,
        'images': images,
      };

  /// Creates an individual ticket (no `equipment_link`).
  Future<void> createIndividual({
    required String name,
    required String description,
    CallType? callType,
    TaskPriority? priority,
    required String contactName,
    required String contactPhone,
    required String address,
    List<String> imagePaths = const [],
  }) async {
    final images = await _upload(imagePaths, 'tasks');
    await _post(
      'user/createTask',
      individualTaskBody(
        name: name,
        description: description,
        callType: callType,
        priority: priority,
        contactName: contactName,
        contactPhone: contactPhone,
        address: address,
        images: images,
      ),
    );
  }

  Future<void> update(
    TaskItem t, {
    String? name,
    String? description,
    CallType? callType,
    int? equipmentId,
    TaskPriority? priority,
    DateTime? dueDate,
    String? contactName,
    String? contactPhone,
    String? address,
  }) async {
    await _post('user/updateTask', {
      'task_link': t.taskId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (callType != null) 'call_type': callType.key,
      if (equipmentId != null) 'equipment_link': equipmentId,
      if (priority != null) 'priority': priority.key,
      if (dueDate != null) 'due_date': _date(dueDate),
      if (contactName != null) 'contact_name': contactName,
      if (contactPhone != null) 'contact_phone': contactPhone,
      if (address != null) 'address': address,
    });
  }

  Future<void> delete(TaskItem t) async {
    await _post('user/deleteTask', {'task_link': t.taskId});
  }

  /// Assigns (or reassigns) the ticket to a technician.
  Future<void> assign(TaskItem t, int technicianId) async {
    await _post('user/assignTechnician', {
      'task_link': t.taskId,
      'technician_link': technicianId,
    });
  }

  /// Returns the ticket to the unassigned queue.
  Future<void> unassign(TaskItem t) async {
    await _post('user/unassignTask', {'task_link': t.taskId});
  }

  /// The assigned technician acknowledges the ticket.
  Future<void> accept(TaskItem t) async {
    await _post('user/acceptTask', {'task_link': t.taskId});
  }

  /// Approves a client-raised request (requested -> approved).
  Future<void> approveRequest(TaskItem t, {String? note}) async {
    await _post('user/approveTask', {
      'task_link': t.taskId,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  /// Rejects a client-raised request; the backend closes the ticket.
  Future<void> rejectRequest(TaskItem t, {required String reason}) async {
    await _post('user/rejectTask', {'task_link': t.taskId, 'reason': reason});
  }

  Future<void> escalate(TaskItem t, {required String reason}) async {
    await _post('user/escalateTask', {'task_link': t.taskId, 'reason': reason});
  }

  /// Moves the ticket to [status] (`updateTaskStatus`). Use [startWork] and
  /// [hold] for the transitions that carry hold-reason data.
  Future<void> setStatus(TaskItem t, ServiceStatus status) async {
    await _post('user/updateTaskStatus', {
      'task_user_link': _taskUserLink(t),
      'status': status.key,
    });
  }

  /// Moves an open ticket to In Progress, or resumes one that is on hold
  /// (releasing the active hold reason).
  Future<void> startWork(TaskItem t) async {
    final hold = t.activeHold;
    await _post('user/updateTaskStatus', {
      'task_user_link': _taskUserLink(t),
      'status': ServiceStatus.inProgress.key,
      if (t.serviceStatus == ServiceStatus.hold && hold != null)
        'hold': {'release_from_hold': true, 'hold_reason_link': hold.id},
    });
  }

  /// Puts the ticket on hold with a reason. The backend keys hold reasons by
  /// (type, spare part number, task), so the part number is sent as '' when
  /// not applicable.
  Future<void> hold(
    TaskItem t, {
    required HoldType type,
    String sparePartNumber = '',
    String reason = '',
    String? imagePath,
  }) async {
    final image = imagePath == null
        ? null
        : (await _upload([imagePath], 'out_images')).first;
    await _post('user/updateTaskStatus', {
      'task_user_link': _taskUserLink(t),
      'status': ServiceStatus.hold.key,
      'reason': reason.isEmpty ? type.label : reason,
      'hold': {
        'hold_reason': type.key,
        'spare_part_number': sparePartNumber,
        'reason': reason.isEmpty ? type.label : reason,
        if (image != null) 'image': image,
      },
    });
  }

  /// Edits the active hold reason of a ticket that is already on hold.
  Future<void> updateHold(
    HoldReason current, {
    required HoldType type,
    String sparePartNumber = '',
    String reason = '',
    String? imagePath,
  }) async {
    final image = imagePath == null
        ? current.image
        : (await _upload([imagePath], 'out_images')).first;
    await _post('user/updateHoldReasons', {
      'hold_reason_link': current.id,
      'hold_reason': type.key,
      'spare_part_number': sparePartNumber,
      'reason': reason.isEmpty ? type.label : reason,
      if (image != null) 'image': image,
    });
  }

  /// Submits the technician's work report. For the assigned technician the
  /// backend moves the ticket to Completed; admins completing on their behalf
  /// also need an explicit status change.
  Future<void> complete(
    TaskItem t, {
    required String actionTaken,
    String requirementDetails = '',
    bool followUp = false,
    List<String> imagePaths = const [],
    required bool asTechnician,
  }) async {
    final images = await _upload(imagePaths, 'out_images');
    await _post('user/updateTaskFeedback', {
      'task_link': t.taskId,
      'action_taken': actionTaken,
      'req_details': requirementDetails,
      'follow_up': followUp,
      'out_images': images,
    });
    if (!asTechnician) {
      await _post('user/updateTaskStatus', {
        'task_user_link': _taskUserLink(t),
        'status': ServiceStatus.completed.key,
      });
    }
  }

  /// Confirms completed work with a rating and closes the ticket
  /// (`clientSignatureForReport`).
  Future<void> confirm(
    TaskItem t, {
    required int rating,
    String? feedback,
    bool? serviceSatisfactory,
    bool? isRunningSmoothly,
  }) async {
    await _post('user/clientSignatureForReport', {
      'task_link': t.taskId,
      'rating': rating,
      if (feedback != null && feedback.isNotEmpty) 'feedback': feedback,
      if (serviceSatisfactory != null)
        'service_satisfactory': serviceSatisfactory,
      if (isRunningSmoothly != null) 'is_running_smoothly': isRunningSmoothly,
    });
  }

  /// The backend-generated service report PDF (admin only).
  Future<Uint8List> serviceReportPdf(TaskItem t) async {
    final body = unwrap(
      await _repo.api.post<dynamic>(
        'user/getServiceReport',
        data: {'task_link': t.taskId},
      ),
    );
    final encoded = body is Map ? body['pdf_base64']?.toString() : null;
    if (encoded == null || encoded.isEmpty) {
      throw const RepositoryException('The service report could not be generated');
    }
    return base64Decode(encoded);
  }
}
