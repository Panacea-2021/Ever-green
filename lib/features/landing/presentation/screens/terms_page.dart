import 'package:flutter/material.dart';

import '../landing_theme.dart';
import 'legal_document_page.dart';

/// Website Terms and Conditions page — Figma node 212:167.
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  static const _sections = <(String, List<String>)>[
    (
      'USER AGREEMENT',
      [
        'This User Agreement (this “Agreement”) is a contract between you (“you” or “User”) and Ever Green (“we” or “us”). You must read, agree to, and accept all of the terms and conditions contained in this Agreement in order to use our website, all affiliated websites, including mobile websites and applications, owned or operated by us, our predecessors or successors in interest, or our Affiliates (collectively, the “Site”), all services, applications and products that are accessible through the Site and all Ever Green mobile applications that link to or reference this Agreement, whether provided by us or our Affiliates.',
        'This Agreement includes and incorporates by reference the following: the warranty under Common Questions, the visit window under How it works, and any other agreement you accept before a technician opens a panel, as such agreements may be in effect and amended from time to time.',
      ],
    ),
    (
      'THE VISIT',
      [
        'A booking on the Site is a request for a certified technician to attend the kitchen you name. Ever Green confirms it when the same-day desk accepts the job. Visits run in Hyderabad and Bengaluru. You provide a door, a way to the machine and a person on site who can approve the line before a technician opens a panel.',
        'You tell us which machine left the line down — the range, the fridge, the hood, or another piece of equipment. The technician respects it, names the work, and waits for your sign-off. You do not ask a technician to bypass a safety control.',
      ],
    ),
    (
      'THE PRICE',
      [
        'The price is sent before a panel is opened. Nothing extra lands on the bill after you sign off, unless you ask for more work in writing during the visit.',
        'A booking is not a confirmed appointment until the desk accepts the job and shares the visit window. Same-day visits are the usual window when the line is down; the service engineer works inside the window you were given.',
      ],
    ),
    (
      'WARRANTY',
      [
        'Covered repairs stay covered. The warranty is written into the job note before the service engineer leaves the kitchen.',
        'The warranty covers the named work on the job note. It does not cover a different machine, misuse after sign-off, or a fault that was not part of the approved job.',
      ],
    ),
    (
      'YOUR KITCHEN',
      [
        'Someone who can open the kitchen and sign the job off needs to be there. Service can keep running around the repair.',
        'You keep the area safe and accessible. You do not leave the technician without a way to reach you while they are on site.',
      ],
    ),
    (
      'CHANGES',
      [
        'We may update these terms when the Site or the service changes. The date on this page is the date the current terms took effect. Continued use of the Site after an update means you accept the new terms.',
      ],
    ),
    (
      'CONTACT',
      [
        'Questions about these terms can be sent through Contact Us on the Site. Book a repair if the line is down and you need a technician in the kitchen.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentPage(
      title: 'TERMS AND CONDITIONS',
      heroAsset: LandingAssets.termsHero,
      sections: _sections,
      desktopHeroHeight: 280,
      mobileHeroHeight: 240,
    );
  }
}
