import '../../../../core/data/evergreen_repository.dart' show mediaUrl;
import '../../../../core/models/backend_models.dart' as backend;

/// The backend's five-state status (`open`, `hold`, `in_progress`,
/// `completed`, `closed`). [TaskStatus] is the design's four-state view.
typedef ServiceStatus = backend.TaskStatus;

/// Workflow status of a task.
///
/// The backend `completed` state (work done, awaiting confirmation) shows as
/// [TaskStatus.closed] with [ApprovalState.completed], as in the design.
enum TaskStatus { open, hold, inProgress, closed }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.open:
        return 'Open';
      case TaskStatus.hold:
        return 'Hold';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.closed:
        return 'Closed';
    }
  }

  String get key => name;

  static TaskStatus fromKey(String? key) {
    // Accept both enum names and the human labels used by the legacy screen.
    switch (key) {
      case 'open':
      case 'Open':
        return TaskStatus.open;
      case 'hold':
      case 'Hold':
        return TaskStatus.hold;
      case 'inProgress':
      case 'In Progress':
        return TaskStatus.inProgress;
      case 'closed':
      case 'Closed':
        return TaskStatus.closed;
      default:
        return TaskStatus.open;
    }
  }
}

/// Business priority, drives SLA hours and sort order.
enum TaskPriority { low, medium, high, critical }

extension TaskPriorityX on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.critical:
        return 'Critical';
    }
  }

  /// Default SLA window in hours per priority.
  int get slaHours {
    switch (this) {
      case TaskPriority.low:
        return 72;
      case TaskPriority.medium:
        return 48;
      case TaskPriority.high:
        return 24;
      case TaskPriority.critical:
        return 8;
    }
  }

  int get rank {
    switch (this) {
      case TaskPriority.critical:
        return 3;
      case TaskPriority.high:
        return 2;
      case TaskPriority.medium:
        return 1;
      case TaskPriority.low:
        return 0;
    }
  }

  String get key => name;

  static TaskPriority fromKey(String? key) {
    return TaskPriority.values.firstWhere(
      (p) => p.name == key,
      orElse: () => TaskPriority.medium,
    );
  }

  static TaskPriority fromBackend(backend.TaskPriorityLevel p) {
    switch (p) {
      case backend.TaskPriorityLevel.low:
        return TaskPriority.low;
      case backend.TaskPriorityLevel.medium:
        return TaskPriority.medium;
      case backend.TaskPriorityLevel.high:
        return TaskPriority.high;
      case backend.TaskPriorityLevel.critical:
        return TaskPriority.critical;
    }
  }
}

/// Approval workflow state:
/// requested (by client) -> approved (manager) -> assigned -> inService
/// -> completed (technician) -> confirmed (client confirms/rates).
enum ApprovalState {
  requested,
  approved,
  assigned,
  inService,
  completed,
  confirmed,
  rejected,
}

extension ApprovalStateX on ApprovalState {
  String get label {
    switch (this) {
      case ApprovalState.requested:
        return 'Requested';
      case ApprovalState.approved:
        return 'Approved';
      case ApprovalState.assigned:
        return 'Assigned';
      case ApprovalState.inService:
        return 'In Service';
      case ApprovalState.completed:
        return 'Completed';
      case ApprovalState.confirmed:
        return 'Confirmed';
      case ApprovalState.rejected:
        return 'Rejected';
    }
  }

  String get key => name;

  static ApprovalState fromKey(String? key) {
    return ApprovalState.values.firstWhere(
      (s) => s.name == key,
      orElse: () => ApprovalState.requested,
    );
  }

  static ApprovalState fromBackend(backend.ApprovalStage a) {
    switch (a) {
      case backend.ApprovalStage.requested:
        return ApprovalState.requested;
      case backend.ApprovalStage.approved:
        return ApprovalState.approved;
      case backend.ApprovalStage.assigned:
        return ApprovalState.assigned;
      case backend.ApprovalStage.inService:
        return ApprovalState.inService;
      case backend.ApprovalStage.completed:
        return ApprovalState.completed;
      case backend.ApprovalStage.confirmed:
        return ApprovalState.confirmed;
      case backend.ApprovalStage.rejected:
        return ApprovalState.rejected;
    }
  }
}

/// Null when [value] is a valid contact number: 10–15 digits, optionally
/// prefixed with '+'. Spaces and dashes are ignored.
String? validateContactPhone(String value) {
  final v = normalizeContactPhone(value);
  if (v.isEmpty) return 'Please enter a mobile number';
  if (!RegExp(r'^\+?\d{10,15}$').hasMatch(v)) {
    return 'Enter a valid mobile number (10–15 digits)';
  }
  return null;
}

/// [value] with spaces and dashes removed.
String normalizeContactPhone(String value) =>
    value.trim().replaceAll(RegExp(r'[\s-]'), '');

/// The Ticket Queue's three tabs.
enum QueueBucket { unassigned, awaiting, assigned }

/// A ticket as the UI sees it. Built from a backend [backend.ServiceTask]
/// (see [TaskItem.fromService]); [source] keeps the full row so screens can
/// read ids, hold reasons, feedback, etc.
class TaskItem {
  /// Backend `tasks.id` as a string (used in `/task-details/:taskId`).
  final String id;
  final String title;
  final String equipment;
  final String companyName;
  final String ticketNo;
  final TaskStatus status;
  final TaskPriority priority;
  final ApprovalState approval;
  final String assignee; // technician name or '-' if unassigned
  final String managerName; // manager overseeing the task
  final String clientName;
  final DateTime createdAt;
  final DateTime? assignedAt; // when a technician was assigned
  final DateTime? acceptedAt; // when that technician accepted/claimed it
  final DateTime? dueDate;
  final DateTime? closedAt;
  final bool escalated;
  final int? rating; // 1..5, set by client on confirm
  final String? feedback;
  final List<String> attachments; // task image URLs
  final String imageUrl;
  final String? resolutionNotes; // technician's work-done summary
  final DateTime? startedAt; // when the technician began work on-site
  final DateTime? resolvedAt; // when the technician marked work complete

  /// Person / address of an individual ticket ('' for equipment tickets).
  final String contactName;
  final String contactPhone;
  final String address;
  final backend.ServiceTask? source;

  const TaskItem({
    required this.id,
    required this.title,
    required this.equipment,
    required this.companyName,
    required this.ticketNo,
    required this.status,
    this.priority = TaskPriority.medium,
    this.approval = ApprovalState.assigned,
    this.assignee = '-',
    this.managerName = '',
    this.clientName = '',
    required this.createdAt,
    this.assignedAt,
    this.acceptedAt,
    this.dueDate,
    this.closedAt,
    this.escalated = false,
    this.rating,
    this.feedback,
    this.attachments = const [],
    this.imageUrl = 'assets/images/login_bg.png',
    this.resolutionNotes,
    this.startedAt,
    this.resolvedAt,
    this.contactName = '',
    this.contactPhone = '',
    this.address = '',
    this.source,
  });

  factory TaskItem.fromService(backend.ServiceTask t) {
    final images = t.images.map(mediaUrl).where((u) => u.isNotEmpty).toList();
    final equipmentImage = mediaUrl(t.equipment?.imageUrl);
    final tech = t.technician;
    final hasTech = tech != null;
    final finished = t.status == ServiceStatus.completed ||
        t.status == ServiceStatus.closed;
    return TaskItem(
      id: '${t.id}',
      title: t.name.isNotEmpty ? t.name : 'Ticket ${t.ticketNo}',
      equipment: t.equipment?.name ?? '',
      companyName: t.company?.displayName ?? '',
      ticketNo: t.ticketNo,
      status: _designStatus(t.status),
      priority: TaskPriorityX.fromBackend(t.priority),
      approval: ApprovalStateX.fromBackend(t.approval),
      // An assigned engineer without a name still owns the ticket.
      assignee: !hasTech
          ? '-'
          : tech.name.trim().isNotEmpty
              ? tech.name
              : tech.phone.trim().isNotEmpty
                  ? tech.phone
                  : 'Service Engineer #${tech.id}',
      managerName: t.manager?.name ?? '',
      clientName: t.client?.name ?? '',
      createdAt:
          t.createdAt ?? t.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      assignedAt: hasTech ? t.assignedAt : null,
      acceptedAt: hasTech ? t.acceptedAt : null,
      dueDate: t.dueDate,
      // Rows closed before close times were recorded fall back to the
      // resolution time, then to the row's last update.
      closedAt: finished
          ? t.closedAt ??
              t.resolvedAt ??
              (t.status == ServiceStatus.closed ? t.updatedAt : null)
          : null,
      escalated: t.escalated,
      rating: t.rating,
      feedback: t.feedback,
      attachments: images,
      imageUrl: images.isNotEmpty
          ? images.first
          : equipmentImage.isNotEmpty
              ? equipmentImage
              : 'assets/images/login_bg.png',
      resolutionNotes: t.resolutionNotes ?? t.actionTaken,
      startedAt: t.startedAt,
      resolvedAt: t.resolvedAt,
      contactName: t.contactName ?? '',
      contactPhone: t.contactPhone ?? '',
      address: t.address ?? '',
      source: t,
    );
  }

  static TaskStatus _designStatus(ServiceStatus s) {
    switch (s) {
      case ServiceStatus.open:
        return TaskStatus.open;
      case ServiceStatus.hold:
        return TaskStatus.hold;
      case ServiceStatus.inProgress:
        return TaskStatus.inProgress;
      case ServiceStatus.completed:
      case ServiceStatus.closed:
        return TaskStatus.closed;
    }
  }

  // ---- Backend views ----

  /// Exact backend status, including `completed`.
  ServiceStatus get serviceStatus {
    final s = source;
    if (s != null) return s.status;
    switch (status) {
      case TaskStatus.open:
        return ServiceStatus.open;
      case TaskStatus.hold:
        return ServiceStatus.hold;
      case TaskStatus.inProgress:
        return ServiceStatus.inProgress;
      case TaskStatus.closed:
        return approval == ApprovalState.completed
            ? ServiceStatus.completed
            : ServiceStatus.closed;
    }
  }

  /// Backend `tasks.id`.
  int get taskId => source?.id ?? int.tryParse(id) ?? 0;

  /// Backend `task_user.id` of the latest assignment row.
  int? get taskUserId => source?.taskUserId;

  int? get technicianId => source?.technician?.id;
  String get technicianPhone => source?.technician?.phone ?? '';
  int? get managerId => source?.manager?.id;
  int? get clientId => source?.client?.id;
  String get clientPhone => source?.client?.phone ?? '';
  int? get companyId => source?.company?.id ?? source?.equipment?.companyId;
  int? get equipmentId => source?.equipment?.id;
  backend.CallType? get callType => source?.callType;
  backend.HoldReason? get activeHold => source?.activeHold;
  String get description => source?.description ?? '';
  String? get escalationReason => source?.escalationReason;
  String? get rejectionReason => source?.rejectionReason;

  /// Work done, awaiting confirmation (backend `completed`).
  bool get isCompleted => serviceStatus == ServiceStatus.completed;

  /// Raised for a person (contact + address) instead of company equipment.
  bool get isIndividual {
    final s = source;
    if (s != null) return s.isIndividual;
    return equipment.isEmpty && companyName.isEmpty && contactName.isNotEmpty;
  }

  /// Who / where the ticket is for: the company for equipment tickets, the
  /// contact person for individual ones.
  String get partyName => isIndividual ? contactName : companyName;

  /// Case-insensitive free-text match used by the task lists' search bars.
  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      title,
      equipment,
      companyName,
      assignee,
      clientName,
      ticketNo,
      lifecycleLabel,
      priority.label,
      contactName,
      contactPhone,
      address,
    ].any((f) => f.toLowerCase().contains(q));
  }

  bool get isBreakdown => callType == backend.CallType.breakdown;

  /// SLA deadline = createdAt + priority SLA (or explicit dueDate).
  DateTime get slaDeadline =>
      dueDate ?? createdAt.add(Duration(hours: priority.slaHours));

  bool get isClosed => status == TaskStatus.closed;

  /// True when no technician owns the ticket yet (raised but not accepted).
  bool get isUnassigned => !isClosed && (assignee.isEmpty || assignee == '-');

  /// Open and assigned to a technician but work hasn't started yet.
  /// Drives the "Assigned" group within the Open tab.
  bool get isAssignedNotStarted =>
      status == TaskStatus.open && hasAssignee && startedAt == null;

  /// A human label for the task's position in the lifecycle, used by the
  /// board grouping and the details timeline:
  /// Open -> Not Assigned -> Assigned -> In Progress -> Hold -> Closed.
  String get lifecycleLabel {
    switch (status) {
      case TaskStatus.closed:
        return 'Closed';
      case TaskStatus.hold:
        return 'Hold';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.open:
        return hasAssignee ? 'Assigned' : 'Not Assigned';
    }
  }

  /// Whether the technician has submitted a resolution (work complete).
  bool get isResolved => resolvedAt != null || resolutionNotes != null;

  /// Minutes a technician has to accept an assigned ticket before it is
  /// considered stale and should be auto-reassigned.
  static const int acceptanceWindowMinutes = 5;

  bool get hasAssignee => assignee.isNotEmpty && assignee != '-';

  /// Accepted explicitly, or implicitly by starting / progressing the work.
  bool get isAccepted =>
      acceptedAt != null || startedAt != null || status != TaskStatus.open;

  /// Assigned to someone but they haven't accepted yet (still open).
  bool get isAwaitingAcceptance => !isClosed && hasAssignee && !isAccepted;

  /// Ticket queue tab the ticket belongs to, or null once the work is done
  /// (backend `completed` / `closed`). Every other ticket is in exactly one:
  /// no Service Engineer -> unassigned; assigned, open, never accepted or
  /// started -> awaiting; otherwise (accepted, started, in progress or on
  /// hold) -> assigned.
  QueueBucket? get queueBucket {
    if (isClosed) return null;
    if (!hasAssignee) return QueueBucket.unassigned;
    return isAccepted ? QueueBucket.assigned : QueueBucket.awaiting;
  }

  /// When the current assignment started. Rows assigned before
  /// `assigned_at` was recorded fall back to the assignment row's update
  /// time, then to the ticket's creation.
  DateTime get assignedSince =>
      assignedAt ?? source?.updatedAt ?? createdAt;

  /// Minutes elapsed since assignment while still unaccepted (0 if n/a).
  int pendingAcceptanceMinutes([DateTime? now]) {
    if (!isAwaitingAcceptance) return 0;
    final mins = (now ?? DateTime.now()).difference(assignedSince).inMinutes;
    return mins < 0 ? 0 : mins;
  }

  /// Assigned but not accepted past the acceptance window — a candidate for
  /// auto / manual reassignment.
  bool isAcceptanceOverdue([DateTime? now]) =>
      isAwaitingAcceptance &&
      pendingAcceptanceMinutes(now) >= acceptanceWindowMinutes;

  /// Overdue when past SLA deadline and not yet closed.
  bool isOverdue([DateTime? now]) {
    if (isClosed) return false;
    return (now ?? DateTime.now()).isAfter(slaDeadline);
  }

  /// Hours remaining to SLA (negative when overdue).
  int hoursToSla([DateTime? now]) {
    return slaDeadline.difference(now ?? DateTime.now()).inHours;
  }

  /// Resolution time in hours for closed tasks.
  int? get resolutionHours => closedAt?.difference(createdAt).inHours;

  TaskItem copyWith({
    String? title,
    String? equipment,
    String? companyName,
    String? ticketNo,
    TaskStatus? status,
    TaskPriority? priority,
    ApprovalState? approval,
    String? assignee,
    String? managerName,
    String? clientName,
    DateTime? createdAt,
    DateTime? assignedAt,
    DateTime? acceptedAt,
    DateTime? dueDate,
    DateTime? closedAt,
    bool? escalated,
    int? rating,
    String? feedback,
    List<String>? attachments,
    String? imageUrl,
    String? resolutionNotes,
    DateTime? startedAt,
    DateTime? resolvedAt,
    String? contactName,
    String? contactPhone,
    String? address,
    // Explicit null-outs (copyWith's ?? cannot clear a nullable field).
    bool clearAssignedAt = false,
    bool clearAcceptedAt = false,
    bool clearStartedAt = false,
    bool clearResolvedAt = false,
    bool clearResolutionNotes = false,
    bool clearClosedAt = false,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      equipment: equipment ?? this.equipment,
      companyName: companyName ?? this.companyName,
      ticketNo: ticketNo ?? this.ticketNo,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      approval: approval ?? this.approval,
      assignee: assignee ?? this.assignee,
      managerName: managerName ?? this.managerName,
      clientName: clientName ?? this.clientName,
      createdAt: createdAt ?? this.createdAt,
      assignedAt: clearAssignedAt ? null : (assignedAt ?? this.assignedAt),
      acceptedAt: clearAcceptedAt ? null : (acceptedAt ?? this.acceptedAt),
      dueDate: dueDate ?? this.dueDate,
      closedAt: clearClosedAt ? null : (closedAt ?? this.closedAt),
      escalated: escalated ?? this.escalated,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
      attachments: attachments ?? this.attachments,
      imageUrl: imageUrl ?? this.imageUrl,
      resolutionNotes: clearResolutionNotes
          ? null
          : (resolutionNotes ?? this.resolutionNotes),
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      resolvedAt: clearResolvedAt ? null : (resolvedAt ?? this.resolvedAt),
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      address: address ?? this.address,
      source: source,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'equipment': equipment,
        'companyName': companyName,
        'ticketNo': ticketNo,
        'status': status.key,
        'priority': priority.key,
        'approval': approval.key,
        'assignee': assignee,
        'managerName': managerName,
        'clientName': clientName,
        'createdAt': createdAt.toIso8601String(),
        'assignedAt': assignedAt?.toIso8601String(),
        'acceptedAt': acceptedAt?.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'closedAt': closedAt?.toIso8601String(),
        'escalated': escalated,
        'rating': rating,
        'feedback': feedback,
        'attachments': attachments,
        'imageUrl': imageUrl,
        'resolutionNotes': resolutionNotes,
        'startedAt': startedAt?.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'contactName': contactName,
        'contactPhone': contactPhone,
        'address': address,
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) =>
        json[key] == null ? null : DateTime.tryParse(json[key] as String);
    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      equipment: json['equipment'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      ticketNo: json['ticketNo'] as String? ?? '',
      status: TaskStatusX.fromKey(json['status'] as String?),
      priority: TaskPriorityX.fromKey(json['priority'] as String?),
      approval: ApprovalStateX.fromKey(json['approval'] as String?),
      assignee: json['assignee'] as String? ?? '-',
      managerName: json['managerName'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      createdAt:
          date('createdAt') ?? DateTime.fromMillisecondsSinceEpoch(0),
      assignedAt: date('assignedAt'),
      acceptedAt: date('acceptedAt'),
      dueDate: date('dueDate'),
      closedAt: date('closedAt'),
      escalated: json['escalated'] as bool? ?? false,
      rating: json['rating'] as int?,
      feedback: json['feedback'] as String?,
      attachments:
          (json['attachments'] as List<dynamic>?)?.cast<String>() ?? const [],
      imageUrl: json['imageUrl'] as String? ?? 'assets/images/login_bg.png',
      resolutionNotes: json['resolutionNotes'] as String?,
      startedAt: date('startedAt'),
      resolvedAt: date('resolvedAt'),
      contactName: json['contactName'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }
}
