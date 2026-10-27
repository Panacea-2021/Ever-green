import 'package:flutter/material.dart';

import '../landing_theme.dart';
import '../sections/hero_section.dart';
import '../sections/how_it_works_section.dart';
import '../sections/task_steps_section.dart';
import '../sections/technicians_section.dart';
import '../sections/why_choose_us_section.dart';
import '../sections/reviews_section.dart';
import '../sections/faq_section.dart';
import '../sections/download_app_section.dart';
import '../sections/footer_section.dart';

/// Evergreen Landing Page - Marketing website homepage.
/// 
/// A pixel-perfect implementation of the Figma design combining all sections:
/// - Hero (header + headline + CTAs)
/// - How It Works (5-step expandable cards)
/// - Task Steps (dark background with phone mockup)
/// - Featured Technicians (horizontal scrolling cards)
/// - Why Choose Us (feature cards with kitchen image)
/// - Client Reviews (testimonial carousel)
/// - FAQ (searchable accordion)
/// - Download App (store badges + phone mockup)
/// - Footer (links + social + copyright)
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LandingColors.white,
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              // 1. Hero section with header navigation
              HeroSection(),
              
              // 2. How It Works - 5-step process
              HowItWorksSection(),
              
              // 3. Task Steps - Dark background with steps
              TaskStepsSection(),
              
              // 4. Featured Technicians - Horizontal card carousel
              TechniciansSection(),
              
              // 5. Why Choose Us - Feature cards with kitchen image
              WhyChooseUsSection(),
              
              // 6. Client Reviews - Testimonial carousel
              ReviewsSection(),
              
              // 7. Common Questions/FAQ - Searchable accordion
              FaqSection(),
              
              // 8. Download Our App - Store badges + phone
              DownloadAppSection(),
              
              // 9. Footer - Links, social icons, copyright
              FooterSection(),
            ],
          ),
        ),
      ),
    );
  }
}
