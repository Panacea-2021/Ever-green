import 'package:flutter/material.dart';

import '../landing_theme.dart';
import 'legal_document_page.dart';

/// Website Privacy & Policy page — Figma node 218:199.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  static const _sections = <(String, List<String>)>[
    (
      'USER AGREEMENT',
      [
        'This User Agreement (this “Agreement”) is a contract between you (“you” or “User”) and Ever Green (“we” or “us”). You must read, agree to, and accept all of the terms and conditions contained in this Agreement in order to use our website, all affiliated websites, including mobile websites and applications, owned or operated by us, our predecessors or successors in interest, or our Affiliates (collectively, the “Site”), all services, applications and products that are accessible through the Site and all Ever Green mobile applications that link to or reference this Agreement, whether provided by us or our Affiliates.',
        'This Agreement includes and incorporates by reference the following: the warranty under Common Questions, the visit window under How it works, and the price you accept before a technician opens a panel, as such agreements may be in effect and amended from time to time.',
      ],
    ),
    (
      'THE VISIT',
      [
        'A booking on the Site is a request for a certified technician to attend the kitchen you name. Ever Green confirms it when the same-day desk accepts the job. Visits run in Hyderabad and Bengaluru. You provide a door, a way to the machine and a person on site who can approve the work before the technician leaves.',
        'You tell us which machine left the line down — the range, the fridge, the hood, or another piece of equipment. The technician inspects it, names the work, and waits for your sign-off. You do not ask a technician to bypass a safety control.',
      ],
    ),
    (
      'WHAT WE KEEP',
      [
        'We keep the kitchen name, a mobile number, the machine you named, and the job note so the visit can be booked and signed off. Photos and work notes stay on the job you approved.',
        'We do not sell this information. It is used to run the visit, send the price, and keep the warranty on the job note.',
      ],
    ),
    (
      'WHO SEES IT',
      [
        'The desk, the service engineer on the job, and anyone you name as the person on site can see what they need to finish the visit. Affiliates that host the Site see only what is required to keep the Site running.',
      ],
    ),
    (
      'CHANGES',
      [
        'We may update this policy when the Site or the service changes. The date on this page is the date the current policy took effect. Continued use of the Site after an update means you accept the new policy.',
      ],
    ),
    (
      'CONTACT',
      [
        'Questions about this policy can be sent through Contact Us on the Site.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentPage(
      title: 'PRIVACY AND POLICY',
      heroAsset: LandingAssets.privacyHero,
      sections: _sections,
      desktopHeroHeight: 280,
      mobileHeroHeight: 240,
      bodyOverlap: 36,
      bodyMaxWidth: 1040,
      bodyRadius: 20,
      desktopTitleFontSize: 48,
      heroContentBottomInset: 0,
      showCloseButton: true,
      backgroundColor: Color(0xFFDAF1E1),
    );
  }
}
