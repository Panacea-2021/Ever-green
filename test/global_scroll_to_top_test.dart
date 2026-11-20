import 'package:evergreen/shared/widgets/global_scroll_to_top.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('global button scrolls the active scrollable to the top',
      (tester) async {
    final controller = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: GlobalScrollToTop(
          child: Scaffold(
            body: SingleChildScrollView(
              controller: controller,
              child: const SizedBox(height: 2000),
            ),
          ),
        ),
      ),
    );

    controller.jumpTo(900);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.descendant(
        of: find.byType(GlobalScrollToTop),
        matching: find.byType(GestureDetector),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(controller.offset, 0);
    controller.dispose();
  });
}
