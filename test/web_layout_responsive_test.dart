import 'package:evergreen/features/audit/data/audit_log_provider.dart';
import 'package:evergreen/features/audit/domain/models/audit_log_entry.dart';
import 'package:evergreen/features/audit/presentation/screens/audit_log_screen.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/features/pm/data/pm_provider.dart';
import 'package:evergreen/features/pm/presentation/screens/pm_schedule_screen.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _EmptyAuditLogRepository implements AuditLogRepository {
  @override
  Future<(List<AuditLogEntry>, int)> getPage(
    int page, {
    AuditEntity? entity,
  }) async =>
      (const <AuditLogEntry>[], 0);
}

void main() {
  testWidgets('PM Schedule status and action fit desktop and narrow web widths',
      (tester) async {
    if (!kIsWeb) return;

    for (final width in [1100.0, 520.0]) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pmProvider.overrideWith((ref) async => const PmState()),
            pmDueSourcesProvider.overrideWith(
              (ref) async => const PmDueSources(),
            ),
          ],
          child: const MaterialApp(home: PmScheduleScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No visits due right now'), findsOneWidget);
      expect(find.text('New Schedule'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Activity History filters and count do not overflow web widths',
      (tester) async {
    if (!kIsWeb) return;

    for (final width in [1200.0, 720.0, 480.0]) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserRoleProvider.overrideWithValue(UserRole.superAdmin),
            auditLogRepositoryProvider
                .overrideWithValue(_EmptyAuditLogRepository()),
          ],
          child: const MaterialApp(home: AuditLogScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('0 entries'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
