import 'package:flutter/material.dart';

import '../landing_theme.dart';

class TaskStepsSection extends StatelessWidget {
  const TaskStepsSection({
    super.key,
    this.onSeeHowItWorks,
  });

  final VoidCallback? onSeeHowItWorks;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final imageWidth =
            isMobile ? 1000.0 : constraints.maxWidth.clamp(0.0, 1600.0);
        final banner = SizedBox(
          width: imageWidth,
          child: AspectRatio(
            aspectRatio: 1600 / 569,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  LandingAssets.taskStepsBanner,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.medium,
                ),
                Positioned(
                  left: imageWidth * 0.056,
                  top: imageWidth * (569 / 1600) * 0.074,
                  child: Container(
                    width: imageWidth * 0.126,
                    height: imageWidth * (569 / 1600) * 0.04,
                    color: const Color(0xFF001B12),
                    child: Row(
                      children: [
                        Text(
                          'HOW IT WORKS',
                          style: TextStyle(
                            fontFamily: LandingTypography.fontFamily,
                            color: Colors.white.withValues(alpha: 0.96),
                            fontSize: (imageWidth * 0.0085).clamp(11.0, 14.0),
                            fontWeight: FontWeight.w600,
                            letterSpacing:
                                (imageWidth * 0.0011).clamp(1.3, 1.8),
                          ),
                        ),
                        SizedBox(width: imageWidth * 0.006),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (onSeeHowItWorks != null)
                  Positioned(
                    left: imageWidth * 0.056,
                    top: imageWidth * (569 / 1600) * 0.606,
                    width: imageWidth * 0.146,
                    height: imageWidth * (569 / 1600) * 0.09,
                    child: Semantics(
                      button: true,
                      label: 'See how it works',
                      child: Tooltip(
                        message: 'See how it works',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onSeeHowItWorks,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );

        return isMobile
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: banner,
              )
            : Center(child: banner);
      },
    );
  }
}
