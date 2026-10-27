import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../sections/services/services_bottom_sections.dart';
import '../sections/services/services_top_sections.dart';

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
  final _whyKey = GlobalKey();
  final _plansKey = GlobalKey();
  final _contactKey = GlobalKey();

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
          ServicesHeader(
            onLogo: () => context.go(Routes.home),
            onBook: toContact,
            items: [
              SvcNavItem('Home', () => context.go(Routes.home)),
              SvcNavItem('Services', () => _scrollTo(_servicesKey), active: true),
              SvcNavItem('Industries', () => _scrollTo(_industriesKey)),
              SvcNavItem('Plans', () => _scrollTo(_plansKey)),
              SvcNavItem('About', () => _scrollTo(_whyKey)),
              SvcNavItem('Contact', toContact),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ServicesHero(onBook: toContact, onAssess: toContact),
                  ServicesGridSection(key: _servicesKey, onLearnMore: toContact),
                  const EquipmentSection(),
                  IndustriesSection(key: _industriesKey),
                  const ProcessSection(),
                  WhyChooseSection(key: _whyKey),
                  PlansSection(key: _plansKey, onKnowMore: toContact),
                  const CaseStudiesSection(),
                  const TestimonialsSection(),
                  const ServicesFaqSection(),
                  ServicesCtaSection(
                    key: _contactKey,
                    onAssessment: () => context.go(Routes.login),
                    onContact: () => context.go(Routes.login),
                  ),
                  ServicesFooter(onBook: toContact),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
