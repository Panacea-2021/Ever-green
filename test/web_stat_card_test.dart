import 'package:evergreen/web/theme/web_dashboard_colors.dart';
import 'package:evergreen/web/widgets/web_stat_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildCard({bool disableAnimations = false}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 220,
              child: WebStatCard(
                label: 'Open Tasks',
                value: '3',
                icon: Icons.checklist,
                accent: Color(0xFF735A78),
                caption: '3 total',
              ),
            ),
          ),
        ),
      ),
    );
  }

  AnimatedContainer cardContainer(WidgetTester tester) =>
      tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));

  testWidgets('hover applies green styling and leaving restores defaults',
      (tester) async {
    await tester.pumpWidget(buildCard());
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.byType(WebStatCard)));
    await tester.pump();

    final hovered = cardContainer(tester);
    final decoration = hovered.decoration! as BoxDecoration;
    expect(hovered.duration, const Duration(milliseconds: 220));
    expect(decoration.color, WebDashboardColors.successSoft);
    expect(
      decoration.border!.top.color,
      WebDashboardColors.success.withValues(alpha: 0.35),
    );
    expect(hovered.transform!.getTranslation().y, -2.5);
    expect(find.text('Open Tasks'), findsOneWidget);

    await mouse.moveTo(const Offset(0, 400));
    await tester.pump();
    final restored = cardContainer(tester);
    final restoredDecoration = restored.decoration! as BoxDecoration;
    expect(restoredDecoration.color, Colors.white);
    expect(restoredDecoration.border!.top.color, WebDashboardColors.line);
    expect(restored.transform!.getTranslation().y, 0);
    await mouse.removePointer();
  });

  testWidgets('reduced motion disables the transition and lift',
      (tester) async {
    await tester.pumpWidget(buildCard(disableAnimations: true));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.byType(WebStatCard)));
    await tester.pump();

    final hovered = cardContainer(tester);
    expect(hovered.duration, Duration.zero);
    expect(hovered.transform!.getTranslation().y, 0);
    expect(
      (hovered.decoration! as BoxDecoration).color,
      WebDashboardColors.successSoft,
    );
    await mouse.removePointer();
  });
}
