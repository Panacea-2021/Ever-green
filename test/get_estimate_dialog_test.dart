import 'package:evergreen/features/landing/presentation/widgets/get_estimate_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('estimate dialog shows and validates all required fields',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_estimateHost());
    await tester.tap(find.text('Get Estimate'));
    await tester.pumpAndSettle();

    expect(find.text('Get a Free Estimate'), findsOneWidget);
    expect(find.text('Select Equipment'), findsOneWidget);
    expect(find.text('Select Service'), findsOneWidget);
    expect(find.text('Describe the Problem'), findsOneWidget);
    expect(find.text('Upload Photos (Optional)'), findsOneWidget);
    expect(find.text('Customer Details'), findsOneWidget);
    expect(find.text('Customer Name'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(
      find.text('Briefly explain the issue with your machinery...'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Our team will review your details and contact you with an estimated repair cost.',
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Request Free Estimate'));
    await tester.tap(find.text('Request Free Estimate'));
    await tester.pumpAndSettle();

    expect(find.text('Equipment is required'), findsOneWidget);
    expect(find.text('Service is required'), findsOneWidget);
    expect(find.text('Problem description is required'), findsOneWidget);
    expect(find.text('Customer name is required'), findsOneWidget);
    expect(find.text('Phone number is required'), findsOneWidget);
    expect(find.byKey(const ValueKey('get-estimate-dialog')), findsOneWidget);

    await tester
        .ensureVisible(find.byKey(const ValueKey('get-estimate-close')));
    await tester.tap(find.byKey(const ValueKey('get-estimate-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('get-estimate-dialog')), findsNothing);
  });

  testWidgets('estimate dialog fits and scrolls on a phone-sized viewport',
      (tester) async {
    tester.view.physicalSize = const Size(375, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_estimateHost());
    await tester.tap(find.text('Get Estimate'));
    await tester.pumpAndSettle();

    expect(find.text('Get a Free Estimate'), findsOneWidget);
    await tester.ensureVisible(find.text('Request Free Estimate'));
    expect(tester.takeException(), isNull);
  });
}

Widget _estimateHost() {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showGetEstimateDialog(context),
              child: const Text('Get Estimate'),
            ),
          ),
        ),
      ),
    ),
  );
}
