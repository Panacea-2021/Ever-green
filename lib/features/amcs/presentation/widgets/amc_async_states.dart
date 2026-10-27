import 'package:flutter/material.dart';

const Color _green = Color(0xFF106220);

/// Centered spinner used while company / task data loads.
class AmcLoadingState extends StatelessWidget {
  const AmcLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: _green, strokeWidth: 2.5),
    );
  }
}

/// Error message with a Retry button.
class AmcErrorState extends StatelessWidget {
  const AmcErrorState({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Colors.black.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18, color: _green),
              label: const Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  color: _green,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _green),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon + message for an empty list.
class AmcEmptyState extends StatelessWidget {
  const AmcEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.search_off,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.black.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// Company logo (network) with the building-icon fallback.
class CompanyLogo extends StatelessWidget {
  const CompanyLogo({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.radius = 16,
    this.fallbackIcon = Icons.business,
  });

  final String url;
  final double width;
  final double height;
  final double radius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(fallbackIcon, size: 40, color: Colors.grey.shade400),
    );
    if (url.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}
