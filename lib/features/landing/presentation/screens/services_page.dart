import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../widgets/web_login_popup.dart';
import '../sections/landing_site_header.dart';
import '../sections/services/services_bottom_sections.dart';
import '../sections/services/services_top_sections.dart';
import '../widgets/book_repair_dialog.dart';

/// Evergreen Services page - commercial kitchen services for businesses.
///
/// Sections: header, hero, services grid, equipment, industries, process,
/// why choose us, AMC plans, case studies, testimonials, FAQ, CTA and footer.
class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final _servicesKey = GlobalKey();
  final _industriesKey = GlobalKey();
  final _processKey = GlobalKey();
  final _whyKey = GlobalKey();
  final _plansKey = GlobalKey();
  final _contactKey = GlobalKey();
  final _faqKey = GlobalKey();

  // Not restored from PageStorage, so the page always opens at the top.
  final _scrollController = ScrollController(keepScrollOffset: false);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    void toContact() => _scrollTo(_contactKey);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          LandingSiteHeader(
            onHome: () {
              while (context.canPop()) {
                context.pop();
              }
              context.go(Routes.home);
            },
            onServices: () => _scrollTo(_servicesKey),
            onIndustries: () => context.push(Routes.industries),
            onAbout: () => context.push(Routes.about),
            onHowItWorks: () => context.push(Routes.howItWorks),
            onContact: () => context.push(Routes.contact),
            onPrivacy: () => context.go(Routes.privacy),
            onBookRepair: () => showBookRepairDialog(context),
            onSignIn: () => showWebLoginPopup(context),
            onSearch: () => _scrollTo(_faqKey),
            activeNav: 'Services',
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ServicesHero(
                    onBook: () => showWebLoginPopup(context),
                    onAssess: toContact,
                  ),
                  ServicesGridSection(
                    key: _servicesKey,
                    onLearnMore: toContact,
                  ),
                  const EquipmentSection(),
                  IndustriesSection(key: _industriesKey),
                  ProcessSection(key: _processKey),
                  WhyChooseSection(key: _whyKey),
                  PlansSection(key: _plansKey, onKnowMore: toContact),
                  const CaseStudiesSection(),
                  const TestimonialsSection(),
                  ServicesFaqSection(key: _faqKey),
                  ServicesCtaSection(
                    key: _contactKey,
                    onAssessment: () => showWebLoginPopup(context),
                    onContact: () => context.go(Routes.contact),
                  ),
                  ServicesFooter(
                    onBook: () => showWebLoginPopup(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
