import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/scaffold_with_bottom_nav.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/custom_menu_icon.dart';
import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';
import '../../../amcs/data/amc_provider.dart';
import '../../../amcs/domain/models/amc_contract.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../notifications/data/notifications_provider.dart';
import '../../../tasks/data/task_provider.dart';
import '../../data/analytics_history_provider.dart';
import '../../data/analytics_provider.dart';
import '../../data/dashboard_repository.dart';
import '../widgets/video_hero.dart';

/// Which metric series the Reports combined chart is showing.
enum _ReportMetric { users, tasks, equipment }

/// Palette + shared style tokens for the dashboard.
class _Palette {
  static const green = Color(0xFF106220);
  static const greenDark = Color(0xFF0D5119);
  static const accentBlue = Color(0xFF344BFD);
  static const up = Color(0xFF04AD2F);
  static const down = Color(0xFFBF0F0F);
  static const amber = Color(0xFFE08600);
  static const danger = Color(0xFFD32F2F);
  static const ink = Color(0xFF1A1A1A);
  static const reportsTint = Color(0xFFF2F7F2);
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedYear = '${DateTime.now().year}';
  _ReportMetric _reportMetric = _ReportMetric.users;

  @override
  Widget build(BuildContext context) {
    // Transparent status bar with light icons while this screen is shown;
    // AnnotatedRegion restores the previous style automatically on pop.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final showOrgOverview =
        Permissions.canViewOrgOverview(ref.watch(currentUserRoleProvider));
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      drawer: const AppDrawer(),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Soft patterned background.
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/images/home_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          RefreshIndicator(
            color: _Palette.green,
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full-bleed video hero (reaches the top edge).
                  _buildVideoHero(context),

                  // Floating summary bar overlapping the hero/content seam.
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: _buildSummaryBar(),
                  ),

                  ..._animatedSections([
                    _buildLoadError(),
                    _buildRenewalReminder(),
                    _buildUnassignedAlert(),
                    _buildRoleCta(),

                    if (showOrgOverview) ...[
                      _sectionHeader('Overview', caption: 'This month'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildOverviewGrid(),
                      ),
                      const SizedBox(height: 24),
                      _buildReportsSection(),
                      const SizedBox(height: 24),
                    ],

                    _sectionHeader(
                        showOrgOverview ? 'Task Status' : 'My Task Status'),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildTaskStatusGrid(),
                    ),

                    // Bottom padding so content clears the FAB / bottom nav.
                    SizedBox(
                      height: ScaffoldWithBottomNav.bottomInset(context),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  SHARED
  // ---------------------------------------------------------------------------

  Widget _sectionHeader(String title, {String? caption}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _Palette.ink,
              letterSpacing: -0.54,
            ),
          ),
          if (caption != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _Palette.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                caption,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _Palette.green,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    ref
      ..invalidate(taskCountsProvider)
      ..invalidate(tasksProvider)
      ..invalidate(companiesProvider)
      ..invalidate(equipmentsProvider(null))
      ..invalidate(dashboardUsersProvider)
      ..invalidate(monthlyStatsProvider)
      ..invalidate(unreadNotificationsCountProvider);
    if (_isAdmin) ref.invalidate(userStatsProvider);
    try {
      await Future.wait([
        ref.read(taskCountsProvider.future),
        ref.read(analyticsHistoryProvider.future),
      ]);
    } catch (_) {
      // Shown by the load-error row.
    }
  }

  bool get _isAdmin {
    final role = ref.read(currentUserRoleProvider);
    return role == UserRole.superAdmin || role == UserRole.manager;
  }

  /// Task counts by status for the caller (`getAllTasksCount`), or null while
  /// loading / on error.
  TaskCounts? get _counts => ref.watch(taskCountsProvider).valueOrNull;

  /// Users visible to the caller; null when the role can't list users.
  List<User>? get _users => ref.watch(dashboardUsersProvider).valueOrNull;

  /// Global per-access-level totals (admins only).
  UserStats? get _userStats {
    final role = ref.watch(currentUserRoleProvider);
    if (role != UserRole.superAdmin && role != UserRole.manager) return null;
    return ref.watch(userStatsProvider).valueOrNull;
  }

  static const _shellRoutes = {
    Routes.home,
    Routes.amcs,
    Routes.tasks,
    Routes.profile,
  };

  /// Opens [route], or null when the signed-in role may not open it, so a
  /// card never leads to the Unauthorized screen.
  VoidCallback? _open(String route, {Object? extra}) {
    final role = ref.watch(currentUserRoleProvider);
    if (!Permissions.canAccessRoute(role, route)) return null;
    return () => _shellRoutes.contains(route)
        ? context.go(route)
        : context.push(route, extra: extra);
  }

  /// A rounded card whose ripple stays inside its corners. Not tappable (and
  /// no press feedback) when [onTap] is null.
  Widget _inkCard({
    required BoxDecoration decoration,
    required double radius,
    required EdgeInsetsGeometry padding,
    required Widget child,
    VoidCallback? onTap,
    Color? splash,
    bool pressScale = true,
  }) {
    final ink = splash ?? _Palette.green;
    final card = Container(
      decoration: decoration,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: ink.withValues(alpha: 0.10),
          highlightColor: ink.withValues(alpha: 0.05),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return onTap != null && pressScale ? _PressableScale(child: card) : card;
  }

  int? _roleCount(bool Function(UserRole) test) {
    final users = _users;
    if (users == null) return null;
    return users.where((u) => test(u.role)).length;
  }

  List<Widget> _animatedSections(List<Widget> sections) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) return sections;
    final out = <Widget>[];
    var visibleIndex = 0;
    for (final section in sections) {
      if (section is SizedBox) {
        out.add(section);
        continue;
      }
      out.add(
        section
            .animate(delay: (visibleIndex * 70).ms)
            .fadeIn(duration: 380.ms, curve: Curves.easeOut)
            .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
      );
      visibleIndex++;
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  //  HERO
  // ---------------------------------------------------------------------------

  Widget _buildVideoHero(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(currentUserRoleProvider);
    final hasName = user?.name.trim().isNotEmpty ?? false;
    final displayName = hasName ? user!.name.trim() : null;
    final dateStr = _todayLabel();

    return VideoHero(
      videoAsset: 'assets/videos/home_hero.mp4',
      // ~15% taller than the previous default (230 -> 265).
      contentHeight: 265,
      fallbackImageAssets: const [
        'assets/images/home_banner.png',
        'assets/images/login_bg.png',
      ],
      overlay: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName != null ? 'Welcome back,' : 'Welcome',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (displayName != null) const SizedBox(height: 2),
                  if (displayName != null)
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.7,
                        shadows: [
                          Shadow(color: Colors.black45, blurRadius: 10),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _roleChip(role.label),
                      const SizedBox(width: 10),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                          shadows: [
                            Shadow(color: Colors.black38, blurRadius: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleChip(String label) {
    return _inkCard(
      onTap: Permissions.hasProfileTab(ref.watch(currentUserRoleProvider))
          ? _open(Routes.profile)
          : null,
      splash: Colors.white,
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  String _todayLabel() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final n = DateTime.now();
    return '${n.day} ${months[n.month - 1]} ${n.year}';
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (context) => CustomMenuIcon(
              onTap: () => Scaffold.of(context).openDrawer(),
              light: true,
            ),
          ),
          const Text(
            'Welcome',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.6,
              shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
            ),
          ),
          Row(
            children: [
              _glassIconButton(
                icon: Icons.qr_code_scanner,
                onTap: () => context.push(Routes.scanner),
              ),
              const SizedBox(width: 8),
              _glassIconButton(
                icon: Icons.notifications_outlined,
                badge: ref.watch(unreadNotificationsCountProvider).valueOrNull,
                onTap: () => context.push(Routes.notifications),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
    int? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          if (badge != null && badge > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF2F00),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Floating card that bridges the hero and the content with 3 quick totals.
  /// Admins see org-wide totals; everyone else sees only their own tasks.
  Widget _buildSummaryBar() {
    final role = ref.watch(currentUserRoleProvider);
    if (!Permissions.canViewOrgOverview(role)) return _buildMyTasksSummaryBar();
    final users = _userStats?.total ?? _users?.length;
    final amcs =
        ref.watch(companiesProvider).valueOrNull?.where((c) => c.isAmc).length;
    final tasks = _counts?.total;

    return _summaryCard([
      _summaryCell(
        Icons.groups_outlined,
        'Users',
        users,
        _Palette.green,
        onTap: _open(Routes.usersList),
      ),
      _summaryDivider(),
      _summaryCell(
        Icons.verified_outlined,
        'AMCs',
        amcs,
        _Palette.amber,
        onTap: _open(Routes.amcs),
      ),
      _summaryDivider(),
      _summaryCell(
        Icons.checklist_rtl_outlined,
        'Tasks',
        tasks,
        _Palette.accentBlue,
        onTap: _open(Routes.tasks),
      ),
    ]);
  }

  /// `getAllTasksCount` is already scoped to the caller's own tickets (service
  /// engineers) or their companies' tickets (client roles).
  Widget _buildMyTasksSummaryBar() {
    final counts = _counts;
    return _summaryCard([
      _summaryCell(
        Icons.pending_actions_outlined,
        'Open',
        counts?.of(TaskStatus.open),
        _Palette.amber,
        onTap: _open(Routes.taskBoard, extra: TaskStatus.open),
      ),
      _summaryDivider(),
      _summaryCell(
        Icons.autorenew,
        'In Progress',
        counts?.of(TaskStatus.inProgress),
        _Palette.green,
        onTap: _open(Routes.taskBoard, extra: TaskStatus.inProgress),
      ),
      _summaryDivider(),
      _summaryCell(
        Icons.checklist_rtl_outlined,
        'My Tasks',
        counts?.total,
        _Palette.accentBlue,
        onTap: _open(Routes.tasks),
      ),
    ]);
  }

  Widget _summaryCard(List<Widget> cells) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(children: cells),
    );
  }

  Widget _summaryDivider() => Container(
        width: 1,
        height: 36,
        color: Colors.black.withValues(alpha: 0.08),
      );

  Widget _summaryCell(
    IconData icon,
    String label,
    int? value,
    Color tint, {
    VoidCallback? onTap,
  }) {
    final content = Column(
      children: [
        Icon(icon, color: tint, size: 20),
        const SizedBox(height: 6),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value ?? 0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Text(
            value == null ? '—' : '$v',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _Palette.ink,
              letterSpacing: -0.6,
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
      ],
    );

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: _inkCard(
          onTap: onTap,
          radius: 16,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: const BoxDecoration(),
          child: content,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  ALERT ROWS
  // ---------------------------------------------------------------------------

  Widget _alertRow({
    required IconData icon,
    required Color accent,
    required Color bg,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: _inkCard(
        onTap: onTap,
        splash: accent,
        radius: 18,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _Palette.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chevron_right, color: accent, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadError() {
    final counts = ref.watch(taskCountsProvider);
    if (!counts.hasError || counts.hasValue) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: _alertRow(
        icon: Icons.cloud_off_outlined,
        accent: _Palette.danger,
        bg: const Color(0xFFFDEEEE),
        title: "Couldn't load your dashboard",
        subtitle: 'Tap to retry',
        onTap: _onRefresh,
      ),
    );
  }

  Widget _buildRenewalReminder() {
    final role = ref.watch(currentUserRoleProvider);
    if (!Permissions.canViewRenewals(role)) return const SizedBox.shrink();
    final due = ref.watch(amcRenewalsProvider);
    if (due.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: _alertRow(
        icon: Icons.notifications_active_outlined,
        accent: _Palette.amber,
        bg: const Color(0xFFFFF7EC),
        title: '${due.length} AMC${due.length == 1 ? '' : 's'} need attention',
        subtitle: 'Tap to review renewals',
        onTap: _open(Routes.amcRenewals),
      ),
    );
  }

  Widget _buildUnassignedAlert() {
    final role = ref.watch(currentUserRoleProvider);
    if (!Permissions.canAssignTasks(role)) return const SizedBox.shrink();
    final unassigned = ref.watch(unassignedTasksProvider);
    if (unassigned.isEmpty) return const SizedBox.shrink();
    final overdue = unassigned.where((t) => t.isOverdue()).length;
    final danger = overdue > 0;
    final accent = danger ? _Palette.danger : _Palette.amber;

    return _alertRow(
      icon: danger ? Icons.error_outline : Icons.assignment_late_outlined,
      accent: accent,
      bg: danger ? const Color(0xFFFDEEEE) : const Color(0xFFFFF7EC),
      title:
          '${unassigned.length} ticket${unassigned.length == 1 ? '' : 's'} need assigning',
      subtitle: danger
          ? '$overdue past SLA • tap to assign'
          : 'Tap to assign a service engineer',
      onTap: _open(Routes.ticketQueue),
    );
  }

  Widget _buildRoleCta() {
    final role = ref.watch(currentUserRoleProvider);
    if (!role.isTechnicianLevel && !role.isClientSide) {
      return const SizedBox.shrink();
    }
    // `getAllTasksCount` is already scoped to the technician's own tickets or
    // the client's companies.
    final openCount = _counts?.active ?? 0;
    final label = role.isTechnicianLevel ? 'My Tasks' : 'My Service Tasks';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: _inkCard(
        onTap: _open(Routes.taskBoard),
        splash: Colors.white,
        radius: 18,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_Palette.green, _Palette.greenDark],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _Palette.green.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.assignment_turned_in_outlined,
              color: Colors.white,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$openCount open task${openCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  OVERVIEW
  // ---------------------------------------------------------------------------

  Widget _buildOverviewGrid() {
    final stats = _userStats;
    final pocCount = stats?.clients ?? _roleCount((r) => r == UserRole.client);
    final clientCount = stats != null
        ? stats.clients + stats.clientAdmins
        : _roleCount((r) => r.isClientSide);
    final managerCount =
        stats?.managers ?? _roleCount((r) => r == UserRole.manager);
    final techCount =
        stats?.technicians ?? _roleCount((r) => r.isTechnicianLevel);

    final pocTrend = ref.watch(trendProvider(TrendMetric.poc));
    final clientTrend = ref.watch(trendProvider(TrendMetric.clients));
    final mgrTrend = ref.watch(trendProvider(TrendMetric.managers));
    final techTrend = ref.watch(trendProvider(TrendMetric.technicians));

    final pocSeries = _series(TrendMetric.poc);
    final clientSeries = _series(TrendMetric.clients);
    final mgrSeries = _series(TrendMetric.managers);
    final techSeries = _series(TrendMetric.technicians);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.person_outline,
                tint: const Color(0xFF2E8B45),
                title: 'POC',
                value: pocCount,
                trend: pocTrend,
                series: pocSeries,
                onTap: _open(Routes.usersList, extra: {'tab': 1}),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _statCard(
                icon: Icons.groups_outlined,
                tint: const Color(0xFF775DAC),
                title: 'Clients',
                value: clientCount,
                trend: clientTrend,
                series: clientSeries,
                onTap: _open(Routes.usersList, extra: {'tab': 0}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.admin_panel_settings_outlined,
                tint: const Color(0xFF9E663B),
                title: 'Managers',
                value: managerCount,
                trend: mgrTrend,
                series: mgrSeries,
                onTap: _open(Routes.usersList, extra: {'tab': 3}),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _statCard(
                icon: Icons.build_outlined,
                tint: const Color(0xFF5B899E),
                title: 'Service Engineers',
                value: techCount,
                trend: techTrend,
                series: techSeries,
                onTap: _open(Routes.techniciansList) ??
                    _open(Routes.usersList, extra: {'tab': 2}),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<double> _series(TrendMetric m) {
    final src = ref.watch(metricSeriesProvider(m));
    final last = src.length <= 6 ? src : src.sublist(src.length - 6);
    return last.map((e) => e.toDouble()).toList();
  }

  Widget _statCard({
    required IconData icon,
    required Color tint,
    required String title,
    required int? value,
    required Trend trend,
    required List<double> series,
    VoidCallback? onTap,
  }) {
    final positive = trend.isPositive;
    final deltaColor = positive ? _Palette.up : _Palette.down;
    return _inkCard(
      onTap: onTap,
      splash: tint,
      radius: 24,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: tint, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.6),
                    letterSpacing: -0.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: value ?? 0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Text(
                  value == null ? '—' : '$v',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: tint,
                    letterSpacing: -0.9,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 30,
                  child: _sparkline(series, tint),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                positive ? Icons.arrow_upward : Icons.arrow_downward,
                color: deltaColor,
                size: 14,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  trend.label,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: deltaColor,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A tiny axis-less line chart used inside stat/KPI cards.
  Widget _sparkline(List<double> data, Color color) {
    if (data.length < 2) return const SizedBox.shrink();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final maxV = data.reduce((a, b) => a > b ? a : b);
    final minV = data.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);
    return LineChart(
      LineChartData(
        minY: minV - range * 0.15,
        maxY: maxV + range * 0.15,
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.0),
                ],
              ),
            ),
            spots: [
              for (int i = 0; i < data.length; i++)
                FlSpot(i.toDouble(), data[i]),
            ],
          ),
        ],
      ),
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 500),
    );
  }

  // ---------------------------------------------------------------------------
  //  REPORTS
  // ---------------------------------------------------------------------------

  Widget _buildReportsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 20),
      decoration: BoxDecoration(
        color: _Palette.reportsTint,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Text(
              'Reports',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _Palette.ink,
                letterSpacing: -0.54,
              ),
            ),
          ),
          _buildKpiGrid(),
          const SizedBox(height: 14),
          _buildTrendCard(),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    final openTasks = _counts?.active ?? 0;
    final onTap = _open(Routes.analytics) ?? _open(Routes.taskBoard);

    final openTrend = ref.watch(trendProvider(TrendMetric.openTasks));
    final closedTrend = ref.watch(trendProvider(TrendMetric.closedTasks));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  icon: Icons.assignment_outlined,
                  tint: _Palette.green,
                  label: 'Open Tasks',
                  value: '$openTasks',
                  trend: openTrend,
                  invert: true,
                  series: _series(TrendMetric.openTasks),
                  onTap: onTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kpiCard(
                  icon: Icons.task_alt,
                  tint: const Color(0xFF5B899E),
                  label: 'Closed (mo)',
                  value: '${closedTrend.current}',
                  trend: closedTrend,
                  series: _series(TrendMetric.closedTasks),
                  onTap: onTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required Color tint,
    required String label,
    required String value,
    required Trend? trend,
    required List<double> series,
    bool invert = false,
    VoidCallback? onTap,
  }) {
    final bool? positive =
        trend == null ? null : (invert ? !trend.isPositive : trend.isPositive);
    final deltaColor = positive == null
        ? Colors.transparent
        : (positive ? _Palette.up : _Palette.down);

    return _inkCard(
      onTap: onTap,
      splash: tint,
      radius: 20,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: tint, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _Palette.ink,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SizedBox(height: 24, child: _sparkline(series, tint)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (positive != null)
            Row(
              children: [
                Icon(
                  positive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: deltaColor,
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  '${trend!.percent}% vs last mo',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: deltaColor,
                  ),
                ),
              ],
            )
          else
            Text(
              'current',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendCard() {
    final (bars, line, labels, _) = _reportSeries();
    final (barLabel, lineLabel) = _reportLegends();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: _inkCard(
        onTap: _open(Routes.analytics),
        pressScale: false,
        radius: 24,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _reportTitle(),
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _Palette.ink,
                      letterSpacing: -0.48,
                    ),
                  ),
                ),
                _yearDropdown(),
              ],
            ),
            const SizedBox(height: 10),
            // Inline legend.
            Row(
              children: [
                _legendDot(_Palette.green, barLabel),
                const SizedBox(width: 16),
                _legendDot(_Palette.accentBlue, lineLabel),
              ],
            ),
            const SizedBox(height: 16),
            _metricToggle(),
            const SizedBox(height: 18),
            SizedBox(
              height: 210,
              child: _buildFlCombinedChart(bars, line, labels),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  (List<double>, List<double>, List<String>, double) _reportSeries() {
    final year = int.tryParse(_selectedYear) ?? DateTime.now().year;
    final snapshots = ref.watch(yearSnapshotsProvider(year));
    final months = snapshots.map(snapshotMonthLabel).toList();
    final (barMetric, lineMetric) = switch (_reportMetric) {
      _ReportMetric.users => (TrendMetric.technicians, TrendMetric.clients),
      _ReportMetric.tasks => (TrendMetric.openTasks, TrendMetric.closedTasks),
      _ReportMetric.equipment => (TrendMetric.equipment, TrendMetric.amcs),
    };
    final barSrc = snapshots.map((s) => s.metric(barMetric)).toList();
    final lineSrc = snapshots.map((s) => s.metric(lineMetric)).toList();

    List<T> lastN<T>(List<T> src, int n) =>
        src.length <= n ? src : src.sublist(src.length - n);

    final bars = lastN(barSrc, 7).map((e) => e.toDouble()).toList();
    final line = lastN(lineSrc, 7).map((e) => e.toDouble()).toList();
    final labels = lastN(months, 7);
    final maxData = [...bars, ...line, 1.0].reduce((a, b) => a > b ? a : b);
    return (bars, line, labels, maxData);
  }

  String _reportTitle() {
    switch (_reportMetric) {
      case _ReportMetric.users:
        return 'Users by Access Level';
      case _ReportMetric.tasks:
        return 'Task Throughput';
      case _ReportMetric.equipment:
        return 'Equipment & Contracts';
    }
  }

  (String, String) _reportLegends() {
    switch (_reportMetric) {
      case _ReportMetric.users:
        return ('Service Engineers', 'Clients');
      case _ReportMetric.tasks:
        return ('Open', 'Closed');
      case _ReportMetric.equipment:
        return ('Equipment', 'AMCs');
    }
  }

  Widget _metricToggle() {
    const items = [
      (_ReportMetric.users, 'Users'),
      (_ReportMetric.tasks, 'Tasks'),
      (_ReportMetric.equipment, 'Equipment'),
    ];
    return Row(
      children: [
        for (final (metric, label) in items)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _reportMetric = metric),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _reportMetric == metric
                      ? _Palette.green
                      : const Color(0xFFEBF0EA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _reportMetric == metric
                        ? Colors.white
                        : Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _yearDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF0EA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedYear,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            letterSpacing: -0.42,
          ),
          items: ref.watch(analyticsYearsProvider).map((y) {
            final year = '$y';
            return DropdownMenuItem(value: year, child: Text(year));
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedYear = value);
          },
        ),
      ),
    );
  }

  /// fl_chart combined view: bars + an overlaid smooth, area-filled line.
  Widget _buildFlCombinedChart(
    List<double> bars,
    List<double> line,
    List<String> labels,
  ) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final n = labels.length;
    if (n == 0) {
      return const Center(
        child: Text(
          'No data yet',
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: Colors.black38,
            fontSize: 13,
          ),
        ),
      );
    }

    final maxVal = [...bars, ...line, 1.0].reduce((a, b) => a > b ? a : b);
    final maxY = (maxVal * 1.25).ceilToDouble();
    final interval = (maxY / 4).ceilToDouble().clamp(1, double.infinity);

    return Stack(
      children: [
        BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            minY: 0,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => _Palette.ink,
                tooltipBorderRadius: BorderRadius.circular(10),
                tooltipPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                  '${labels[group.x]}\n',
                  const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                  children: [
                    TextSpan(
                      text: '${rod.toY.round()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: interval.toDouble(),
                  getTitlesWidget: (v, _) => Text(
                    v.toInt().toString(),
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 10,
                      color: Colors.black38,
                    ),
                  ),
                ),
              ),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= n) return const SizedBox.shrink();
                    final highlight = i >= n - 2;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          fontWeight:
                              highlight ? FontWeight.w700 : FontWeight.w400,
                          color: highlight ? _Palette.green : Colors.black45,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval.toDouble(),
              getDrawingHorizontalLine: (_) => FlLine(
                color: Colors.black.withValues(alpha: 0.06),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              for (int i = 0; i < n; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: i < bars.length ? bars[i] : 0,
                      width: 16,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xFF3AA05A), _Palette.green],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 650),
        ),
        IgnorePointer(
          child: LineChart(
            LineChartData(
              maxY: maxY,
              minY: 0,
              minX: 0,
              maxX: (n - 1).toDouble(),
              titlesData: const FlTitlesData(show: false),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: _Palette.accentBlue,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                      radius: spot.x == (n - 1) ? 4.5 : 0,
                      color: _Palette.accentBlue,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _Palette.accentBlue.withValues(alpha: 0.22),
                        _Palette.accentBlue.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  spots: [
                    for (int i = 0; i < n; i++)
                      FlSpot(i.toDouble(), i < line.length ? line[i] : 0),
                  ],
                ),
              ],
            ),
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 650),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  //  TASK STATUS
  // ---------------------------------------------------------------------------

  Widget _buildTaskStatusGrid() {
    final byStatus = tasksByStatusOf(_counts ?? const TaskCounts({}));
    final open = byStatus['Open']!;
    final hold = byStatus['Hold']!;
    final inProgress = byStatus['In Progress']!;
    final closed = byStatus['Closed']!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _taskCard(
                Icons.check_box_outlined,
                'Open',
                open,
                const Color(0xFF2E8B45),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _taskCard(
                Icons.pause_circle_outline,
                'Hold',
                hold,
                const Color(0xFF775DAC),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _taskCard(
                Icons.timelapse,
                'In Progress',
                inProgress,
                const Color(0xFF9E663B),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _taskCard(
                Icons.check_circle_outline,
                'Closed',
                closed,
                const Color(0xFF5B899E),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _taskCard(IconData icon, String title, int value, Color tint) {
    const statusByTitle = {
      'Open': TaskStatus.open,
      'Hold': TaskStatus.hold,
      'In Progress': TaskStatus.inProgress,
      'Closed': TaskStatus.closed,
    };
    return _inkCard(
      onTap: _open(Routes.taskBoard, extra: statusByTitle[title]),
      splash: tint,
      radius: 24,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: tint, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.6),
                    letterSpacing: -0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              '$v',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: tint,
                letterSpacing: -0.9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps a child so it scales down slightly while pressed — subtle tactile
/// feedback for the dashboard cards.
class _PressableScale extends StatefulWidget {
  final Widget child;

  const _PressableScale({required this.child});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
