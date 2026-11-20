import 'package:flutter/material.dart';

class WebUploadContent extends StatelessWidget {
  const WebUploadContent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 72).clamp(0.0, 680.0).toDouble();
        final height =
            (constraints.maxHeight - 48).clamp(0.0, 600.0).toDouble();
        final contentHeight = (height - 48).clamp(0.0, 552.0).toDouble();
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: contentHeight),
            child: Center(
              child: SizedBox(
                width: width,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
