/// The kind of action that was performed.
enum AuditAction { created, updated, deleted, loggedIn, loggedOut, assigned }

/// The type of entity the action was performed on.
enum AuditEntity { user, task, amc, equipment, auth }

extension AuditActionX on AuditAction {
  String get label {
    switch (this) {
      case AuditAction.created:
        return 'Created';
      case AuditAction.updated:
        return 'Updated';
      case AuditAction.deleted:
        return 'Deleted';
      case AuditAction.loggedIn:
        return 'Logged In';
      case AuditAction.loggedOut:
        return 'Logged Out';
      case AuditAction.assigned:
        return 'Assigned';
    }
  }

  String get key => name;

  static AuditAction fromKey(String key) {
    return AuditAction.values.firstWhere(
      (a) => a.name == key,
      orElse: () => AuditAction.updated,
    );
  }

  /// Backend `audit_action` value (`logged_in`, ...).
  String get backendKey =>
      name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

  static AuditAction fromBackend(dynamic key) {
    return AuditAction.values.firstWhere(
      (a) => a.backendKey == '$key' || a.name == '$key',
      orElse: () => AuditAction.updated,
    );
  }
}

extension AuditEntityX on AuditEntity {
  String get label {
    switch (this) {
      case AuditEntity.user:
        return 'User';
      case AuditEntity.task:
        return 'Task';
      case AuditEntity.amc:
        return 'AMC';
      case AuditEntity.equipment:
        return 'Equipment';
      case AuditEntity.auth:
        return 'Auth';
    }
  }

  String get key => name;

  static AuditEntity fromKey(String key) {
    return AuditEntity.values.firstWhere(
      (e) => e.name == key,
      orElse: () => AuditEntity.task,
    );
  }
}

/// A single audit trail entry: who did what, to which entity, and when.
class AuditLogEntry {
  final String id;
  final String actorName;
  final String actorRole;
  final AuditAction action;
  final AuditEntity entity;
  final String entityName;
  final String? details;
  final DateTime timestamp;

  const AuditLogEntry({
    required this.id,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.entity,
    required this.entityName,
    required this.timestamp,
    this.details,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'actorName': actorName,
        'actorRole': actorRole,
        'action': action.key,
        'entity': entity.key,
        'entityName': entityName,
        'details': details,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] as String,
      actorName: json['actorName'] as String? ?? 'Unknown',
      actorRole: json['actorRole'] as String? ?? '',
      action: AuditActionX.fromKey(json['action'] as String? ?? 'updated'),
      entity: AuditEntityX.fromKey(json['entity'] as String? ?? 'task'),
      entityName: json['entityName'] as String? ?? '',
      details: json['details'] as String?,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// A `getAuditLogs` row.
  factory AuditLogEntry.fromBackend(Map<String, dynamic> json) {
    String str(dynamic v) => v == null ? '' : '$v'.trim();
    return AuditLogEntry(
      id: str(json['id']),
      actorName: str(json['actor_name']).isEmpty ? 'Unknown' : str(json['actor_name']),
      actorRole: _roleLabel(str(json['actor_role'])),
      action: AuditActionX.fromBackend(json['action']),
      entity: AuditEntityX.fromKey(str(json['entity'])),
      entityName: str(json['entity_name']),
      details: str(json['details']).isEmpty ? null : str(json['details']),
      timestamp: DateTime.tryParse(str(json['created_at']))?.toLocal() ??
          DateTime.now(),
    );
  }

  /// Backend access levels shown with the app's role labels.
  static String _roleLabel(String role) {
    switch (role) {
      case 'eg_super_admin':
        return 'Super Admin';
      case 'eg_admin':
        return 'Manager';
      case 'senior_technician':
        return 'Senior Service Engineer';
      case 'technician':
        return 'Junior Service Engineer';
      case 'client_admin':
        return 'Client Admin';
      case 'client':
        return 'Client / POC';
      default:
        return role;
    }
  }
}
