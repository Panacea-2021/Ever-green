import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../landing_theme.dart';
import '../sections/hero_section.dart';
import '../sections/home_intro_artwork.dart';
import '../sections/services/services_bottom_sections.dart';
import '../sections/task_steps_section.dart';
import '../sections/technicians_section.dart';
import '../sections/why_choose_us_section.dart';
import '../sections/reviews_section.dart';
import '../sections/faq_section.dart';
import '../sections/download_app_section.dart';

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

  void _showTechnicians() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: const [
            Text(
              'Featured technicians',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Meera Iyer'),
              subtitle: Text('Kitchen Appliance Specialist'),
            ),
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Arjun Patel'),
              subtitle: Text('Refrigeration & Cooling Expert'),
            ),
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Sara Qureshi'),
              subtitle: Text('Ventilation & Hood Specialist'),
            ),
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Nikhil Rao'),
              subtitle: Text('Microwave & Small Appliance Expert'),
            ),
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Leela Nair'),
              subtitle: Text('Laundry Appliance Specialist'),
            ),
          ],
        ),
      ),
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
                  onIndustries: () => context.go(Routes.industries),
                  onAbout: () => context.go(Routes.about),
                  onHowItWorks: () => context.go(Routes.howItWorks),
                  onContactUs: () => context.go(Routes.contact),
                  onPrivacy: () => context.go(Routes.privacy),
                  onBookRepair: () => showWebsiteLoginDialog(context),
                  onSignIn: () => showWebsiteLoginDialog(context),
                  onGetEstimate: () => showWebsiteLoginDialog(context),
                  onSearch: () => _scrollTo(_faqKey),
                ),
              ),
              KeyedSubtree(
                key: _trustedKey,
                child: HomeIntroArtwork(
                  stepsKey: _howItWorksKey,
                  onBookRepair: () => showWebsiteLoginDialog(context),
                  onLearnMore: () => _scrollTo(_howItWorksKey),
                ),
              ),
              KeyedSubtree(
                key: _taskStepsKey,
                child: TaskStepsSection(
                  onSeeHowItWorks: () => context.go(Routes.howItWorks),
                ),
              ),
              TechniciansSection(onViewAll: _showTechnicians),
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
              ServicesCtaSection(
                onAssessment: () => showWebsiteLoginDialog(context),
                onContact: () => showWebsiteLoginDialog(context),
              ),
              ServicesFooter(
                onBook: () => showWebsiteLoginDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
