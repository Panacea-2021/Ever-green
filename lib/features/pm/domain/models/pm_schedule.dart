import '../../../../core/models/backend_models.dart';

/// How often a preventive-maintenance visit recurs.
enum PmFrequency { monthly, quarterly, halfYearly, yearly }

extension PmFrequencyX on PmFrequency {
  String get label {
    switch (this) {
      case PmFrequency.monthly:
        return 'Monthly';
      case PmFrequency.quarterly:
        return 'Quarterly';
      case PmFrequency.halfYearly:
        return 'Half-Yearly';
      case PmFrequency.yearly:
        return 'Yearly';
    }
  }

  int get months {
    switch (this) {
      case PmFrequency.monthly:
        return 1;
      case PmFrequency.quarterly:
        return 3;
      case PmFrequency.halfYearly:
        return 6;
      case PmFrequency.yearly:
        return 12;
    }
  }

  String get key => name;

  /// The backend `pm_frequency` value.
  String get backendKey {
    switch (this) {
      case PmFrequency.monthly:
        return 'monthly';
      case PmFrequency.quarterly:
        return 'quarterly';
      case PmFrequency.halfYearly:
        return 'half_yearly';
      case PmFrequency.yearly:
        return 'yearly';
    }
  }

  /// Accepts both the app key (`halfYearly`) and the backend key
  /// (`half_yearly`).
  static PmFrequency fromKey(String? key) {
    return PmFrequency.values.firstWhere(
      (f) => f.name == key || f.backendKey == key,
      orElse: () => PmFrequency.quarterly,
    );
  }
}

int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
int? _intOrNull(dynamic v) =>
    v == null ? null : (v is num ? v.toInt() : int.tryParse('$v'));
String _str(dynamic v) => v == null ? '' : '$v';
DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse('$v')?.toLocal();
Map<String, dynamic>? _map(dynamic v) => v is Map<String, dynamic> ? v : null;

String _companyName(Map<String, dynamic>? equipment) {
  final company = _map(equipment?['company']);
  return company == null ? '' : Company.fromJson(company).displayName;
}

/// A preventive-maintenance schedule (`pm_schedule`) for a piece of equipment
/// at a company. The backend advances [nextDue] by the frequency each time a
/// visit is generated.
class PmSchedule {
  final String id;
  final String equipmentName;
  final String companyName;
  final PmFrequency frequency;
  final DateTime nextDue;
  final bool active;
  final int? equipmentId;

  const PmSchedule({
    required this.id,
    required this.equipmentName,
    required this.companyName,
    required this.frequency,
    required this.nextDue,
    this.active = true,
    this.equipmentId,
  });

  bool isDue([DateTime? now]) {
    final today = now ?? DateTime.now();
    return active &&
        !nextDue.isAfter(DateTime(today.year, today.month, today.day));
  }

  /// The schedule advanced by one cycle from [from] (defaults to current due).
  PmSchedule advanced([DateTime? from]) {
    final base = from ?? nextDue;
    return copyWith(
      nextDue: DateTime(base.year, base.month + frequency.months, base.day),
    );
  }

  PmSchedule copyWith({
    String? id,
    String? equipmentName,
    String? companyName,
    PmFrequency? frequency,
    DateTime? nextDue,
    bool? active,
  }) {
    return PmSchedule(
      id: id ?? this.id,
      equipmentName: equipmentName ?? this.equipmentName,
      companyName: companyName ?? this.companyName,
      frequency: frequency ?? this.frequency,
      nextDue: nextDue ?? this.nextDue,
      active: active ?? this.active,
      equipmentId: equipmentId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'equipmentName': equipmentName,
        'companyName': companyName,
        'frequency': frequency.key,
        'nextDue': nextDue.toIso8601String(),
        'active': active,
      };

  factory PmSchedule.fromJson(Map<String, dynamic> json) {
    return PmSchedule(
      id: json['id'] as String,
      equipmentName: json['equipmentName'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      frequency: PmFrequencyX.fromKey(json['frequency'] as String?),
      nextDue: DateTime.parse(json['nextDue'] as String),
      active: json['active'] as bool? ?? true,
    );
  }

  /// A `getPmSchedules` row (with nested `equipment` + `company`).
  factory PmSchedule.fromBackend(Map<String, dynamic> json) {
    final equipment = _map(json['equipment']);
    return PmSchedule(
      id: '${_int(json['id'])}',
      equipmentName: _str(equipment?['name'] ?? json['equipment_name']),
      companyName: equipment != null
          ? _companyName(equipment)
          : _str(json['company_name']),
      frequency: PmFrequencyX.fromKey(json['frequency']?.toString()),
      nextDue: _date(json['next_due']) ?? DateTime.now(),
      active: json['is_active'] != false,
      equipmentId: _intOrNull(json['equipment_link'] ?? equipment?['id']),
    );
  }
}

/// A maintenance visit generated from a schedule (`pm_generated_task`).
class PmGeneratedTask {
  final String id;
  final String scheduleId;
  final String equipmentName;
  final String companyName;
  final DateTime dueDate;
  final DateTime generatedAt;
  final int? taskId;
  final int? equipmentId;

  /// Status of the generated task, when the row includes it.
  final TaskStatus? taskStatus;

  const PmGeneratedTask({
    required this.id,
    required this.scheduleId,
    required this.equipmentName,
    required this.companyName,
    required this.dueDate,
    required this.generatedAt,
    this.taskId,
    this.equipmentId,
    this.taskStatus,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'scheduleId': scheduleId,
        'equipmentName': equipmentName,
        'companyName': companyName,
        'dueDate': dueDate.toIso8601String(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory PmGeneratedTask.fromJson(Map<String, dynamic> json) {
    return PmGeneratedTask(
      id: json['id'] as String,
      scheduleId: json['scheduleId'] as String? ?? '',
      equipmentName: json['equipmentName'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      dueDate: DateTime.parse(json['dueDate'] as String),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  /// A `getPmGeneratedTasks` / `generatePmTasks` row. Names may come flat
  /// (`equipment_name`, `company_name`) or nested under `equipment` or
  /// `schedule.equipment`.
  factory PmGeneratedTask.fromBackend(Map<String, dynamic> json) {
    final equipment = _map(json['equipment']) ??
        _map(_map(json['schedule'] ?? json['pm_schedule'])?['equipment']);
    final flatCompany = json['company_name'] ?? _map(json['company'])?['name'];
    final task = _map(json['task']);
    return PmGeneratedTask(
      id: '${_int(json['id'])}',
      scheduleId: '${_int(json['schedule_link'])}',
      equipmentName: _str(json['equipment_name'] ?? equipment?['name']),
      companyName:
          flatCompany != null ? _str(flatCompany) : _companyName(equipment),
      dueDate: _date(json['due_date']) ?? DateTime.now(),
      generatedAt: _date(json['generated_at']) ?? DateTime.now(),
      taskId: _intOrNull(json['task_link']),
      equipmentId: _intOrNull(
        equipment?['id'] ??
            _map(json['schedule'] ?? json['pm_schedule'])?['equipment_link'],
      ),
      taskStatus:
          task?['status'] == null ? null : TaskStatus.fromKey(task!['status']),
    );
  }
}
