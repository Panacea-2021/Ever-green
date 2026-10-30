import 'package:evergreen/shared/widgets/scroll_to_top_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows after scrolling and returns to the top when tapped',
      (tester) async {
    final controller = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              ListView.builder(
                controller: controller,
                itemCount: 40,
                itemBuilder: (_, i) =>
                    SizedBox(height: 120, child: Text('Row $i')),
              ),
              ScrollToTopButton(controller: controller),
            ],
          ),
        ),
      ),
    );

    AnimatedOpacity fade() => tester.widget<AnimatedOpacity>(
          find.descendant(
            of: find.byType(ScrollToTopButton),
            matching: find.byType(AnimatedOpacity),
          ),
        );

    expect(fade().opacity, 0);

    controller.jumpTo(900);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(fade().opacity, 1);

    await tester.tap(
      find.descendant(
        of: find.byType(ScrollToTopButton),
        matching: find.byType(GestureDetector),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(controller.offset, 0);
    expect(fade().opacity, 0);

    controller.dispose();
  });
}
