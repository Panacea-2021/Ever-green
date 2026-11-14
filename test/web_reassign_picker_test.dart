// @TestOn('browser')

import 'package:evergreen/core/data/evergreen_repository.dart'
    show techniciansProvider;
import 'package:evergreen/features/auth/domain/models/user_model.dart';
import 'package:evergreen/features/tasks/data/task_provider.dart'
    show TechnicianStats, technicianStatsProvider;
import 'package:evergreen/features/tasks/domain/models/task_item.dart';
import 'package:evergreen/features/tasks/presentation/widgets/task_action_handler.dart';
import 'package:evergreen/shared/providers/auth_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _task = TaskItem(
  id: '42',
  title: 'Replace filter',
  equipment: 'Cold room',
  companyName: 'Evergreen',
  ticketNo: 'EG-42',
  status: TaskStatus.open,
  assignee: 'K Raju',
  createdAt: DateTime(2026, 11, 1),
);

void main() {
  testWidgets('reassign opens a popup with eligible service engineers',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserRoleProvider.overrideWithValue(UserRole.superAdmin),
          techniciansProvider.overrideWith(
            (ref) async => const [
              User(
                id: '8',
                email: 'engineer@example.com',
                name: 'R Srinu',
                role: UserRole.technician,
              ),
            ],
          ),
          technicianStatsProvider.overrideWithValue(const <TechnicianStats>[]),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => TaskActionHandler(context, ref)
                    .assign(_task, reassign: true),
                child: const Text('Reassign'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Reassign'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('Reassign Service Engineer'), findsOneWidget);
    expect(find.text('Currently: K Raju'), findsOneWidget);
    expect(find.text('R Srinu'), findsOneWidget);
    expect(find.text('0 active task(s)'), findsOneWidget);
  });
}
