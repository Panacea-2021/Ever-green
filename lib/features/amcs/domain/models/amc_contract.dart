import '../../../../core/models/backend_models.dart';

/// Renewal status derived from an AMC's end date relative to "now".
enum AmcStatus { active, expiringSoon, expired }

extension AmcStatusX on AmcStatus {
  String get label {
    switch (this) {
      case AmcStatus.active:
        return 'Active';
      case AmcStatus.expiringSoon:
        return 'Expiring Soon';
      case AmcStatus.expired:
        return 'Expired';
    }
  }

  String get key => name;

  static AmcStatus fromKey(String? key) {
    return AmcStatus.values.firstWhere(
      (s) => s.name == key,
      orElse: () => AmcStatus.active,
    );
  }
}

/// Date-only helpers for a backend [Company]. The backend stores contract
/// dates as UTC midnight, so the calendar day is read from the raw
/// `YYYY-MM-DD` prefix instead of converting to local time (which can shift
/// the day in negative-offset time zones).
extension CompanyAmcX on Company {
  /// AMC companies, plus legacy rows created before `service_type` existed
  /// (NULL service type) that still carry a contract end date.
  bool get isAmc => serviceType == CompanyServiceType.amc || isLegacyAmc;

  bool get isLegacyAmc => serviceType == null && amcEndDay != null;

  DateTime? get amcStartDay => _day(raw['start_date']) ?? _local(startDate);
  DateTime? get amcEndDay => _day(raw['end_date']) ?? _local(endDate);

  String? get logo {
    final v = raw['logo'];
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
  }

  static DateTime? _day(dynamic v) {
    if (v == null) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch('$v');
    if (m == null) return null;
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }

  static DateTime? _local(DateTime? d) =>
      d == null ? null : DateTime(d.year, d.month, d.day);
}

/// `YYYY-MM-DD`, the format the backend expects for company dates.
String apiDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// [start] plus [months], clamped to the last day of the target month
/// (31 Aug + 6 months = 28/29 Feb, not 3 Mar).
DateTime addMonthsClamped(DateTime start, int months) {
  final firstOfTarget = DateTime(start.year, start.month + months);
  final lastDay = DateTime(firstOfTarget.year, firstOfTarget.month + 1, 0).day;
  return DateTime(
    firstOfTarget.year,
    firstOfTarget.month,
    start.day > lastDay ? lastDay : start.day,
  );
}

/// `dd-MM-yyyy` for display.
String displayDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec',
];

/// `07 Sept 2027`, the design's long date style.
String longDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

/// One AMC company's contract, viewed through the renewal lens. Built from a
/// backend [Company] via [AmcContract.fromCompany]; only AMC companies with
/// contract dates have one. [id] is the company id as a string.
class AmcContract {
  final String id;
  final String companyName;
  final String branchName;
  final String pocName;
  final String mobile;
  final String email;
  final DateTime startDate;
  final DateTime endDate;
  final String? imageUrl;

  /// Service classification label: 'AMC', 'Non-AMC', or 'Regular'.
  final String serviceType;

  /// AMC sub-category label when [serviceType] is 'AMC': 'NC AMC' or 'C AMC'
  /// (empty otherwise).
  final String amcCategory;

  /// The backend company this contract was built from, if any.
  final Company? company;

  const AmcContract({
    required this.id,
    required this.companyName,
    required this.branchName,
    required this.pocName,
    required this.mobile,
    required this.email,
    required this.startDate,
    required this.endDate,
    this.imageUrl,
    this.serviceType = 'AMC',
    this.amcCategory = '',
    this.company,
  });

  /// Returns null for Non-AMC / Regular companies and for AMC companies
  /// missing an end date.
  static AmcContract? fromCompany(Company c) {
    if (!c.isAmc) return null;
    final end = c.amcEndDay;
    if (end == null) return null;
    return AmcContract(
      id: '${c.id}',
      companyName: c.name,
      branchName: c.branchName,
      pocName: c.poc?.name ?? '',
      mobile: c.poc?.phone ?? '',
      email: c.pocEmail ?? c.email,
      startDate: c.amcStartDay ?? end,
      endDate: end,
      imageUrl: c.logo,
      serviceType: CompanyServiceType.amc.label,
      amcCategory: c.amcType?.label ?? '',
      company: c,
    );
  }

  int? get companyId => company?.id ?? int.tryParse(id);

  /// Number of days until the contract ends (negative if already expired).
  int daysUntilExpiry([DateTime? now]) {
    final today = _dateOnly(now ?? DateTime.now());
    final end = _dateOnly(endDate);
    return end.difference(today).inDays;
  }

  /// Contracts within this many days of expiry are flagged "Expiring Soon".
  static const int expiryWindowDays = 30;

  AmcStatus status([DateTime? now]) {
    final days = daysUntilExpiry(now);
    if (days < 0) return AmcStatus.expired;
    if (days <= expiryWindowDays) return AmcStatus.expiringSoon;
    return AmcStatus.active;
  }

  // UTC-normalised so a DST change between the two dates can't drop a day.
  static DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  AmcContract copyWith({
    String? id,
    String? companyName,
    String? branchName,
    String? pocName,
    String? mobile,
    String? email,
    DateTime? startDate,
    DateTime? endDate,
    String? imageUrl,
    String? serviceType,
    String? amcCategory,
  }) {
    return AmcContract(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      branchName: branchName ?? this.branchName,
      pocName: pocName ?? this.pocName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      imageUrl: imageUrl ?? this.imageUrl,
      serviceType: serviceType ?? this.serviceType,
      amcCategory: amcCategory ?? this.amcCategory,
      company: company,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'branchName': branchName,
      'pocName': pocName,
      'mobile': mobile,
      'email': email,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'imageUrl': imageUrl,
      'serviceType': serviceType,
      'amcCategory': amcCategory,
    };
  }

  factory AmcContract.fromJson(Map<String, dynamic> json) {
    return AmcContract(
      id: json['id'] as String,
      companyName: json['companyName'] as String? ?? '',
      branchName: json['branchName'] as String? ?? '',
      pocName: json['pocName'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      email: json['email'] as String? ?? '',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      imageUrl: json['imageUrl'] as String?,
      serviceType: json['serviceType'] as String? ?? 'AMC',
      amcCategory: json['amcCategory'] as String? ?? '',
    );
  }
}
