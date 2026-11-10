import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/evergreen_repository.dart';
import '../../../core/models/backend_models.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/pm_schedule.dart';
import '../domain/pm_occurrences.dart';

/// The recurring PM schedules and the maintenance visits generated from them.
class PmState {
  final List<PmSchedule> schedules;
  final List<PmGeneratedTask> generated;

  const PmState({this.schedules = const [], this.generated = const []});

  PmState copyWith({
    List<PmSchedule>? schedules,
    List<PmGeneratedTask>? generated,
  }) {
    return PmState(
      schedules: schedules ?? this.schedules,
      generated: generated ?? this.generated,
    );
  }
}

final pmApiProvider = Provider<PmApi>((ref) {
  return PmApi(ref.watch(apiClientProvider));
});

/// PM schedule endpoints. Admins manage; anyone with company access reads.
class PmApi {
  final ApiClient api;

  PmApi(this.api);

  Future<List<PmSchedule>> getSchedules({int? companyId}) async {
    final body = unwrap(
      await api.post<dynamic>(
        'user/getPmSchedules',
        data: {if (companyId != null) 'company_link': companyId},
      ),
    );
    return dataList(body).map(PmSchedule.fromBackend).toList();
  }

  Future<List<PmGeneratedTask>> getGenerated({int? scheduleId}) async {
    final body = unwrap(
      await api.post<dynamic>(
        'user/getPmGeneratedTasks',
        data: {if (scheduleId != null) 'schedule_link': scheduleId},
      ),
    );
    return dataList(body).map(PmGeneratedTask.fromBackend).toList();
  }

  Future<void> create({
    required int equipmentId,
    required PmFrequency frequency,
    required DateTime nextDue,
  }) async {
    unwrap(
      await api.post<dynamic>(
        'user/createPmSchedule',
        data: {
          'equipment_link': equipmentId,
          'frequency': frequency.backendKey,
          'next_due': _day(nextDue),
        },
      ),
    );
  }

  Future<void> update(
    int scheduleId, {
    PmFrequency? frequency,
    DateTime? nextDue,
    bool? isActive,
  }) async {
    unwrap(
      await api.post<dynamic>(
        'user/updatePmSchedule',
        data: {
          'pm_schedule_link': scheduleId,
          if (frequency != null) 'frequency': frequency.backendKey,
          if (nextDue != null) 'next_due': _day(nextDue),
          if (isActive != null) 'is_active': isActive,
        },
      ),
    );
  }

  Future<void> delete(int scheduleId) async {
    unwrap(
      await api.post<dynamic>(
        'user/deletePmSchedule',
        data: {'pm_schedule_link': scheduleId},
      ),
    );
  }

  /// Generates visits (tasks) for active schedules due within [daysAhead]
  /// days and returns the generated rows.
  Future<List<PmGeneratedTask>> generate({int daysAhead = 0}) async {
    final body = unwrap(
      await api.post<dynamic>(
        'user/generatePmTasks',
        data: {'days_ahead': daysAhead},
      ),
    );
    return dataList(body).map(PmGeneratedTask.fromBackend).toList();
  }

  static String _day(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).toIso8601String();
}

final pmProvider = FutureProvider.autoDispose<PmState>((ref) async {
  final api = ref.watch(pmApiProvider);
  final results = await Future.wait([api.getSchedules(), api.getGenerated()]);
  final generated = results[1] as List<PmGeneratedTask>
    ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
  return PmState(
    schedules: results[0] as List<PmSchedule>,
    generated: generated,
  );
});

/// Upcoming active schedules sorted by nextDue.
final pmUpcomingProvider = Provider.autoDispose<List<PmSchedule>>((ref) {
  final schedules = ref.watch(pmProvider).valueOrNull?.schedules ?? const [];
  final list = schedules.where((s) => s.active).toList()
    ..sort((a, b) => a.nextDue.compareTo(b.nextDue));
  return list;
});

/// Everything the upcoming-maintenance list is computed from.
class PmDueSources {
  final List<Equipment> equipments;
  final List<PmSchedule> schedules;
  final Map<int, PmVisit> lastVisits;

  const PmDueSources({
    this.equipments = const [],
    this.schedules = const [],
    this.lastVisits = const {},
  });
}

/// All equipment (required) plus PM tasks and schedules (best effort: a
/// failure there only loses the visit anchors / schedule rows).
final pmDueSourcesProvider =
    FutureProvider.autoDispose<PmDueSources>((ref) async {
  final equipmentsFuture = ref.watch(equipmentsProvider(null).future);
  final tasksFuture = ref
      .watch(tasksProvider.future)
      .then<List<ServiceTask>?>((v) => v)
      .catchError((Object _) => null);
  final pmFuture = ref
      .watch(pmProvider.future)
      .then<PmState?>((v) => v)
      .catchError((Object _) => null);
  final equipments = await equipmentsFuture;
  final tasks = await tasksFuture ?? const <ServiceTask>[];
  final pm = await pmFuture ?? const PmState();
  return PmDueSources(
    equipments: equipments,
    schedules: pm.schedules,
    lastVisits: lastPmVisits(tasks: tasks, generated: pm.generated),
  );
});

/// Equipment that can get a schedule (for the New Schedule sheet).
final pmEquipmentOptionsProvider =
    FutureProvider.autoDispose<List<Equipment>>((ref) {
  return ref.watch(equipmentsProvider(null).future);
});
