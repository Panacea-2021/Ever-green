import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../landing_theme.dart';

/// Data model for a step card.
class StepCardData {
  final String number;
  final String label;
  final String title;
  final String description;
  final String iconPath;

  const StepCardData({
    required this.number,
    required this.label,
    required this.title,
    required this.description,
    required this.iconPath,
  });
}

/// "How It Works" section with 5 expandable step cards.
class HowItWorksSection extends StatefulWidget {
  const HowItWorksSection({super.key});

  @override
  State<HowItWorksSection> createState() => _HowItWorksSectionState();
}

class _HowItWorksSectionState extends State<HowItWorksSection> {
  int _activeIndex = 0;

  static const List<StepCardData> _steps = [
    StepCardData(
      number: '01',
      label: 'REGISTER',
      title: 'Register yourself',
      description:
          'Create your Evergreen account for the kitchen, the branch, or the client you look after.',
      iconPath: LandingAssets.iconRegister,
    ),
    StepCardData(
      number: '02',
      label: 'EQUIPMENT',
      title: 'Add equipment',
      description:
          'Log the range, the fridge, and every other machine that has to stay on the line.',
      iconPath: LandingAssets.iconEquipment,
    ),
    StepCardData(
      number: '03',
      label: 'REPAIRS',
      title: 'Add repairs',
      description:
          'Raise a job the moment something leaves the line down, with the fault in plain words.',
      iconPath: LandingAssets.iconRepairs,
    ),
    StepCardData(
      number: '04',
      label: 'SERVICE ENGINEER',
      title: 'Service engineer repair',
      description:
          'A certified service engineer takes the fault on site and puts that machine back to work.',
      iconPath: LandingAssets.iconTechnician,
    ),
    StepCardData(
      number: '05',
      label: 'APPROVE',
      title: 'Approve',
      description:
          'Review the finished job and sign it off before the service engineer leaves.',
      iconPath: LandingAssets.iconApprove,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Container(
      width: double.infinity,
      color: LandingColors.bgMint,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : (isTablet ? 60 : 140),
        vertical: isMobile ? 60 : 112,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          _buildHeader(isMobile, isTablet),

          SizedBox(height: isMobile ? 40 : 64),

          // Step cards
          isMobile ? _buildMobileCards() : _buildDesktopCards(isTablet),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile, bool isTablet) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEyebrow(),
          const SizedBox(height: 24),
          _buildIntroText(isMobile),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildEyebrow(),
        SizedBox(
          width: isTablet ? 400 : 576,
          child: _buildIntroText(isMobile),
        ),
      ],
    );
  }

  Widget _buildEyebrow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          LandingAssets.dot,
          width: 6,
          height: 6,
        ),
        const SizedBox(width: 10),
        Text(
          'HOW IT WORKS',
          style: LandingTypography.eyebrow,
        ),
      ],
    );
  }

  Widget _buildIntroText(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'From signup to\nsign-off in 5 steps',
          style: LandingTypography.sectionSubtitle.copyWith(
            fontSize: isMobile ? 36 : 54,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Getting a kitchen back on the line is easier than it looks — five steps from a new account to a signed-off repair.',
          style: LandingTypography.introBody,
        ),
      ],
    );
  }

  Widget _buildDesktopCards(bool isTablet) {
    return SizedBox(
      height: 420,
      child: Row(
        children: List.generate(_steps.length, (index) {
          final isActive = index == _activeIndex;
          return Expanded(
            flex: isActive ? 3 : 1,
            child: Padding(
              padding: EdgeInsets.only(
                right: index < _steps.length - 1 ? 12 : 0,
              ),
              child: _StepCard(
                data: _steps[index],
                isActive: isActive,
                onTap: () => setState(() => _activeIndex = index),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMobileCards() {
    return Column(
      children: List.generate(_steps.length, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < _steps.length - 1 ? 12 : 0,
          ),
          child: _MobileStepCard(
            data: _steps[index],
            isActive: index == _activeIndex,
            onTap: () => setState(() => _activeIndex = index),
          ),
        );
      }),
    );
  }
}

/// Desktop step card that expands when active.
class _StepCard extends StatefulWidget {
  final StepCardData data;
  final bool isActive;
  final VoidCallback onTap;

  const _StepCard({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: 420,
          decoration: BoxDecoration(
            color: widget.isActive ? LandingColors.primary : Colors.white,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Step label at top
              Positioned(
                top: 24,
                left: 24,
                child: Text(
                  '${widget.data.number}. ${widget.data.label}',
                  style: widget.isActive
                      ? LandingTypography.stepLabel
                      : LandingTypography.stepLabelInactive,
                ),
              ),

              // Icon (centered for inactive, positioned for active)
              if (widget.isActive)
                Positioned(
                  top: 151,
                  left: 24,
                  child: SvgPicture.asset(
                    widget.data.iconPath,
                    width: 36,
                    height: 36,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                )
              else
                Positioned(
                  bottom: 85,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SvgPicture.asset(
                      widget.data.iconPath,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        _isHovered
                            ? LandingColors.primary
                            : LandingColors.textGray,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),

              // Title and description (only visible when active)
              if (widget.isActive)
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.data.title,
                        style: LandingTypography.cardTitle,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.data.description,
                        style: LandingTypography.cardBody,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mobile step card with vertical layout.
class _MobileStepCard extends StatelessWidget {
  final StepCardData data;
  final bool isActive;
  final VoidCallback onTap;

  const _MobileStepCard({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isActive ? LandingColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  data.iconPath,
                  width: 28,
                  height: 28,
                  colorFilter: ColorFilter.mode(
                    isActive ? Colors.white : LandingColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.number}. ${data.label}',
                        style: isActive
                            ? LandingTypography.stepLabel
                            : LandingTypography.stepLabelInactive,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.title,
                        style: LandingTypography.cardTitle.copyWith(
                          fontSize: 18,
                          color: isActive
                              ? Colors.white
                              : LandingColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isActive
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: isActive ? Colors.white : LandingColors.textGray,
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 16),
              Text(
                data.description,
                style: LandingTypography.cardBody.copyWith(
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
