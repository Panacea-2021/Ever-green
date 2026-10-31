import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../sections/landing_site_header.dart';
import '../sections/services/services_bottom_sections.dart';
import '../sections/services/services_common.dart';
import '../sections/services/services_top_sections.dart';
import '../widgets/book_repair_dialog.dart';

enum WebsiteInfoKind { industries, about, howItWorks }

class WebsiteInfoPage extends StatelessWidget {
  const WebsiteInfoPage({super.key, required this.kind});

  final WebsiteInfoKind kind;

  String get _activeNav => switch (kind) {
        WebsiteInfoKind.industries => 'Industries',
        WebsiteInfoKind.about => 'About',
        WebsiteInfoKind.howItWorks => 'How it works',
      };

  String get _eyebrow => switch (kind) {
        WebsiteInfoKind.industries => 'Industries we serve',
        WebsiteInfoKind.about => 'About Evergreen',
        WebsiteInfoKind.howItWorks => 'How it works',
      };

  String get _title => switch (kind) {
        WebsiteInfoKind.industries => 'One service partner. Every kitchen.',
        WebsiteInfoKind.about => 'Keeping commercial kitchens running.',
        WebsiteInfoKind.howItWorks => 'Reliable kitchen care, made simple.',
      };

  String get _description => switch (kind) {
        WebsiteInfoKind.industries =>
          'From busy corporate cafeterias to hygiene-critical hospitals, '
              'Evergreen supports the equipment and teams your kitchen depends on.',
        WebsiteInfoKind.about =>
          'Evergreen brings reliable maintenance, repairs, and ongoing support '
              'to commercial kitchens across India.',
        WebsiteInfoKind.howItWorks =>
          'Tell us what your kitchen needs. We plan the right service, send '
              'a qualified technician, and keep you informed at every step.',
      };

  IconData get _icon => switch (kind) {
        WebsiteInfoKind.industries => Icons.apartment_outlined,
        WebsiteInfoKind.about => Icons.eco_outlined,
        WebsiteInfoKind.howItWorks => Icons.checklist_outlined,
      };

  String get _heroImage => switch (kind) {
        WebsiteInfoKind.industries => SvcAssets.itCampus,
        WebsiteInfoKind.about => SvcAssets.emergency,
        WebsiteInfoKind.howItWorks => SvcAssets.hero,
      };

  Widget get _content => switch (kind) {
        WebsiteInfoKind.industries =>
          const IndustriesSection(lightBackground: true),
        WebsiteInfoKind.about => const WhyChooseSection(),
        WebsiteInfoKind.howItWorks => const ProcessSection(),
      };

  @override
  Widget build(BuildContext context) {
    void go(String route) => context.push(route);

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
            onServices: () => go(Routes.services),
            onIndustries: () => go(Routes.industries),
            onAbout: () => go(Routes.about),
            onHowItWorks: () => go(Routes.howItWorks),
            onContact: () => go(Routes.contact),
            onPrivacy: () => go(Routes.privacy),
            onBookRepair: () => showBookRepairDialog(context),
            onSignIn: () => showWebsiteLoginDialog(context),
            activeNav: _activeNav,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InfoHeroCard(
                    eyebrow: _eyebrow,
                    title: _title,
                    description: _description,
                    icon: _icon,
                    image: _heroImage,
                  ),
                  _content,
                  ServicesCtaSection(
                    onAssessment: () => showWebsiteLoginDialog(context),
                    onContact: () => go(Routes.contact),
                  ),
                  ServicesFooter(
                    onBook: () => showWebsiteLoginDialog(context),
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

class _InfoHeroCard extends StatelessWidget {
  const _InfoHeroCard({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.image,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final String image;

  @override
  Widget build(BuildContext context) {
    final mobile = SvcLayout.isMobile(context);

    return SizedBox(
      height: mobile ? 380 : 460,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            image,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: SvcColors.primaryDeep),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xB30B3B1E),
                  Color(0x660B3B1E),
                  Color(0x1A0B3B1E),
                ],
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: SvcLayout.maxWidth),
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: SvcLayout.hPad(context)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvcEyebrow(eyebrow, light: true),
                          const SizedBox(height: 18),
                          Text(
                            title,
                            style: svcText(
                              size: mobile ? 32 : 48,
                              weight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 700),
                            child: Text(
                              description,
                              style: svcText(
                                size: mobile ? 15 : 17,
                                color: Colors.white.withOpacity(0.92),
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!mobile) ...[
                      const SizedBox(width: 32),
                      Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 56,
                          color: SvcColors.highlightLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
