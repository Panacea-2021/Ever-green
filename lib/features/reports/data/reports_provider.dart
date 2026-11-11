import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/report_models.dart';

// ============================================================================
// Helper to unwrap Either<Failure, T> — same pattern as EvergreenRepository
// ============================================================================

T _unwrap<T>(Either<Failure, T> result) {
  return result.fold(
    (failure) => throw failure,
    (value) => value,
  );
}

Map<String, dynamic> _dataMap(dynamic body) {
  if (body is Map<String, dynamic>) {
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    return body;
  }
  return {};
}

List<dynamic> _dataList(dynamic body) {
  if (body is Map) {
    final d = body['data'];
    if (d is List) return d;
  }
  if (body is List) return body;
  return [];
}

/// Reports API service — follows same pattern as EvergreenRepository
class ReportsApi {
  final ApiClient _api;

  ReportsApi(this._api);

  Future<ReportsDashboard> getDashboard() async {
    final result = await _api.get<dynamic>('reports/dashboard');
    final body = _unwrap(result);
    final data = _dataMap(body);
    return ReportsDashboard.fromJson(data);
  }

  Future<TaskSummaryReport> getTaskSummary({
    DateTime? from,
    DateTime? to,
  }) async {
    final result = await _api.post<dynamic>(
      'reports/tasks',
      data: {
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      },
    );
    final body = _unwrap(result);
    final data = _dataMap(body);
    return TaskSummaryReport.fromJson(data);
  }

  Future<TechnicianPerformanceReport> getTechnicianPerformance({
    DateTime? from,
    DateTime? to,
  }) async {
    final result = await _api.post<dynamic>(
      'reports/technicians',
      data: {
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      },
    );
    final body = _unwrap(result);
    final data = _dataMap(body);
    return TechnicianPerformanceReport.fromJson(data);
  }

  Future<AmcStatusReport> getAmcStatus() async {
    final result = await _api.get<dynamic>('reports/amcs');
    final body = _unwrap(result);
    final data = _dataMap(body);
    return AmcStatusReport.fromJson(data);
  }

  Future<EquipmentHealthReport> getEquipmentHealth() async {
    final result = await _api.get<dynamic>('reports/equipment');
    final body = _unwrap(result);
    final data = _dataMap(body);
    return EquipmentHealthReport.fromJson(data);
  }

  Future<SlaComplianceReport> getSlaCompliance({
    DateTime? from,
    DateTime? to,
  }) async {
    final result = await _api.post<dynamic>(
      'reports/sla',
      data: {
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      },
    );
    final body = _unwrap(result);
    final data = _dataMap(body);
    return SlaComplianceReport.fromJson(data);
  }
}

/// Provider for reports API
final reportsApiProvider = Provider<ReportsApi>((ref) {
  return ReportsApi(ref.watch(apiClientProvider));
});

/// Dashboard provider
final reportsDashboardProvider = FutureProvider<ReportsDashboard>((ref) async {
  return ref.watch(reportsApiProvider).getDashboard();
});

/// Date range for reports
class ReportDateRange {
  final DateTime from;
  final DateTime to;

  const ReportDateRange({required this.from, required this.to});

  static ReportDateRange thisMonth() {
    final now = DateTime.now();
    return ReportDateRange(
      from: DateTime(now.year, now.month, 1),
      to: now,
    );
  }

  static ReportDateRange lastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    return ReportDateRange(
      from: lastMonth,
      to: DateTime(now.year, now.month, 0),
    );
  }

  static ReportDateRange last30Days() {
    final now = DateTime.now();
    return ReportDateRange(
      from: now.subtract(const Duration(days: 30)),
      to: now,
    );
  }

  static ReportDateRange last90Days() {
    final now = DateTime.now();
    return ReportDateRange(
      from: now.subtract(const Duration(days: 90)),
      to: now,
    );
  }

  static ReportDateRange thisYear() {
    final now = DateTime.now();
    return ReportDateRange(
      from: DateTime(now.year, 1, 1),
      to: now,
    );
  }
}

/// Selected date range provider
final reportDateRangeProvider = StateProvider<ReportDateRange>((ref) {
  return ReportDateRange.thisMonth();
});

/// Task summary report provider
final taskSummaryReportProvider =
    FutureProvider<TaskSummaryReport>((ref) async {
  final range = ref.watch(reportDateRangeProvider);
  return ref.watch(reportsApiProvider).getTaskSummary(
        from: range.from,
        to: range.to,
      );
});

/// Technician performance report provider
final technicianPerformanceReportProvider =
    FutureProvider<TechnicianPerformanceReport>((ref) async {
  final range = ref.watch(reportDateRangeProvider);
  return ref.watch(reportsApiProvider).getTechnicianPerformance(
        from: range.from,
        to: range.to,
      );
});

/// AMC status report provider
final amcStatusReportProvider = FutureProvider<AmcStatusReport>((ref) async {
  return ref.watch(reportsApiProvider).getAmcStatus();
});

/// Equipment health report provider
final equipmentHealthReportProvider =
    FutureProvider<EquipmentHealthReport>((ref) async {
  return ref.watch(reportsApiProvider).getEquipmentHealth();
});

/// SLA compliance report provider
final slaComplianceReportProvider =
    FutureProvider<SlaComplianceReport>((ref) async {
  final range = ref.watch(reportDateRangeProvider);
  return ref.watch(reportsApiProvider).getSlaCompliance(
        from: range.from,
        to: range.to,
      );
});
