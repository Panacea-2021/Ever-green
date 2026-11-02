import 'dart:math';

import 'package:evergreen/core/models/backend_models.dart';
import 'package:evergreen/core/utils/fuzzy_search.dart';
import 'package:evergreen/core/utils/password_generator.dart';
import 'package:evergreen/features/amcs/data/amc_provider.dart';
import 'package:evergreen/features/audit/domain/models/audit_log_entry.dart';
import 'package:evergreen/features/pickers/presentation/screens/equipment_picker_screen.dart';
import 'package:evergreen/features/tasks/domain/models/task_item.dart'
    show TaskItem;
import 'package:evergreen/features/tasks/presentation/widgets/task_workflow.dart';
import 'package:evergreen/features/users/data/users_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fuzzyMatches', () {
    test('matches plain substrings ignoring case and punctuation', () {
      expect(fuzzyMatches('eg-0042', ['EG0042']), isTrue);
      expect(fuzzyMatches('voltas', ['Voltas AC']), isTrue);
      expect(fuzzyMatches('', ['anything']), isTrue);
    });

    test('tolerates small typos', () {
      expect(fuzzyMatches('voltsa', ['Voltas']), isTrue);
      expect(fuzzyMatches('compresor', ['Air Compressor']), isTrue);
      expect(fuzzyMatches('daiken split', ['Daikin', 'Split AC']), isTrue);
    });

    test('rejects unrelated words and short-word typos', () {
      expect(fuzzyMatches('fridge', ['Voltas AC']), isFalse);
      expect(fuzzyMatches('acx', ['AC']), isFalse);
      expect(fuzzyMatches('voltas chiller', ['Voltas AC']), isFalse);
    });

    test('equipmentMatches searches make, model, serials, type and location',
        () {
      const e = Equipment(
        id: 1,
        name: 'Split AC',
        egSerialNumber: 'EG-0042',
        make: 'Daikin',
        model: 'FTKF50',
        serialNumber: 'SN998',
        type: 'HVAC',
        location: 'Server Room',
      );
      expect(equipmentMatches(e, 'daikn'), isTrue);
      expect(equipmentMatches(e, 'eg 0042'), isTrue);
      expect(equipmentMatches(e, 'servr room'), isTrue);
      expect(equipmentMatches(e, 'hvac'), isTrue);
      expect(equipmentMatches(e, 'boiler'), isFalse);
    });
  });

  group('generatePassword', () {
    test('is 6-20 characters with a digit and a symbol', () {
      for (var seed = 0; seed < 50; seed++) {
        final p = generatePassword(random: Random(seed));
        expect(p.length, 10);
        expect(p, matches(RegExp(r'[2-9]')));
        expect(p, matches(RegExp(r'[@#$%&*!]')));
        expect(p, isNot(matches(RegExp(r'[0O1lI]'))));
      }
      expect(generatePassword(length: 6).length, 6);
    });
  });

  group('credentials email', () {
    test('emailSent reads the backend flag', () {
      expect(UsersRepository.emailSent({'email_sent': true}), isTrue);
      expect(UsersRepository.emailSent({'email_sent': false}), isFalse);
      expect(UsersRepository.emailSent({'message': 'ok'}), isFalse);
      expect(UsersRepository.emailSent(null), isFalse);
    });

    test('CompanyInput sends send_credentials', () {
      const input = CompanyInput(
        name: 'Acme',
        branchName: 'HQ',
        serviceType: CompanyServiceType.regular,
        sendCredentials: false,
      );
      expect(input.toBody()['send_credentials'], isFalse);
    });
  });

  test('issue_type audit entity round-trips', () {
    expect(AuditEntity.issueType.key, 'issue_type');
    expect(AuditEntityX.fromKey('issue_type'), AuditEntity.issueType);
    expect(AuditEntity.issueType.label, 'Issue Type');
  });

  group('task delete', () {
    TaskItem task(TaskStatus status) => TaskItem.fromService(
          ServiceTask.fromJson({
            'id': 7,
            'status': status.key,
            'task': {
              'id': 7,
              'ticket_no': 'TK7',
              'name': 'Leak',
              'location': 'Block B',
              'issue_type': {'id': 4, 'name': 'Installation'},
              'deleted_at': '2026-10-28T10:00:00Z',
              'delete_reason': 'Raised twice',
              'deleter': {'id': 1, 'name': 'Admin'},
            },
          }),
        );

    test('only open tasks can be deleted', () {
      expect(canDeleteTask(task(TaskStatus.open)), isTrue);
      for (final s in [
        TaskStatus.inProgress,
        TaskStatus.hold,
        TaskStatus.completed,
        TaskStatus.closed,
      ]) {
        expect(canDeleteTask(task(s)), isFalse, reason: s.key);
      }
    });

    test('parses location, issue type and deletion details', () {
      final s = task(TaskStatus.open).source!;
      expect(s.location, 'Block B');
      expect(s.issueTypeId, 4);
      expect(s.issueTypeLabel, 'Installation');
      expect(s.deletedAt, isNotNull);
      expect(s.deletedByName, 'Admin');
      expect(s.deleteReason, 'Raised twice');
    });

    testWidgets('delete dialog requires a reason', (tester) async {
      String? result = 'unset';
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result =
                  await askTaskDeleteReason(context, task(TaskStatus.open)),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      final delete = find.widgetWithText(ElevatedButton, 'Delete');
      await tester.tap(delete);
      await tester.pump();
      expect(find.text('Please enter a reason'), findsOneWidget);
      expect(result, 'unset');

      await tester.enterText(
          find.byKey(const Key('deleteReasonField')), '  Duplicate ticket ');
      await tester.pump();
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(result, 'Duplicate ticket');
    });
  });
}
