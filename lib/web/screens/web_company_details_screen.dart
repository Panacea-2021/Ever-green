import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/evergreen_repository.dart';
import '../../core/models/backend_models.dart';
import '../../core/router/routes.dart';
import '../theme/web_dashboard_colors.dart';
import '../theme/web_tokens.dart';

const Color _trendDown = Color(0xFFBF0F0F);
const Color _trendUp = WebDashboardColors.success;

/// Count for a stat card plus its month-over-month trend, with the loading /
/// error state.
class _Stat {
  const _Stat(this.value, this.caption, {this.down = false, this.onRetry});
  final String value;
  final String caption;
  final bool down;
  final VoidCallback? onRetry;

  Color get trendColor => down || onRetry != null ? _trendDown : _trendUp;
}

/// Items created this calendar month vs last month, e.g. `50% vs Last Month`.
_Stat _trend(int total, Iterable<DateTime?> created) {
  final today = DateTime.now();
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
  return _Stat('$total', '$pct% vs Last Month', down: current < previous);
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

/// Web layout of Company Details: same image, name, location and the Tasks /
/// Equipments stats as the mobile screen, arranged as a banner + card row.
class WebCompanyDetailsScreen extends ConsumerWidget {
  const WebCompanyDetailsScreen({
    super.key,
    required this.companyId,
    this.companyName,
    this.location,
  });

  final String companyId;
  final String? companyName;
  final String? location;

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

    final tasksCard = _WebStatCard(
      title: 'Tasks',
      stat: tasks,
      iconAsset: 'assets/images/icon_task.svg',
      onTap: () => context.push(
        '${Routes.companyTasks}/$companyId',
        extra: {'companyName': name},
      ),
    );
    final equipmentsCard = _WebStatCard(
      title: 'Equipments',
      stat: equipments,
      iconAsset: 'assets/images/icon_wrench.svg',
      onTap: () => context.push(
        '${Routes.companyEquipments}/$companyId',
        extra: {'companyName': name},
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Banner(name: name, place: place),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, c) {
                    if (c.maxWidth < 720) {
                      return Column(
                        children: [
                          tasksCard,
                          const SizedBox(height: 18),
                          equipmentsCard,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: tasksCard),
                        const SizedBox(width: 18),
                        Expanded(child: equipmentsCard),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.name, required this.place});
  final String name;
  final String place;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: WebTokens.softShadow,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/company_header_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.orange.shade400, Colors.orange.shade700],
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 20,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: SvgPicture.asset(
                    'assets/images/arrow_back_white.svg',
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 28,
            right: 28,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: WebTokens.display(30, color: Colors.white, h: 1.15),
                ),
                if (place.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/images/location_green.svg',
                          width: 15,
                          height: 15,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WebTokens.bodyText(
                              13.5,
                              color: WebDashboardColors.primaryDark,
                              weight: FontWeight.w700,
                              h: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WebStatCard extends StatefulWidget {
  const _WebStatCard({
    required this.title,
    required this.stat,
    required this.iconAsset,
    required this.onTap,
  });

  final String title;
  final _Stat stat;
  final String iconAsset;
  final VoidCallback onTap;

  @override
  State<_WebStatCard> createState() => _WebStatCardState();
}

class _WebStatCardState extends State<_WebStatCard> {
  static const Color _accent = Color(0xFF5B899E);
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final stat = widget.stat;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hover ? _trendUp.withValues(alpha: 0.35) : WebTokens.line,
            ),
            boxShadow: _hover ? WebTokens.cardShadow : WebTokens.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF5FA),
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      widget.iconAsset,
                      width: 19,
                      height: 19,
                      colorFilter:
                          const ColorFilter.mode(_accent, BlendMode.srcIn),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: WebTokens.heading(17, color: WebTokens.body),
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/images/chevron_right_green.svg',
                    width: 24,
                    height: 24,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stat.value,
                          style: WebTokens.display(38, color: _accent, h: 1.0),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: stat.onRetry,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (stat.onRetry == null) ...[
                                Transform.flip(
                                  flipY: stat.down,
                                  child: SvgPicture.asset(
                                    'assets/images/arrow_down_red.svg',
                                    width: 18,
                                    height: 18,
                                    colorFilter: ColorFilter.mode(
                                      stat.trendColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                stat.caption,
                                style: WebTokens.bodyText(
                                  12.5,
                                  color: stat.trendColor,
                                  weight: FontWeight.w700,
                                  h: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.flip(
                    flipY: true,
                    child: Transform.rotate(
                      angle: 3.14159,
                      child: Image.asset(
                        'assets/images/bar_chart.png',
                        width: 84,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
