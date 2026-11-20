import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sections/web_hero_section.dart';
import '../sections/web_how_it_works_section.dart';
import '../sections/web_task_steps_section.dart';
import '../sections/web_featured_technicians_section.dart';
import '../sections/web_why_choose_us_section.dart';
import '../sections/web_reviews_section.dart';
import '../sections/web_faq_section.dart';
import '../sections/web_download_section.dart';
import '../sections/web_footer_section.dart';

/// The Evergreen **website** home / landing page — a completely different
/// design from the mobile app, assembled from independent section widgets.
/// Reuses the app's data providers (technicians, etc.) for dynamic content.
class WebHomeScreen extends ConsumerWidget {
  const WebHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WebHeroSection(),
            WebHowItWorksSection(),
            WebTaskStepsSection(),
            WebFeaturedTechniciansSection(),
            WebWhyChooseUsSection(),
            WebReviewsSection(),
            WebFaqSection(),
            WebDownloadSection(),
            WebFooterSection(),
          ],
        ),
      ),
    );
  }
}
