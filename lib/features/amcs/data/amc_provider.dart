import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/evergreen_repository.dart';
import '../../../core/models/backend_models.dart';
import '../domain/models/amc_contract.dart';

/// AMC contracts derived from [companiesProvider] (the single source of
/// truth): every AMC company that has an end date. Empty while companies are
/// loading or failed; screens that need loading/error states should watch
/// [companiesProvider] directly.
final amcProvider = Provider<List<AmcContract>>((ref) {
  final companies = ref.watch(companiesProvider).valueOrNull ?? const [];
  return amcContractsFrom(companies);
});

List<AmcContract> amcContractsFrom(Iterable<Company> companies) => [
      for (final c in companies)
        if (AmcContract.fromCompany(c) case final contract?) contract,
    ];

/// Active companies' contracts that are expiring within the window or already
/// expired, soonest end date first. Drives the renewals screen and reminders.
List<AmcContract> renewalsFrom(Iterable<AmcContract> contracts) {
  return contracts
      .where((c) => c.company?.isActive != false)
      .where((c) => c.status() != AmcStatus.active)
      .toList()
    ..sort((a, b) => a.endDate.compareTo(b.endDate));
}

final amcRenewalsProvider = Provider<List<AmcContract>>((ref) {
  return renewalsFrom(ref.watch(amcProvider));
});

/// Fields sent to `user/createCompany` and `user/updateCompany/:id`.
/// Non-AMC and Regular companies never carry an AMC type or dates.
class CompanyInput {
  final String name;
  final String branchName;
  final String email;
  final String gstNumber;
  final String address;
  final CompanyServiceType serviceType;
  final AmcType? amcType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? logo;

  /// Client admin details; all four are required together on create. On
  /// update only the non-empty ones are changed.
  final String adminName;
  final String adminPhone;
  final String adminEmail;
  final String adminPassword;

  const CompanyInput({
    required this.name,
    required this.branchName,
    required this.serviceType,
    this.email = '',
    this.gstNumber = '',
    this.address = '',
    this.amcType,
    this.startDate,
    this.endDate,
    this.logo,
    this.adminName = '',
    this.adminPhone = '',
    this.adminEmail = '',
    this.adminPassword = '',
  });

  bool get isAmc => serviceType == CompanyServiceType.amc;

  Map<String, dynamic> toBody() {
    String? opt(String v) => v.trim().isEmpty ? null : v.trim();
    return {
      'company_name': name.trim(),
      'branch_name': branchName.trim(),
      if (opt(email) != null) 'company_email': opt(email),
      if (opt(gstNumber) != null) 'gst_number': gstNumber.trim().toUpperCase(),
      if (opt(address) != null) 'company_location': opt(address),
      'service_type': serviceType.key,
      if (isAmc && amcType != null) 'amc_type': amcType!.key,
      if (isAmc && startDate != null) 'start_date': apiDate(startDate!),
      if (isAmc && endDate != null) 'end_date': apiDate(endDate!),
      if (logo != null && logo!.isNotEmpty) 'logo': logo,
      if (opt(adminName) != null) 'name': opt(adminName),
      if (opt(adminPhone) != null) 'phone': opt(adminPhone),
      if (opt(adminEmail) != null) 'email': opt(adminEmail),
      if (opt(adminPassword) != null) 'password': opt(adminPassword),
    };
  }
}

/// `user/updateCompany/:id` body for an AMC renewal. Name and branch are
/// required by the backend; omitted keys (email, GST, address, logo, client
/// admin) keep their stored values. The backend requires an AMC type whenever
/// `service_type` is AMC, so legacy companies (no type yet) must pass one.
Map<String, dynamic> renewCompanyBody(
  Company company, {
  required DateTime startDate,
  required DateTime endDate,
  AmcType? amcType,
}) {
  final type = amcType ?? company.amcType;
  if (type == null) {
    throw ArgumentError.value(amcType, 'amcType', 'AMC type is required');
  }
  if (endDate.isBefore(startDate)) {
    throw ArgumentError.value(endDate, 'endDate', 'must be on/after start');
  }
  return {
    'company_name': company.name,
    'branch_name': company.branchName,
    'service_type': CompanyServiceType.amc.key,
    'amc_type': type.key,
    'start_date': apiDate(startDate),
    'end_date': apiDate(endDate),
  };
}

/// Result of `user/uploadCompanyData`.
class CompanyUploadResult {
  final String message;
  final int added;
  final int skipped;
  final List<String> errors;

  const CompanyUploadResult({
    required this.message,
    required this.added,
    required this.skipped,
    required this.errors,
  });
}

final amcRepositoryProvider = Provider<AmcRepository>((ref) {
  return AmcRepository(ref.watch(evergreenRepositoryProvider));
});

/// Company / AMC writes. Every call throws [FailureException] on a backend
/// error so callers can show `'$error'`.
class AmcRepository {
  AmcRepository(this._repo);
  final EvergreenRepository _repo;

  Future<Company?> createCompany(CompanyInput input) async {
    final body = unwrap(
      await _repo.api.post<dynamic>('user/createCompany', data: input.toBody()),
    );
    return _company(body);
  }

  Future<Company?> updateCompany(int id, CompanyInput input) async {
    final body = unwrap(
      await _repo.api
          .put<dynamic>('user/updateCompany/$id', data: input.toBody()),
    );
    return _company(body);
  }

  /// Only changes the contract (service type, AMC type, dates); the backend
  /// keeps the other fields. See [renewCompanyBody].
  Future<Company?> renewCompany(
    Company company, {
    required DateTime startDate,
    required DateTime endDate,
    AmcType? amcType,
  }) async {
    final body = unwrap(
      await _repo.api.put<dynamic>(
        'user/updateCompany/${company.id}',
        data: renewCompanyBody(
          company,
          startDate: startDate,
          endDate: endDate,
          amcType: amcType,
        ),
      ),
    );
    return _company(body);
  }

  Future<void> setCompanyActive(int id, {required bool isActive}) async {
    unwrap(
      await _repo.api.post<dynamic>(
        'user/setCompanyActive',
        data: {'company_link': id, 'is_active': isActive},
      ),
    );
  }

  /// The company-tasks "Disable" action: requested -> rejected (closed).
  Future<void> rejectTask(int taskId, String reason) async {
    unwrap(
      await _repo.api.post<dynamic>(
        'user/rejectTask',
        data: {'task_link': taskId, 'reason': reason},
      ),
    );
  }

  Future<String> uploadLogo(String path) =>
      _repo.uploadFile(path, folderName: 'logo');

  Future<CompanyUploadResult> uploadCompanyData({
    String? path,
    List<int>? bytes,
    required String fileName,
  }) async {
    final file = path != null
        ? await MultipartFile.fromFile(path, filename: fileName)
        : MultipartFile.fromBytes(bytes ?? const [], filename: fileName);
    final body = unwrap(
      await _repo.api.post<dynamic>(
        'user/uploadCompanyData',
        data: FormData.fromMap({'file': file}),
      ),
    );
    final map = body is Map ? body : const {};
    int n(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return CompanyUploadResult(
      message: '${map['message'] ?? 'Upload complete'}',
      added: n(map['added']),
      skipped: n(map['skipped']),
      errors: (map['errors'] as List? ?? const []).map((e) => '$e').toList(),
    );
  }

  static Company? _company(dynamic body) {
    final data = body is Map ? body['data'] : null;
    return data is Map<String, dynamic> ? Company.fromJson(data) : null;
  }
}
