class DashboardData {
  final String welcomeMessage;
  final DashboardStats stats;
  final List<DashboardActivity> recentActivities;

  const DashboardData({
    required this.welcomeMessage,
    required this.stats,
    required this.recentActivities,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      welcomeMessage: json['welcomeMessage'] as String,
      stats: DashboardStats.fromJson(json['stats'] as Map<String, dynamic>),
      recentActivities: (json['recentActivities'] as List)
          .map((e) => DashboardActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DashboardStats {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;

  const DashboardStats({
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.pendingTasks = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalTasks: json['totalTasks'] as int? ?? 0,
      completedTasks: json['completedTasks'] as int? ?? 0,
      pendingTasks: json['pendingTasks'] as int? ?? 0,
    );
  }
}

class DashboardActivity {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final ActivityType type;

  const DashboardActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.type = ActivityType.info,
  });

  factory DashboardActivity.fromJson(Map<String, dynamic> json) {
    return DashboardActivity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: ActivityType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ActivityType.info,
      ),
    );
  }
}

enum ActivityType {
  info,
  success,
  warning,
  error,
}
