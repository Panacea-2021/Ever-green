import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/audit_log_entry.dart';

/// Kept so existing call-sites compile. The backend now writes the audit
/// trail itself (sign-in/out, create/update/delete, assign), so nothing is
/// recorded on the device.
extension AuditLogger on WidgetRef {
  void logAudit({
    required AuditAction action,
    required AuditEntity entity,
    required String entityName,
    String? details,
  }) {}
}
