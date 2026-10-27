// Typed views of EverGreen backend rows (Prisma snake_case JSON). Parsing is
// tolerant: unknown or missing fields fall back to empty values so one bad row
// never breaks a list.

int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
int? _intOrNull(dynamic v) => v == null ? null : (v is num ? v.toInt() : int.tryParse('$v'));
String _str(dynamic v) => v == null ? '' : '$v';
String? _strOrNull(dynamic v) {
  if (v == null) return null;
  final s = '$v'.trim();
  return s.isEmpty ? null : s;
}

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();
bool? _boolOrNull(dynamic v) => v is bool ? v : null;
Map<String, dynamic>? _map(dynamic v) => v is Map<String, dynamic> ? v : null;

/// `company.service_type`.
enum CompanyServiceType {
  amc('amc', 'AMC'),
  nonAmc('non_amc', 'Non-AMC'),
  regular('regular', 'Regular');

  const CompanyServiceType(this.key, this.label);
  final String key;
  final String label;

  static CompanyServiceType? fromKey(dynamic key) {
    for (final t in values) {
      if (t.key == key) return t;
    }
    return null;
  }
}

/// `company.amc_type` (only for AMC companies).
enum AmcType {
  cAmc('c_amc', 'C AMC'),
  ncAmc('nc_amc', 'NC AMC');

  const AmcType(this.key, this.label);
  final String key;
  final String label;

  static AmcType? fromKey(dynamic key) {
    for (final t in values) {
      if (t.key == key) return t;
    }
    return null;
  }
}

/// `tasks.status` / `task_user.status`.
enum TaskStatus {
  open('open', 'Open'),
  hold('hold', 'On Hold'),
  inProgress('in_progress', 'In Progress'),
  completed('completed', 'Completed'),
  closed('closed', 'Closed');

  const TaskStatus(this.key, this.label);
  final String key;
  final String label;

  static TaskStatus fromKey(dynamic key) {
    for (final s in values) {
      if (s.key == key) return s;
    }
    return TaskStatus.open;
  }
}

/// `tasks.call_type`.
enum CallType {
  amcPreventiveMaintenance('amc_preventive_maintenance', 'AMC / PM'),
  breakdown('breakdown', 'Breakdown'),
  service('service', 'Service');

  const CallType(this.key, this.label);
  final String key;
  final String label;

  static CallType? fromKey(dynamic key) {
    for (final c in values) {
      if (c.key == key) return c;
    }
    return null;
  }
}

/// `hold_reason.hold`.
enum HoldType {
  spareRequired('spare_required', 'Spare required'),
  expertServiceRequired('expert_service_required', 'Expert service required'),
  others('others', 'Others');

  const HoldType(this.key, this.label);
  final String key;
  final String label;

  static HoldType fromKey(dynamic key) {
    for (final h in values) {
      if (h.key == key) return h;
    }
    return HoldType.others;
  }
}

/// `equipment.tm_frequency`.
enum TmFrequency {
  daily('daily', 'Daily'),
  weekly('weekly', 'Weekly'),
  biweekly('biweekly', 'Bi-weekly'),
  monthly('monthly', 'Monthly'),
  biMonthly('bi_monthly', 'Bi-monthly'),
  triMonthly('tri_monthly', 'Tri-monthly'),
  quarterly('quarterly', 'Quarterly'),
  semiAnnual('semi_annual', 'Semi-annual'),
  annual('annual', 'Annual');

  const TmFrequency(this.key, this.label);
  final String key;
  final String label;

  static TmFrequency? fromKey(dynamic key) {
    for (final f in values) {
      if (f.key == key) return f;
    }
    return null;
  }
}

/// `tasks.priority`.
enum TaskPriorityLevel {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High'),
  critical('critical', 'Critical');

  const TaskPriorityLevel(this.key, this.label);
  final String key;
  final String label;

  static TaskPriorityLevel fromKey(dynamic key) {
    for (final p in values) {
      if (p.key == key) return p;
    }
    return TaskPriorityLevel.medium;
  }
}

/// `tasks.approval`.
enum ApprovalStage {
  requested('requested', 'Requested'),
  approved('approved', 'Approved'),
  assigned('assigned', 'Assigned'),
  inService('in_service', 'In Service'),
  completed('completed', 'Completed'),
  confirmed('confirmed', 'Confirmed'),
  rejected('rejected', 'Rejected');

  const ApprovalStage(this.key, this.label);
  final String key;
  final String label;

  static ApprovalStage fromKey(dynamic key) {
    for (final a in values) {
      if (a.key == key) return a;
    }
    return ApprovalStage.requested;
  }
}

/// `equipment.status`.
enum EquipmentCondition {
  operational('operational', 'Operational'),
  underMaintenance('under_maintenance', 'Under Maintenance'),
  faulty('faulty', 'Faulty'),
  retired('retired', 'Retired');

  const EquipmentCondition(this.key, this.label);
  final String key;
  final String label;

  static EquipmentCondition fromKey(dynamic key) {
    for (final c in values) {
      if (c.key == key) return c;
    }
    return EquipmentCondition.operational;
  }
}

class Company {
  final int id;
  final String name;
  final String branchName;
  final String email;
  final String? gstNumber;
  final String? location;
  final CompanyServiceType? serviceType;
  final AmcType? amcType;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final List<Equipment> equipment;

  /// Client admin linked to the company (`poc_details.user`), if any.
  final TaskPerson? poc;
  final String? pocEmail;
  final Map<String, dynamic> raw;

  const Company({
    required this.id,
    required this.name,
    this.branchName = '',
    this.email = '',
    this.gstNumber,
    this.location,
    this.serviceType,
    this.amcType,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.equipment = const [],
    this.poc,
    this.pocEmail,
    this.raw = const {},
  });

  String get displayName => branchName.isEmpty ? name : '$name - $branchName';

  /// "AMC · C AMC", "Non-AMC", or "" when unset.
  String get serviceLabel {
    if (serviceType == null) return '';
    if (serviceType == CompanyServiceType.amc && amcType != null) {
      return '${serviceType!.label} · ${amcType!.label}';
    }
    return serviceType!.label;
  }

  bool get isAmcExpired =>
      serviceType == CompanyServiceType.amc &&
      endDate != null &&
      endDate!.isBefore(DateTime.now());

  factory Company.fromJson(Map<String, dynamic> json) {
    final pocUser = _map(_map(json['poc_details'])?['user']);
    return Company(
        id: _int(json['id']),
        name: _str(json['name']),
        branchName: _str(json['branch_name']),
        email: _str(json['email']),
        gstNumber: _strOrNull(json['gst_number']),
        location: _strOrNull(json['location']),
        serviceType: CompanyServiceType.fromKey(json['service_type']),
        amcType: AmcType.fromKey(json['amc_type']),
        startDate: _date(json['start_date']),
        endDate: _date(json['end_date']),
        isActive: json['is_active'] != false,
        equipment: (json['equipment'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Equipment.fromJson)
            .toList(),
        poc: TaskPerson.fromJson(pocUser),
        pocEmail: _strOrNull(pocUser?['email']),
        raw: json,
      );
  }
}

class Equipment {
  final int id;
  final String name;
  final String? make;
  final String? model;
  final String egSerialNumber;
  final String? serialNumber;
  final String? specifications;
  final String? imageUrl;
  final DateTime? manufacturerDate;
  final String? location;
  final String? description;
  final TmFrequency? tmFrequency;
  final int? companyId;
  final Company? company;
  final String? manual;
  final bool isActive;
  final EquipmentCondition status;
  final String? type;
  final DateTime? installedAt;
  final DateTime? verifiedAt;
  final TaskPerson? verifier;
  final Map<String, dynamic> raw;

  const Equipment({
    required this.id,
    required this.name,
    required this.egSerialNumber,
    this.make,
    this.model,
    this.serialNumber,
    this.specifications,
    this.imageUrl,
    this.manufacturerDate,
    this.location,
    this.description,
    this.tmFrequency,
    this.companyId,
    this.company,
    this.manual,
    this.isActive = true,
    this.status = EquipmentCondition.operational,
    this.type,
    this.installedAt,
    this.verifiedAt,
    this.verifier,
    this.raw = const {},
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    final company = _map(json['company']);
    return Equipment(
      id: _int(json['id']),
      name: _str(json['name']),
      make: _strOrNull(json['make']),
      model: _strOrNull(json['model']),
      egSerialNumber: _str(json['eg_serial_number']),
      serialNumber: _strOrNull(json['serial_number']),
      specifications: _strOrNull(json['specifications']),
      imageUrl: _strOrNull(json['image_url']),
      manufacturerDate: _date(json['manufacturer_date'] ?? json['manufacturerDate']),
      location: _strOrNull(json['location']),
      description: _strOrNull(json['description']),
      tmFrequency: TmFrequency.fromKey(json['tm_frequency'] ?? json['tmFrequency']),
      companyId: _intOrNull(json['company_link']),
      company: company == null ? null : Company.fromJson(company),
      manual: _strOrNull(json['manual']),
      isActive: json['is_active'] != false,
      status: EquipmentCondition.fromKey(json['status']),
      type: _strOrNull(json['type']),
      installedAt: _date(json['installed_at']),
      verifiedAt: _date(json['verified_at']),
      verifier: TaskPerson.fromJson(json['verifier']),
      raw: json,
    );
  }
}

class HoldReason {
  final int id;
  final HoldType hold;
  final bool isActive;
  final String? sparePartNumber;
  final String? image;
  final String? reason;

  const HoldReason({
    required this.id,
    required this.hold,
    this.isActive = false,
    this.sparePartNumber,
    this.image,
    this.reason,
  });

  factory HoldReason.fromJson(Map<String, dynamic> json) => HoldReason(
        id: _int(json['id']),
        hold: HoldType.fromKey(json['hold']),
        isActive: json['is_active'] == true,
        sparePartNumber: _strOrNull(json['spare_part_number']),
        image: _strOrNull(json['image']),
        reason: _strOrNull(json['reason']),
      );
}

/// A person attached to a task (`client` / `technician` in getAllTasks rows).
class TaskPerson {
  final int id;
  final String name;
  final String phone;
  final String? accessLevel;

  const TaskPerson({required this.id, required this.name, this.phone = '', this.accessLevel});

  static TaskPerson? fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    return TaskPerson(
      id: _int(json['id']),
      name: _str(json['name']),
      phone: _str(json['phone']),
      accessLevel: _strOrNull(json['access_level']),
    );
  }
}

/// One ticket. Built from a `getAllTasks` row (the latest `task_user` with the
/// task nested under `task`) or from a bare `tasks` row.
class ServiceTask {
  final int id;
  final int? taskUserId;
  final String ticketNo;
  final String name;
  final String description;
  final CallType? callType;
  final TaskStatus status;
  final String? otp;
  final String? feedback;
  final String? actionTaken;
  final String? reqDetails;
  final bool? followUp;
  final String? actionReqDetails;
  final bool? serviceSatisfactory;
  final bool? isRunningSmoothly;
  final String? notes;
  final int? rating;
  final String? statusReason;
  final List<String> images;
  final List<HoldReason> holdReasons;
  final Equipment? equipment;
  final TaskPerson? client;
  final TaskPerson? technician;
  final TaskPerson? manager;
  final TaskPriorityLevel priority;
  final ApprovalStage approval;
  final DateTime? dueDate;
  final bool escalated;
  final String? escalationReason;
  final DateTime? assignedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final String? resolutionNotes;
  final String? rejectionReason;

  /// Contact details of an individual ticket (one with no equipment).
  final String? contactName;
  final String? contactPhone;
  final String? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;

  const ServiceTask({
    required this.id,
    required this.ticketNo,
    required this.status,
    this.taskUserId,
    this.name = '',
    this.description = '',
    this.callType,
    this.otp,
    this.feedback,
    this.actionTaken,
    this.reqDetails,
    this.followUp,
    this.actionReqDetails,
    this.serviceSatisfactory,
    this.isRunningSmoothly,
    this.notes,
    this.rating,
    this.statusReason,
    this.images = const [],
    this.holdReasons = const [],
    this.equipment,
    this.client,
    this.technician,
    this.manager,
    this.priority = TaskPriorityLevel.medium,
    this.approval = ApprovalStage.requested,
    this.dueDate,
    this.escalated = false,
    this.escalationReason,
    this.assignedAt,
    this.acceptedAt,
    this.startedAt,
    this.resolvedAt,
    this.closedAt,
    this.resolutionNotes,
    this.rejectionReason,
    this.contactName,
    this.contactPhone,
    this.address,
    this.createdAt,
    this.updatedAt,
    this.raw = const {},
  });

  Company? get company => equipment?.company;

  /// A ticket raised for a person rather than a company's equipment.
  bool get isIndividual => equipment == null;
  HoldReason? get activeHold {
    for (final h in holdReasons) {
      if (h.isActive) return h;
    }
    return null;
  }

  factory ServiceTask.fromJson(Map<String, dynamic> json) {
    final nested = _map(json['task']);
    final task = nested ?? json;
    final equipment = _map(task['equipment']);
    return ServiceTask(
      id: _int(task['id']),
      taskUserId: nested != null ? _intOrNull(json['id']) : null,
      ticketNo: _str(task['ticket_no']),
      name: _str(task['name']),
      description: _str(task['description']),
      callType: CallType.fromKey(task['call_type']),
      status: TaskStatus.fromKey(json['status'] ?? task['status']),
      otp: _strOrNull(task['otp']),
      feedback: _strOrNull(task['feedback']),
      actionTaken: _strOrNull(task['action_taken']),
      reqDetails: _strOrNull(task['req_details']),
      followUp: _boolOrNull(task['follow_up']),
      actionReqDetails: _strOrNull(task['action_req_details']),
      serviceSatisfactory: _boolOrNull(task['service_satisfactory']),
      isRunningSmoothly: _boolOrNull(task['is_running_smoothly']),
      notes: _strOrNull(task['notes']),
      rating: _intOrNull(task['rating']),
      statusReason: nested != null ? _strOrNull(json['reason']) : null,
      images: (task['image'] as List? ?? const [])
          .map((e) => e is Map ? _str(e['url']) : _str(e))
          .where((e) => e.isNotEmpty)
          .toList(),
      holdReasons: (task['hold_reason'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(HoldReason.fromJson)
          .toList(),
      equipment: equipment == null ? null : Equipment.fromJson(equipment),
      client: TaskPerson.fromJson(json['client']),
      technician: TaskPerson.fromJson(json['technician']),
      manager: TaskPerson.fromJson(json['manager']),
      priority: TaskPriorityLevel.fromKey(task['priority']),
      approval: ApprovalStage.fromKey(task['approval']),
      dueDate: _date(task['due_date']),
      escalated: task['escalated'] == true,
      escalationReason: _strOrNull(task['escalation_reason']),
      assignedAt: _date(task['assigned_at']),
      acceptedAt: _date(task['accepted_at']),
      startedAt: _date(task['started_at']),
      resolvedAt: _date(task['resolved_at']),
      closedAt: _date(task['closed_at']),
      resolutionNotes: _strOrNull(task['resolution_notes']),
      rejectionReason: _strOrNull(task['rejection_reason']),
      contactName: _strOrNull(task['contact_name']),
      contactPhone: _strOrNull(task['contact_phone']),
      address: _strOrNull(task['address']),
      createdAt: _date(task['created_at']),
      updatedAt: _date(json['updated_at'] ?? task['updated_at']),
      raw: json,
    );
  }
}

class AppNotification {
  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  final int? taskId;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.taskId,
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: _int(json['id']),
        title: _str(json['title']),
        description: _str(json['description']),
        imageUrl: _strOrNull(json['image_url']),
        taskId: _intOrNull(json['task_link']),
        isRead: json['is_read'] == true,
        createdAt: _date(json['created_at']),
      );
}

/// Extracts the list under `data` (or the body itself when it is a list).
List<Map<String, dynamic>> dataList(dynamic body, [String key = 'data']) {
  final data = body is Map ? body[key] : body;
  if (data is! List) return const [];
  return data.whereType<Map<String, dynamic>>().toList();
}
