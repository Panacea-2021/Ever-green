import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/router/routes.dart';

const Color _trendDown = Color(0xFFBF0F0F);
const Color _trendUp = Color(0xFF106220);

/// Real count for a stat card plus its month-over-month trend, with the
/// loading / error state.
class _Stat {
  const _Stat(this.value, this.caption, {this.down = false, this.onRetry});
  final String value;
  final String caption;
  final bool down;
  final VoidCallback? onRetry;

  Color get trendColor => down || onRetry != null ? _trendDown : _trendUp;
}

/// Items created this calendar month vs last month, e.g. `50% vs Last Month`.
_Stat _trend(int total, Iterable<DateTime?> created, [DateTime? now]) {
  final today = now ?? DateTime.now();
  final thisMonth = DateTime(today.year, today.month);
  final lastMonth = DateTime(today.year, today.month - 1);
  var current = 0;
  var previous = 0;
  for (final d in created) {
    if (d == null) continue;
    final local = d.toLocal();
    if (!local.isBefore(thisMonth)) {
      current++;
    } else if (!local.isBefore(lastMonth)) {
      previous++;
    }
  }
  final pct = previous == 0
      ? (current == 0 ? 0 : 100)
      : (((current - previous) / previous) * 100).round().abs();
  return _Stat(
    '$total',
    '$pct% vs Last Month',
    down: current < previous,
  );
}

_Stat _statOf<T>(
  AsyncValue<List<T>> async, {
  required bool Function(T) where,
  required DateTime? Function(T) createdAt,
  required VoidCallback onRetry,
}) {
  return async.when(
    skipLoadingOnRefresh: true,
    loading: () => const _Stat('…', 'Loading'),
    error: (_, __) => _Stat('–', 'Failed to load · Retry', onRetry: onRetry),
    data: (all) {
      final items = all.where(where).toList();
      return _trend(items.length, items.map(createdAt));
    },
  );
}

class CompanyDetailsScreen extends ConsumerWidget {
  final String companyId;
  final String? companyName;
  final String? location;
  final String? imageUrl;

  const CompanyDetailsScreen({
    super.key,
    required this.companyId,
    this.companyName,
    this.location,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(companyId);
    Company? company;
    for (final c
        in ref.watch(companiesProvider).valueOrNull ?? const <Company>[]) {
      if (c.id == id) company = c;
    }
    final name = company?.name ?? companyName ?? '';
    final place = company == null
        ? (location ?? '')
        : (company.branchName.isNotEmpty
            ? company.branchName
            : (company.location ?? ''));
    final tasks = _statOf<ServiceTask>(
      ref.watch(tasksProvider),
      where: (t) => id != null && t.company?.id == id,
      createdAt: (t) => t.createdAt,
      onRetry: () => ref.invalidate(tasksProvider),
    );
    final equipments = _statOf<Equipment>(
      ref.watch(equipmentsProvider(id)),
      where: (e) => true,
      createdAt: (e) => DateTime.tryParse('${e.raw['created_at'] ?? ''}'),
      onRetry: () => ref.invalidate(equipmentsProvider(id)),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Header Image - 344px height, full width
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              height: 344,
              child: Image.asset(
                'assets/images/company_header_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.orange.shade400,
                          Colors.orange.shade700,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Back Arrow - left: 16px, top: 54px, size: 24px
            Positioned(
              left: 16,
              top: 54,
              child: GestureDetector(
                onTap: () => context.pop(),
                child: SvgPicture.asset(
                  'assets/images/arrow_back_white.svg',
                  width: 24,
                  height: 24,
                ),
              ),
            ),

            // Title "Company Details" - centered, top: 54px
            const Positioned(
              left: 0,
              right: 0,
              top: 54,
              child: Center(
                child: Text(
                  'Company Details',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
            ),

            // Company Name - left: 16px (centered calc), top: 338px
            Positioned(
              left: 16,
              top: 338,
              right: 16,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: -0.6,
                ),
              ),
            ),

            // Location Icon - left: 16px, top: 377px, size: 16px
            Positioned(
              left: 16,
              top: 377,
              child: SvgPicture.asset(
                'assets/images/location_green.svg',
                width: 16,
                height: 16,
              ),
            ),

            // Location Text - left: 38px, top: 376px
            Positioned(
              left: 38,
              top: 376,
              right: 16,
              child: Text(
                place,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF125420),
                  letterSpacing: -0.42,
                ),
              ),
            ),

            // Tasks Card - left: 16px, top: 425px, w: 361px, h: 151px
            Positioned(
              left: 16,
              top: 425,
              child: _buildStatCard(
                context,
                title: 'Tasks',
                stat: tasks,
                iconAsset: 'assets/images/icon_task.svg',
                chevronLeft: 308, // Tasks card chevron position
                onTap: () {
                  context.push(
                    '${Routes.companyTasks}/$companyId',
                    extra: {'companyName': name},
                  );
                },
              ),
            ),

            // Equipments Card - left: 16px, top: 591px, w: 361px, h: 151px
            Positioned(
              left: 16,
              top: 591,
              child: _buildStatCard(
                context,
                title: 'Equipments',
                stat: equipments,
                iconAsset: 'assets/images/icon_wrench.svg',
                chevronLeft: 312, // Equipments card chevron position
                onTap: () {
                  context.push(
                    '${Routes.companyEquipments}/$companyId',
                    extra: {'companyName': name},
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required _Stat stat,
    required String iconAsset,
    required double chevronLeft,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 361,
        height: 151,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0xBFE0D9EE), // rgba(224,217,238,0.75)
              blurRadius: 32,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Blue Circle Background - left: 15px, top: 17px, size: 34px
            Positioned(
              left: 15,
              top: 17,
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF5FA),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Icon inside circle - left: 23px, top: 24px (for task), left: 24px, top: 26px (for wrench)
            Positioned(
              left: title == 'Tasks' ? 23 : 24,
              top: title == 'Tasks' ? 24 : 26,
              child: SvgPicture.asset(
                iconAsset,
                width: title == 'Tasks' ? 18 : 16,
                height: title == 'Tasks' ? 18 : 16,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF5B899E),
                  BlendMode.srcIn,
                ),
              ),
            ),

            // Title - left: 63px, top: 24px
            Positioned(
              left: 63,
              top: 24,
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0x99000000), // rgba(0,0,0,0.6)
                  letterSpacing: -0.48,
                ),
              ),
            ),

            // Green Chevron Button - right side, top: 22px, size: 24px
            Positioned(
              left: chevronLeft,
              top: 22,
              child: SvgPicture.asset(
                'assets/images/chevron_right_green.svg',
                width: 24,
                height: 24,
              ),
            ),

            // Value - left: 23px, top: 63px
            Positioned(
              left: 23,
              top: 63,
              child: Text(
                stat.value,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5B899E),
                  letterSpacing: -0.96,
                ),
              ),
            ),

            // Bar Chart Image - positioned at bottom right
            // Tasks: left: 271px, top: 89px, w: 61px, h: 41px
            // Equipments: left: 278px, top: 93px, w: 61px, h: 41px
            Positioned(
              left: title == 'Tasks' ? 271 : 278,
              top: title == 'Tasks' ? 89 : 93,
              child: Transform.flip(
                flipY: true,
                child: Transform.rotate(
                  angle: 3.14159, // 180 degrees
                  child: Image.asset(
                    'assets/images/bar_chart.png',
                    width: 61,
                    height: 41,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Trend arrow - left: 18px, top: 114px, size: 20px
            // (asset points up; flipped for a decrease)
            if (stat.onRetry == null)
              Positioned(
                left: 18,
                top: 114,
                child: Transform.flip(
                  flipY: stat.down,
                  child: SvgPicture.asset(
                    'assets/images/arrow_down_red.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      stat.trendColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),

            // Change Text - left: 42px, top: 116px
            Positioned(
              left: stat.onRetry == null ? 42 : 23,
              top: 116,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: stat.onRetry,
                child: Text(
                  stat.caption,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: stat.trendColor,
                    letterSpacing: -0.36,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
