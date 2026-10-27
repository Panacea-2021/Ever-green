import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

/// Shared App Header widget matching Figma design
/// Used consistently across all screens
class AppHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMenuTap;
  final bool showBackButton;
  final bool showScannerIcon;
  final bool showNotificationIcon;
  final VoidCallback? onScannerTap;
  final VoidCallback? onNotificationTap;

  const AppHeader({
    super.key,
    required this.title,
    this.onMenuTap,
    this.showBackButton = false,
    this.showScannerIcon = true,
    this.showNotificationIcon = true,
    this.onScannerTap,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Menu Icon
          _buildMenuIcon(context),

          // Title
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: -0.6,
                ),
              ),
            ),
          ),

          // Right Icons
          if (showScannerIcon) ...[
            _buildScannerIcon(context),
            const SizedBox(width: 8),
          ],
          if (showNotificationIcon) _buildNotificationIcon(context),
        ],
      ),
    );
  }

  Widget _buildMenuIcon(BuildContext context) {
    return GestureDetector(
      onTap: onMenuTap ??
          () {
            if (showBackButton) {
              // Prefer GoRouter pop so nested navigation works correctly.
              if (context.canPop()) {
                context.pop();
              } else {
                Navigator.of(context).maybePop();
              }
            } else {
              Scaffold.of(context).openDrawer();
            }
          },
      child: SizedBox(
        width: 42,
        height: 42,
        child: showBackButton
            ? const Icon(
                Icons.arrow_back,
                color: Colors.black,
                size: 24,
              )
            : SvgPicture.asset(
                'assets/images/menu_icon.svg',
                width: 42,
                height: 42,
              ),
      ),
    );
  }

  Widget _buildScannerIcon(BuildContext context) {
    return GestureDetector(
      onTap: onScannerTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.qr_code_scanner,
          color: Colors.black54,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    return GestureDetector(
      onTap: onNotificationTap ?? () => context.push('/notifications'),
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.notifications_outlined,
          color: Colors.black54,
          size: 20,
        ),
      ),
    );
  }
}
