/// Report types
enum ReportType {
  taskSummary,
  technicianPerformance,
  amcStatus,
  equipmentHealth,
  slaCompliance,
}

/// Reports dashboard summary
class ReportsDashboard {
  final TasksSummary tasksSummary;
  final TechniciansSummary techniciansSummary;
  final AmcsSummary amcsSummary;
  final EquipmentSummary equipmentSummary;
  final int slaCompliance;
  final List<RecentActivity> recentActivity;

  const ReportsDashboard({
    required this.tasksSummary,
    required this.techniciansSummary,
    required this.amcsSummary,
    required this.equipmentSummary,
    required this.slaCompliance,
    required this.recentActivity,
  });

  factory ReportsDashboard.fromJson(Map<String, dynamic> json) {
    return ReportsDashboard(
      tasksSummary: TasksSummary.fromJson(json['tasksSummary'] ?? {}),
      techniciansSummary:
          TechniciansSummary.fromJson(json['techniciansSummary'] ?? {}),
      amcsSummary: AmcsSummary.fromJson(json['amcsSummary'] ?? {}),
      equipmentSummary:
          EquipmentSummary.fromJson(json['equipmentSummary'] ?? {}),
      slaCompliance: json['slaCompliance'] ?? 0,
      recentActivity: (json['recentActivity'] as List<dynamic>?)
              ?.map((e) => RecentActivity.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class TasksSummary {
  final int total;
  final int open;
  final int completed;
  final int overdue;

  const TasksSummary({
    required this.total,
    required this.open,
    required this.completed,
    required this.overdue,
  });

  factory TasksSummary.fromJson(Map<String, dynamic> json) {
    return TasksSummary(
      total: json['total'] ?? 0,
      open: json['open'] ?? 0,
      completed: json['completed'] ?? 0,
      overdue: json['overdue'] ?? 0,
    );
  }
}

class TechniciansSummary {
  final int total;
  final int active;
  final int avgPerformance;

  const TechniciansSummary({
    required this.total,
    required this.active,
    required this.avgPerformance,
  });

  factory TechniciansSummary.fromJson(Map<String, dynamic> json) {
    return TechniciansSummary(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      avgPerformance: json['avgPerformance'] ?? 0,
    );
  }
}

class AmcsSummary {
  final int total;
  final int active;
  final int expiringSoon;

  const AmcsSummary({
    required this.total,
    required this.active,
    required this.expiringSoon,
  });

  factory AmcsSummary.fromJson(Map<String, dynamic> json) {
    return AmcsSummary(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      expiringSoon: json['expiringSoon'] ?? 0,
    );
  }
}

class EquipmentSummary {
  final int total;
  final int operational;
  final int needsAttention;

  const EquipmentSummary({
    required this.total,
    required this.operational,
    required this.needsAttention,
  });

  factory EquipmentSummary.fromJson(Map<String, dynamic> json) {
    return EquipmentSummary(
      total: json['total'] ?? 0,
      operational: json['operational'] ?? 0,
      needsAttention: json['needsAttention'] ?? 0,
    );
  }
}

class RecentActivity {
  final String type;
  final String description;
  final DateTime timestamp;

  const RecentActivity({
    required this.type,
    required this.description,
    required this.timestamp,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Task summary report
class TaskSummaryReport {
  final int totalTasks;
  final int openTasks;
  final int inProgressTasks;
  final int completedTasks;
  final int closedTasks;
  final int holdTasks;
  final int overdueCount;
  final int escalatedCount;
  final int avgResolutionHours;
  final List<ChartData> tasksByPriority;
  final List<ChartData> tasksByCallType;
  final List<ChartData> tasksByStatus;
  final List<TrendData> dailyTrend;

  const TaskSummaryReport({
    required this.totalTasks,
    required this.openTasks,
    required this.inProgressTasks,
    required this.completedTasks,
    required this.closedTasks,
    required this.holdTasks,
    required this.overdueCount,
    required this.escalatedCount,
    required this.avgResolutionHours,
    required this.tasksByPriority,
    required this.tasksByCallType,
    required this.tasksByStatus,
    required this.dailyTrend,
  });

  factory TaskSummaryReport.fromJson(Map<String, dynamic> json) {
    return TaskSummaryReport(
      totalTasks: json['totalTasks'] ?? 0,
      openTasks: json['openTasks'] ?? 0,
      inProgressTasks: json['inProgressTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      closedTasks: json['closedTasks'] ?? 0,
      holdTasks: json['holdTasks'] ?? 0,
      overdueCount: json['overdueCount'] ?? 0,
      escalatedCount: json['escalatedCount'] ?? 0,
      avgResolutionHours: json['avgResolutionHours'] ?? 0,
      tasksByPriority: (json['tasksByPriority'] as List<dynamic>?)
              ?.map((e) => ChartData(
                    label: e['priority'] ?? '',
                    value: e['count'] ?? 0,
                  ),)
              .toList() ??
          [],
      tasksByCallType: (json['tasksByCallType'] as List<dynamic>?)
              ?.map((e) => ChartData(
                    label: e['callType'] ?? '',
                    value: e['count'] ?? 0,
                  ),)
              .toList() ??
          [],
      tasksByStatus: (json['tasksByStatus'] as List<dynamic>?)
              ?.map((e) => ChartData(
                    label: e['status'] ?? '',
                    value: e['count'] ?? 0,
                  ),)
              .toList() ??
          [],
      dailyTrend: (json['dailyTrend'] as List<dynamic>?)
              ?.map((e) => TrendData.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Technician performance report
class TechnicianPerformanceReport {
  final List<TechnicianPerformance> technicians;
  final List<TopPerformer> topPerformers;
  final int averageResolutionTime;
  final int overallSlaCompliance;

  const TechnicianPerformanceReport({
    required this.technicians,
    required this.topPerformers,
    required this.averageResolutionTime,
    required this.overallSlaCompliance,
  });

  factory TechnicianPerformanceReport.fromJson(Map<String, dynamic> json) {
    return TechnicianPerformanceReport(
      technicians: (json['technicians'] as List<dynamic>?)
              ?.map((e) => TechnicianPerformance.fromJson(e))
              .toList() ??
          [],
      topPerformers: (json['topPerformers'] as List<dynamic>?)
              ?.map((e) => TopPerformer.fromJson(e))
              .toList() ??
          [],
      averageResolutionTime: json['averageResolutionTime'] ?? 0,
      overallSlaCompliance: json['overallSlaCompliance'] ?? 0,
    );
  }
}

class TechnicianPerformance {
  final int id;
  final String name;
  final int totalAssigned;
  final int completed;
  final int inProgress;
  final int avgResolutionHours;
  final double? avgRating;
  final int slaCompliance;
  final int escalations;

  const TechnicianPerformance({
    required this.id,
    required this.name,
    required this.totalAssigned,
    required this.completed,
    required this.inProgress,
    required this.avgResolutionHours,
    this.avgRating,
    required this.slaCompliance,
    required this.escalations,
  });

  factory TechnicianPerformance.fromJson(Map<String, dynamic> json) {
    return TechnicianPerformance(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      totalAssigned: json['totalAssigned'] ?? 0,
      completed: json['completed'] ?? 0,
      inProgress: json['inProgress'] ?? 0,
      avgResolutionHours: json['avgResolutionHours'] ?? 0,
      avgRating: (json['avgRating'] as num?)?.toDouble(),
      slaCompliance: json['slaCompliance'] ?? 0,
      escalations: json['escalations'] ?? 0,
    );
  }
}

class TopPerformer {
  final int id;
  final String name;
  final double score;

  const TopPerformer({
    required this.id,
    required this.name,
    required this.score,
  });

  factory TopPerformer.fromJson(Map<String, dynamic> json) {
    return TopPerformer(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// AMC status report
class AmcStatusReport {
  final int totalAmcs;
  final int activeAmcs;
  final int expiringSoon;
  final int expired;
  final int renewalsDue;
  final List<ChartData> amcsByType;
  final List<ChartData> amcsByServiceType;
  final List<ExpiringContract> expiringContracts;
  final List<ChartData> monthlyRevenue;

  const AmcStatusReport({
    required this.totalAmcs,
    required this.activeAmcs,
    required this.expiringSoon,
    required this.expired,
    required this.renewalsDue,
    required this.amcsByType,
    required this.amcsByServiceType,
    required this.expiringContracts,
    required this.monthlyRevenue,
  });

  factory AmcStatusReport.fromJson(Map<String, dynamic> json) {
    return AmcStatusReport(
      totalAmcs: json['totalAmcs'] ?? 0,
      activeAmcs: json['activeAmcs'] ?? 0,
      expiringSoon: json['expiringSoon'] ?? 0,
      expired: json['expired'] ?? 0,
      renewalsDue: json['renewalsDue'] ?? 0,
      amcsByType: (json['amcsByType'] as List<dynamic>?)
              ?.map((e) => ChartData(
                    label: e['type'] ?? '',
                    value: e['count'] ?? 0,
                  ),)
              .toList() ??
          [],
      amcsByServiceType: (json['amcsByServiceType'] as List<dynamic>?)
              ?.map((e) => ChartData(
                    label: e['serviceType'] ?? '',
                    value: e['count'] ?? 0,
                  ),)
              .toList() ??
          [],
      expiringContracts: (json['expiringContracts'] as List<dynamic>?)
              ?.map((e) => ExpiringContract.fromJson(e))
              .toList() ??
          [],
      monthlyRevenue: (json['monthlyRevenue'] as List<dynamic>?)
              ?.map((e) => ChartData(
                    label: e['month'] ?? '',
                    value: e['count'] ?? 0,
                  ),)
              .toList() ??
          [],
    );
  }
}

class ExpiringContract {
  final int companyId;
  final String companyName;
  final String endDate;
  final int daysRemaining;

  const ExpiringContract({
    required this.companyId,
    required this.companyName,
    required this.endDate,
    required this.daysRemaining,
  });

  factory ExpiringContract.fromJson(Map<String, dynamic> json) {
    return ExpiringContract(
      companyId: json['companyId'] ?? 0,
      companyName: json['companyName'] ?? '',
      endDate: json['endDate'] ?? '',
      daysRemaining: json['daysRemaining'] ?? 0,
    );
  }
}

/// Equipment health report
class EquipmentHealthReport {
  final int totalEquipment;
  final int operational;
  final int underMaintenance;
  final int faulty;
  final int retired;
  final int verifiedCount;
  final int unverifiedCount;
  final List<ChartData> equipmentByStatus;
  final List<ChartData> equipmentByServiceType;
  final List<EquipmentIssue> recentIssues;
  final List<MaintenanceDue> maintenanceDue;

  const EquipmentHealthReport({
    required this.totalEquipment,
    required this.operational,
    required this.underMaintenance,
    required this.faulty,
    required this.retired,
    required this.verifiedCount,
    required this.unverifiedCount,
    required this.equipmentByStatus,
    required this.equipmentByServiceType,
    required this.recentIssues,
    required this.maintenanceDue,
  });

  factory EquipmentHealthReport.fromJson(Map<String, dynamic> json) {
    return EquipmentHealthReport(
      totalEquipment: json['totalEquipment'] ?? 0,
      operational: json['operational'] ?? 0,
      underMaintenance: json['underMaintenance'] ?? 0,
      faulty: json['faulty'] ?? 0,
      retired: json['retired'] ?? 0,
      verifiedCount: json['verifiedCount'] ?? 0,
      unverifiedCount: json['unverifiedCount'] ?? 0,
      equipmentByStatus: (json['equipmentByStatus'] as List<dynamic>?)
              ?.map((e) => ChartData(
                    label: e['status'] ?? '',
                    value: e['count'] ?? 0,
                  ),)
              .toList() ??
          [],
      equipmentByServiceType:
          (json['equipmentByServiceType'] as List<dynamic>?)
                  ?.map((e) => ChartData(
                        label: e['serviceType'] ?? '',
                        value: e['count'] ?? 0,
                      ),)
                  .toList() ??
              [],
      recentIssues: (json['recentIssues'] as List<dynamic>?)
              ?.map((e) => EquipmentIssue.fromJson(e))
              .toList() ??
          [],
      maintenanceDue: (json['maintenanceDue'] as List<dynamic>?)
              ?.map((e) => MaintenanceDue.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class EquipmentIssue {
  final int equipmentId;
  final String equipmentName;
  final int issueCount;
  final String lastIssueDate;

  const EquipmentIssue({
    required this.equipmentId,
    required this.equipmentName,
    required this.issueCount,
    required this.lastIssueDate,
  });

  factory EquipmentIssue.fromJson(Map<String, dynamic> json) {
    return EquipmentIssue(
      equipmentId: json['equipmentId'] ?? 0,
      equipmentName: json['equipmentName'] ?? '',
      issueCount: json['issueCount'] ?? 0,
      lastIssueDate: json['lastIssueDate'] ?? '',
    );
  }
}

class MaintenanceDue {
  final int equipmentId;
  final String equipmentName;
  final String companyName;
  final String dueDate;

  const MaintenanceDue({
    required this.equipmentId,
    required this.equipmentName,
    required this.companyName,
    required this.dueDate,
  });

  factory MaintenanceDue.fromJson(Map<String, dynamic> json) {
    return MaintenanceDue(
      equipmentId: json['equipmentId'] ?? 0,
      equipmentName: json['equipmentName'] ?? '',
      companyName: json['companyName'] ?? '',
      dueDate: json['dueDate'] ?? '',
    );
  }
}

/// SLA compliance report
class SlaComplianceReport {
  final int totalTickets;
  final int withinSla;
  final int slaBreached;
  final int complianceRate;
  final int avgResponseTime;
  final int avgResolutionTime;
  final List<PriorityCompliance> complianceByPriority;
  final List<TechnicianCompliance> complianceByTechnician;
  final List<ChartData> breachReasons;
  final List<MonthlyTrend> monthlyTrend;

  const SlaComplianceReport({
    required this.totalTickets,
    required this.withinSla,
    required this.slaBreached,
    required this.complianceRate,
    required this.avgResponseTime,
    required this.avgResolutionTime,
    required this.complianceByPriority,
    required this.complianceByTechnician,
    required this.breachReasons,
    required this.monthlyTrend,
  });

  factory SlaComplianceReport.fromJson(Map<String, dynamic> json) {
    return SlaComplianceReport(
      totalTickets: json['totalTickets'] ?? 0,
      withinSla: json['withinSla'] ?? 0,
      slaBreached: json['slaBreached'] ?? 0,
      complianceRate: json['complianceRate'] ?? 0,
      avgResponseTime: json['avgResponseTime'] ?? 0,
      avgResolutionTime: json['avgResolutionTime'] ?? 0,
      complianceByPriority: (json['complianceByPriority'] as List<dynamic>?)
              ?.map((e) => PriorityCompliance.fromJson(e))
              .toList() ??
          [],
      complianceByTechnician:
          (json['complianceByTechnician'] as List<dynamic>?)
                  ?.map((e) => TechnicianCompliance.fromJson(e))
                  .toList() ??
              [],
      breachReasons: (json['breachReasons'] as List<dynamic>?)
              ?.map((e) => ChartData(
                    label: e['reason'] ?? '',
                    value: e['count'] ?? 0,
                  ),)
              .toList() ??
          [],
      monthlyTrend: (json['monthlyTrend'] as List<dynamic>?)
              ?.map((e) => MonthlyTrend.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class PriorityCompliance {
  final String priority;
  final int total;
  final int compliant;
  final int rate;

  const PriorityCompliance({
    required this.priority,
    required this.total,
    required this.compliant,
    required this.rate,
  });

  factory PriorityCompliance.fromJson(Map<String, dynamic> json) {
    return PriorityCompliance(
      priority: json['priority'] ?? '',
      total: json['total'] ?? 0,
      compliant: json['compliant'] ?? 0,
      rate: json['rate'] ?? 0,
    );
  }
}

class TechnicianCompliance {
  final int technicianId;
  final String technicianName;
  final int total;
  final int compliant;
  final int rate;

  const TechnicianCompliance({
    required this.technicianId,
    required this.technicianName,
    required this.total,
    required this.compliant,
    required this.rate,
  });

  factory TechnicianCompliance.fromJson(Map<String, dynamic> json) {
    return TechnicianCompliance(
      technicianId: json['technicianId'] ?? 0,
      technicianName: json['technicianName'] ?? '',
      total: json['total'] ?? 0,
      compliant: json['compliant'] ?? 0,
      rate: json['rate'] ?? 0,
    );
  }
}

class MonthlyTrend {
  final String month;
  final int rate;

  const MonthlyTrend({required this.month, required this.rate});

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyTrend(
      month: json['month'] ?? '',
      rate: json['rate'] ?? 0,
    );
  }
}

/// Generic chart data
class ChartData {
  final String label;
  final int value;

  const ChartData({required this.label, required this.value});
}

/// Trend data for time series
class TrendData {
  final String date;
  final int created;
  final int completed;

  const TrendData({
    required this.date,
    required this.created,
    required this.completed,
  });

  factory TrendData.fromJson(Map<String, dynamic> json) {
    return TrendData(
      date: json['date'] ?? '',
      created: json['created'] ?? 0,
      completed: json['completed'] ?? 0,
    );
  }
}
