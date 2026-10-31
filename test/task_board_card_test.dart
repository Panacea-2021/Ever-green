import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:evergreen/core/models/backend_models.dart' hide TaskStatus;
import 'package:evergreen/features/tasks/domain/models/task_item.dart';
import 'package:evergreen/features/tasks/presentation/widgets/task_board_card.dart';

const _tech = {'id': 4, 'name': 'Nazir'};

Map<String, dynamic> row({
  String status = 'in_progress',
  Map<String, dynamic>? technician = _tech,
  String priority = 'high',
  String createdAt = '2026-10-01T10:00:00Z',
  bool individual = false,
}) =>
    {
      'id': 77,
      'status': status,
      'technician': technician,
      'updated_at': '2026-10-02T10:00:00Z',
      'task': {
        'id': 12,
        'ticket_no': 'TKT-12',
        'name': 'Fridge not cooling',
        'priority': priority,
        'approval': 'approved',
        'created_at': createdAt,
        if (individual) ...{
          'equipment': null,
          'contact_name': 'Anil Kumar',
          'contact_phone': '+919876543210',
          'address': '12 MG Road, Pune',
        } else
          'equipment': {
            'id': 3,
            'name': 'Fridge',
            'eg_serial_number': 'EG-1',
            'company_link': 9,
            'company': {'id': 9, 'name': 'DMart', 'branch_name': 'Pune'},
          },
      },
    };

TaskItem item(Map<String, dynamic> json) =>
    TaskItem.fromService(ServiceTask.fromJson(json)).copyWith(imageUrl: '');

Future<void> pumpCard(
  WidgetTester tester,
  TaskItem t, {
  VoidCallback? onReport,
  VoidCallback? onAssign,
  VoidCallback? onToggleStar,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TaskBoardCard(
            task: t,
            onTap: () {},
            onReport: onReport ?? () {},
            onAssign: onAssign,
            onToggleStar: onToggleStar,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the design rows and Report + Reassign', (tester) async {
    var reports = 0;
    var assigns = 0;
    await pumpCard(
      tester,
      item(row()),
      onReport: () => reports++,
      onAssign: () => assigns++,
    );
    expect(find.text('Fridge not cooling'), findsOneWidget);
    expect(find.textContaining('Equipment : ', findRichText: true),
        findsOneWidget);
    expect(
        find.textContaining('Company : ', findRichText: true), findsOneWidget);
    expect(find.textContaining('S.No : TKT-12', findRichText: true),
        findsOneWidget);
    expect(find.textContaining('Created At : 01-10-2026', findRichText: true),
        findsOneWidget);
    expect(find.text('Reassign'), findsOneWidget);
    await tester.tap(find.text('Report'));
    await tester.tap(find.text('Reassign'));
    expect(reports, 1);
    expect(assigns, 1);
  });

  testWidgets('unassigned ticket shows Assign', (tester) async {
    await pumpCard(tester, item(row(status: 'open', technician: null)),
        onAssign: () {});
    expect(find.text('Assign'), findsOneWidget);
  });

  testWidgets('roles without assign get a full-width Report only',
      (tester) async {
    await pumpCard(tester, item(row()));
    expect(find.text('Assign'), findsNothing);
    expect(find.text('Reassign'), findsNothing);
    final report = tester.getSize(find
        .ancestor(of: find.text('Report'), matching: find.byType(Container))
        .first);
    final card = tester.getSize(find.byType(TaskBoardCard));
    expect(report.width, greaterThan(card.width * 0.8));
  });

  testWidgets('star is filled for high priority and toggles when allowed',
      (tester) async {
    var toggles = 0;
    await pumpCard(tester, item(row()), onToggleStar: () => toggles++);
    expect(find.byIcon(Icons.star), findsOneWidget);
    await tester.tap(find.byIcon(Icons.star));
    expect(toggles, 1);

    await pumpCard(tester, item(row(priority: 'medium')));
    expect(find.byIcon(Icons.star_border), findsOneWidget);
    await tester.tap(find.byIcon(Icons.star_border));
  });

  testWidgets('individual ticket shows contact and address', (tester) async {
    await pumpCard(tester, item(row(individual: true)));
    expect(find.text('Individual'), findsOneWidget);
    expect(
        find.textContaining('Address : 12 MG Road, Pune', findRichText: true),
        findsOneWidget);
    expect(find.textContaining('Contact : Anil Kumar', findRichText: true),
        findsOneWidget);
    expect(
        find.textContaining('Equipment : ', findRichText: true), findsNothing);
  });

  testWidgets('overdue tickets show the SLA line', (tester) async {
    await pumpCard(tester, item(row()));
    expect(find.textContaining('Overdue by'), findsOneWidget);
    final fresh =
        item(row(createdAt: DateTime.now().toUtc().toIso8601String()));
    await pumpCard(tester, fresh);
    expect(find.textContaining('Overdue by'), findsNothing);
  });
}
