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

  Future<ReportsDashboard> getDashboard({
    DateTime? from,
    DateTime? to,
  }) async {
    final result = await _api.get<dynamic>(
      'reports/dashboard',
      queryParameters: {
        if (from != null) 'from': _fmt(from),
        if (to != null) 'to': _fmt(to),
      },
    );
    final body = _unwrap(result);
    final data = _dataMap(body);
    return ReportsDashboard.fromJson(data);
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<TaskSummaryReport> getTaskSummary({
    DateTime? from,
    DateTime? to,
  }) async {
    final result = await _api.get<dynamic>(
      'reports/tasks',
      queryParameters: {
        if (from != null) 'from': _fmt(from),
        if (to != null) 'to': _fmt(to),
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
    final result = await _api.get<dynamic>(
      'reports/technicians',
      queryParameters: {
        if (from != null) 'from': _fmt(from),
        if (to != null) 'to': _fmt(to),
      },
    );
    final body = _unwrap(result);
    final data = _dataMap(body);
    return TechnicianPerformanceReport.fromJson(data);
  }

  Future<AmcStatusReport> getAmcStatus({
    DateTime? from,
    DateTime? to,
  }) async {
    final result = await _api.get<dynamic>(
      'reports/amcs',
      queryParameters: {
        if (from != null) 'from': _fmt(from),
        if (to != null) 'to': _fmt(to),
      },
    );
    final body = _unwrap(result);
    final data = _dataMap(body);
    return AmcStatusReport.fromJson(data);
  }

  Future<EquipmentHealthReport> getEquipmentHealth({
    DateTime? from,
    DateTime? to,
  }) async {
    final result = await _api.get<dynamic>(
      'reports/equipment',
      queryParameters: {
        if (from != null) 'from': _fmt(from),
        if (to != null) 'to': _fmt(to),
      },
    );
    final body = _unwrap(result);
    final data = _dataMap(body);
    return EquipmentHealthReport.fromJson(data);
  }

  Future<List<int>> getReportYears() async {
    final result = await _api.get<dynamic>('reports/years');
    final body = _unwrap(result);
    final years = <int>[];
    // Accept several possible response shapes.
    dynamic source = body;
    if (body is Map) {
      for (final key in const ['years', 'data', 'available_years', 'availableYears']) {
        if (body[key] is List) {
          source = body[key];
          break;
        }
      }
    }
    if (source is List) {
      for (final v in source) {
        if (v is num) {
          years.add(v.toInt());
        } else if (v is String) {
          final n = int.tryParse(v);
          if (n != null) years.add(n);
        } else if (v is Map) {
          for (final key in const ['year', 'value', 'y']) {
            final n = v[key];
            if (n is num) {
              years.add(n.toInt());
              break;
            } else if (n is String) {
              final parsed = int.tryParse(n);
              if (parsed != null) {
                years.add(parsed);
                break;
              }
            }
          }
        }
      }
    }
    years.sort();
    return years;
  }

  Future<SlaComplianceReport> getSlaCompliance({
    DateTime? from,
    DateTime? to,
  }) async {
    final result = await _api.get<dynamic>(
      'reports/sla',
      queryParameters: {
        if (from != null) 'from': _fmt(from),
        if (to != null) 'to': _fmt(to),
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

/// Available report years from the backend.
final reportYearsProvider = FutureProvider<List<int>>((ref) async {
  try {
    final years = await ref.watch(reportsApiProvider).getReportYears();
    if (years.isNotEmpty) return years;
  } catch (_) {
    // Fall back to locally generated years if the endpoint is unavailable.
  }
  final now = DateTime.now().year;
  return [for (var y = now - 2; y <= now; y++) y];
});

/// Dashboard provider
final reportsDashboardProvider = FutureProvider<ReportsDashboard>((ref) async {
  final range = ref.watch(reportDateRangeProvider);
  return ref.watch(reportsApiProvider).getDashboard(
        from: range.from,
        to: range.to,
      );
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
      from: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29)),
      to: now,
    );
  }

  static ReportDateRange last90Days() {
    final now = DateTime.now();
    return ReportDateRange(
      from: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 89)),
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
  final range = ref.watch(reportDateRangeProvider);
  return ref.watch(reportsApiProvider).getAmcStatus(
        from: range.from,
        to: range.to,
      );
});

/// Equipment health report provider
final equipmentHealthReportProvider =
    FutureProvider<EquipmentHealthReport>((ref) async {
  final range = ref.watch(reportDateRangeProvider);
  return ref.watch(reportsApiProvider).getEquipmentHealth(
        from: range.from,
        to: range.to,
      );
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
