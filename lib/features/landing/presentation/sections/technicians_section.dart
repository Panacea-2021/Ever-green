import 'package:flutter/material.dart';

import '../landing_theme.dart';

class TechniciansSection extends StatefulWidget {
  const TechniciansSection({super.key, this.onViewAll});

  final VoidCallback? onViewAll;

  @override
  State<TechniciansSection> createState() => _TechniciansSectionState();
}

class _TechniciansSectionState extends State<TechniciansSection> {
  int? _activeCard;
  int _activeArrow = 1;

  static const _cardBounds = [
    (0.046, 0.284, 0.182, 0.65),
    (0.237, 0.284, 0.174, 0.65),
    (0.418, 0.284, 0.17, 0.65),
    (0.596, 0.284, 0.176, 0.65),
    (0.778, 0.284, 0.178, 0.65),
  ];

  void _moveSelection(int offset, int arrowIndex) {
    setState(() {
      final current = _activeCard ?? 0;
      _activeCard =
          (current + offset + _cardBounds.length) % _cardBounds.length;
      _activeArrow = arrowIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final imageWidth =
            isMobile ? 1000.0 : constraints.maxWidth.clamp(0.0, 1600.0);
        final imageHeight = imageWidth * (569 / 1600);
        final banner = SizedBox(
          width: imageWidth,
          child: AspectRatio(
            aspectRatio: 1600 / 569,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  LandingAssets.featuredTechniciansBanner,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
                for (var i = 0; i < _cardBounds.length; i++)
                  if (_activeCard == i)
                    Positioned(
                      left: imageWidth * _cardBounds[i].$1,
                      top: imageHeight * _cardBounds[i].$2,
                      width: imageWidth * _cardBounds[i].$3,
                      height: imageHeight * _cardBounds[i].$4,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF0F6B36),
                              width: imageWidth * 0.003,
                            ),
                            borderRadius: BorderRadius.circular(
                              imageWidth * 0.014,
                            ),
                          ),
                        ),
                      ),
                    ),
                _bannerButton(
                  left: imageWidth * 0.727,
                  top: imageHeight * 0.145,
                  size: imageWidth * 0.036,
                  label: 'Previous technician',
                  icon: Icons.chevron_left,
                  selected: _activeArrow == 0,
                  onTap: () => _moveSelection(-1, 0),
                ),
                _bannerButton(
                  left: imageWidth * 0.768,
                  top: imageHeight * 0.145,
                  size: imageWidth * 0.036,
                  label: 'Next technician',
                  icon: Icons.chevron_right,
                  selected: _activeArrow == 1,
                  onTap: () => _moveSelection(1, 1),
                ),
                if (widget.onViewAll != null)
                  Positioned(
                    left: imageWidth * 0.814,
                    top: imageHeight * 0.145,
                    width: imageWidth * 0.127,
                    height: imageHeight * 0.095,
                    child: Semantics(
                      button: true,
                      label: 'View all technicians',
                      child: Tooltip(
                        message: 'View all technicians',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onViewAll,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );

        return isMobile
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: banner,
              )
            : Center(child: banner);
      },
    );
  }

  Widget _bannerButton({
    required double left,
    required double top,
    required double size,
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: Semantics(
        button: true,
        label: label,
        child: Tooltip(
          message: label,
          child: Material(
            color: selected ? const Color(0xFF0F6B36) : Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF0F6B36),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
