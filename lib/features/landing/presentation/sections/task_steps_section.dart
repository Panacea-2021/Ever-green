import 'package:flutter/material.dart';

import '../landing_theme.dart';

/// Task steps section with dark background, phone mockup, and 3 steps.
class TaskStepsSection extends StatelessWidget {
  const TaskStepsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Container(
      width: double.infinity,
      height: isMobile ? null : 809,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 60 : 7,
      ),
      child: Stack(
        children: [
          // Background image with dark overlay
          Positioned.fill(
            child: _buildBackground(),
          ),

          // Content
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: isMobile ? 0 : 88),
              child: Column(
                children: [
                  // Phone mockup image
                  Expanded(
                    child: _buildPhoneMockup(isMobile),
                  ),

                  // Steps row
                  _buildStepsRow(isMobile, isTablet),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          LandingAssets.taskStepsBg,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.black,
          ),
        ),
        Container(
          color: Colors.black.withOpacity(0.8),
        ),
      ],
    );
  }

  Widget _buildPhoneMockup(bool isMobile) {
    return Center(
      child: Image.asset(
        LandingAssets.phoneMockup,
        width: isMobile ? 280 : 757,
        height: isMobile ? 400 : 574,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: isMobile ? 280 : 757,
          height: isMobile ? 400 : 574,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(
            child: Icon(
              Icons.phone_android,
              size: 80,
              color: Colors.white24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepsRow(bool isMobile, bool isTablet) {
    final steps = [
      _StepData(
        number: 'STEP 1',
        title: 'Create a task',
      ),
      _StepData(
        number: 'STEP 2',
        title: 'Service Engineer will come',
      ),
      _StepData(
        number: 'STEP 3',
        title: 'Get it done after approval',
      ),
    ];

    if (isMobile) {
      return Column(
        children: steps.map((step) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _StepItem(
              data: step,
              isMobile: true,
            ),
          );
        }).toList(),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: steps.map((step) {
          return Expanded(
            child: _StepItem(
              data: step,
              isMobile: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StepData {
  final String number;
  final String title;

  const _StepData({
    required this.number,
    required this.title,
  });
}

class _StepItem extends StatelessWidget {
  final _StepData data;
  final bool isMobile;

  const _StepItem({
    required this.data,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          data.number,
          textAlign: TextAlign.center,
          style: LandingTypography.stepNumber.copyWith(
            fontSize: isMobile ? 11 : 13,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: LandingTypography.taskStepTitle.copyWith(
            fontSize: isMobile ? 24 : 32,
          ),
        ),
      ],
    );
  }
}
