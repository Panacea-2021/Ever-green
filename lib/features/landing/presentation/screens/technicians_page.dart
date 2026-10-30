import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../landing_theme.dart';
import '../sections/landing_site_header.dart';
import '../sections/services/services_bottom_sections.dart';

class TechniciansPage extends StatelessWidget {
  const TechniciansPage({super.key});

  static const _technicians = [
    (
      'Meera Iyer',
      'Kitchen Appliance Specialist',
      LandingAssets.techMeera,
    ),
    (
      'Arjun Patel',
      'Refrigeration & Cooling Expert',
      LandingAssets.techArjun,
    ),
    (
      'Sara Qureshi',
      'Ventilation & Hood Specialist',
      LandingAssets.techSara,
    ),
    (
      'Nikhil Rao',
      'Microwave & Small Appliance Expert',
      LandingAssets.techNikhil,
    ),
    (
      'Leela Nair',
      'Laundry Appliance Specialist',
      LandingAssets.techLeela,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LandingColors.bgMain,
      body: Column(
        children: [
          LandingSiteHeader(
            onHome: () => context.go(Routes.home),
            onServices: () => context.go(Routes.services),
            onIndustries: () => context.go(Routes.industries),
            onAbout: () => context.go(Routes.about),
            onHowItWorks: () => context.go(Routes.howItWorks),
            onContact: () => context.go(Routes.contact),
            onPrivacy: () => context.go(Routes.privacy),
            onBookRepair: () => showWebsiteLoginDialog(context),
            onSignIn: () => showWebsiteLoginDialog(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 64, 20, 40),
                    child: Column(
                      children: [
                        const Text(
                          'OUR SERVICE EXPERTS',
                          textAlign: TextAlign.center,
                          style: LandingTypography.eyebrow,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Meet our technicians',
                          textAlign: TextAlign.center,
                          style: LandingTypography.sectionTitle.copyWith(
                            fontSize: MediaQuery.sizeOf(context).width < 600
                                ? 36
                                : 52,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: const Text(
                            'Skilled specialists ready to help keep your '
                            'commercial kitchen equipment running smoothly.',
                            textAlign: TextAlign.center,
                            style: LandingTypography.introBody,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final columns =
                                constraints.maxWidth >= 1000 ? 3 : 2;
                            final cardWidth =
                                (constraints.maxWidth - 24 * (columns - 1)) /
                                    columns;

                            return Wrap(
                              spacing: 24,
                              runSpacing: 24,
                              children: [
                                for (final technician in _technicians)
                                  SizedBox(
                                    width: cardWidth,
                                    child: _TechnicianCard(
                                      name: technician.$1,
                                      specialty: technician.$2,
                                      image: technician.$3,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
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

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard({
    required this.name,
    required this.specialty,
    required this.image,
  });

  final String name;
  final String specialty;
  final String image;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.15,
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: LandingColors.bgMint,
                  child: Icon(
                    Icons.person_outline,
                    size: 64,
                    color: LandingColors.primary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: LandingTypography.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: LandingColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    specialty,
                    style: LandingTypography.introBody.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
