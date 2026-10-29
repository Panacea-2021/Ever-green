import 'package:flutter/material.dart';

import '../landing_theme.dart';

class WhyChooseUsSection extends StatelessWidget {
  const WhyChooseUsSection({super.key});

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
            child: Image.asset(
              LandingAssets.whyChooseUsBanner,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
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
