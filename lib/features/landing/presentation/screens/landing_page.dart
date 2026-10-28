import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../landing_theme.dart';
import '../sections/hero_section.dart';
import '../sections/home_intro_artwork.dart';
import '../sections/task_steps_section.dart';
import '../sections/technicians_section.dart';
import '../sections/why_choose_us_section.dart';
import '../sections/reviews_section.dart';
import '../sections/faq_section.dart';
import '../sections/download_app_section.dart';
import '../sections/footer_section.dart';

/// Evergreen Landing Page — marketing homepage from the Figma Website frame.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _topKey = GlobalKey();
  final _trustedKey = GlobalKey();
  final _howItWorksKey = GlobalKey();
  final _taskStepsKey = GlobalKey();
  final _whyKey = GlobalKey();
  final _faqKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LandingColors.white,
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeyedSubtree(
                key: _topKey,
                child: HeroSection(
                  onHome: () => _scrollTo(_topKey),
                  onServices: () => context.push(Routes.services),
                  onIndustries: () => _scrollTo(_trustedKey),
                  onAbout: () => _scrollTo(_whyKey),
                  onHowItWorks: () => _scrollTo(_howItWorksKey),
                  onContactUs: () => context.push(Routes.contact),
                  onBookRepair: () => context.go(Routes.login),
                  onSignIn: () => context.go(Routes.login),
                  onGetEstimate: () => context.go(Routes.login),
                  onSearch: () => _scrollTo(_faqKey),
                ),
              ),
              KeyedSubtree(
                key: _trustedKey,
                child: HomeIntroArtwork(
                  stepsKey: _howItWorksKey,
                  onBookRepair: () => context.go(Routes.login),
                  onLearnMore: () => _scrollTo(_howItWorksKey),
                ),
              ),
              KeyedSubtree(
                key: _taskStepsKey,
                child: TaskStepsSection(
                  onSeeHowItWorks: () => _scrollTo(_howItWorksKey),
                ),
              ),
              const TechniciansSection(),
              KeyedSubtree(
                key: _whyKey,
                child: const WhyChooseUsSection(),
              ),
              const ReviewsSection(),
              KeyedSubtree(
                key: _faqKey,
                child: FaqSection(
                  onContactUs: () => context.push(Routes.contact),
                ),
              ),
              const DownloadAppSection(),
              const FooterSection(),
            ],
          ),
        ),
      ),
    );
  }
}
