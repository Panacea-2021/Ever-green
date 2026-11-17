import 'dart:async';

import 'package:evergreen/core/data/evergreen_repository.dart';
import 'package:evergreen/features/landing/data/guest_repair_bookings_repository.dart';
import 'package:evergreen/features/landing/presentation/widgets/book_repair_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'loads API choices, submits selected equipment ID with an idempotency key, '
    'and displays the returned reference',
    (tester) async {
      final repository = _FakeGuestRepairBookingsRepository();
      final equipmentResponse = Completer<List<GuestRepairEquipment>>();

      repository.equipmentResponse = equipmentResponse.future;
      await tester.pumpWidget(_app(repository));
      await tester.tap(find.text('Open Book a Repair'));
      await tester.pump();

      expect(find.text('Loading equipment...'), findsOneWidget);
      equipmentResponse.complete(const [
        GuestRepairEquipment(id: 42, name: 'Live API Oven'),
      ]);
      await tester.pumpAndSettle();

      await _choose(
        tester,
        find.byType(DropdownButtonFormField<int>),
        'Live API Oven',
      );
      await _choose(
        tester,
        find.byType(DropdownButtonFormField<String>),
        'Live API Repair',
      );
      await tester.enterText(find.byType(TextFormField).at(0), 'Jordan Lee');
      await tester.enterText(find.byType(TextFormField).at(1), '+14155550123');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'jordan@example.com',
      );
      await tester.tap(find.text('Get Token'));
      await tester.pumpAndSettle();

      expect(repository.submittedEquipmentId, 42);
      expect(repository.submittedService, 'Live API Repair');
      expect(repository.submittedEmail, 'jordan@example.com');
      expect(
        repository.submittedIdempotencyKey,
        matches(RegExp(r'^[A-Za-z0-9_-]{16,128}$')),
      );
      expect(find.text('EG-0123456789ABCDEF'), findsOneWidget);
      expect(find.text('Enquiry submitted!'), findsOneWidget);
    },
  );

  testWidgets('shows option errors and retries loading from the API', (
    tester,
  ) async {
    final repository = _FakeGuestRepairBookingsRepository()
      ..equipmentFailuresRemaining = 1;
    await tester.pumpWidget(_app(repository));
    await tester.tap(find.text('Open Book a Repair'));
    await tester.pumpAndSettle();

    expect(find.text('Equipment unavailable'), findsOneWidget);
    await tester.tap(
      find.byTooltip('Equipment endpoint unavailable. Retry equipment loading'),
    );
    await tester.pumpAndSettle();

    expect(repository.equipmentCalls, 2);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    expect(find.text('Live API Oven'), findsOneWidget);
  });
}

Widget _app(_FakeGuestRepairBookingsRepository repository) {
  return ProviderScope(
    overrides: [
      guestRepairBookingsRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showBookRepairDialog(context),
            child: const Text('Open Book a Repair'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _choose(
  WidgetTester tester,
  Finder dropdown,
  String option,
) async {
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

class _FakeGuestRepairBookingsRepository
    implements GuestRepairBookingsRepository {
  int equipmentCalls = 0;
  int equipmentFailuresRemaining = 0;
  Future<List<GuestRepairEquipment>>? equipmentResponse;
  int? submittedEquipmentId;
  String? submittedEmail;
  String? submittedIdempotencyKey;
  String? submittedService;

  @override
  Future<List<GuestRepairEquipment>> getEquipment() async {
    equipmentCalls++;
    if (equipmentFailuresRemaining > 0) {
      equipmentFailuresRemaining--;
      throw const RepositoryException('Equipment endpoint unavailable.');
    }
    final response = equipmentResponse;
    if (response != null) return response;
    return const [GuestRepairEquipment(id: 42, name: 'Live API Oven')];
  }

  @override
  Future<List<String>> getServices() async => const ['Live API Repair'];

  @override
  Future<GuestRepairBookingResponse> submitBooking({
    required String name,
    required String phone,
    required String email,
    required int equipmentId,
    required String service,
    required String idempotencyKey,
  }) async {
    submittedEquipmentId = equipmentId;
    submittedEmail = email;
    submittedIdempotencyKey = idempotencyKey;
    submittedService = service;
    return GuestRepairBookingResponse(
      reference: 'EG-0123456789ABCDEF',
      status: 'pending',
      createdAt: DateTime.utc(2026, 11, 16),
    );
  }
}
