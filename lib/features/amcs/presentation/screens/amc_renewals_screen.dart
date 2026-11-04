import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../data/amc_provider.dart';
import '../../domain/models/amc_contract.dart';
import '../../../../web/widgets/web_filter_tiles.dart';
import '../../../../web/widgets/web_search_state.dart';
import '../widgets/amc_async_states.dart';

/// Super Admin / Manager view of AMC contracts that need attention —
/// expiring soon or already expired — with one-tap renewal.
class AmcRenewalsScreen extends ConsumerStatefulWidget {
  const AmcRenewalsScreen({super.key});

  @override
  ConsumerState<AmcRenewalsScreen> createState() => _AmcRenewalsScreenState();
}

class _AmcRenewalsScreenState extends ConsumerState<AmcRenewalsScreen> {
  static const Color _green = Color(0xFF106220);

  // null = All flagged; otherwise filter to this status.
  AmcStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final searchQuery = kIsWeb ? ref.watch(webModuleSearchQueryProvider) : '';
    final companiesAsync = ref.watch(companiesProvider);
    final all = amcContractsFrom(companiesAsync.valueOrNull ?? const [])
        .where((c) => c.company?.isActive != false)
        .toList();
    final flagged = renewalsFrom(all);
    final expiringCount =
        all.where((c) => c.status() == AmcStatus.expiringSoon).length;
    final expiredCount =
        all.where((c) => c.status() == AmcStatus.expired).length;

    final visible = flagged.where((contract) {
      return (_filter == null || contract.status() == _filter) &&
          matchesWebSearch(searchQuery, [
            contract.companyName,
            contract.branchName,
            contract.pocName,
            contract.mobile,
            contract.email,
            contract.serviceType,
            contract.amcCategory,
          ]);
    }).toList();
    final canRenew =
        Permissions.canManageAmcs(ref.watch(currentUserRoleProvider));

    if (kIsWeb) {
      return _webBuild(
        companiesAsync,
        flagged.length,
        expiringCount,
        expiredCount,
        visible,
        canRenew,
      );
    }

    Widget list;
    if (companiesAsync.hasError && !companiesAsync.hasValue) {
      list = AmcErrorState(
        error: companiesAsync.error!,
        onRetry: () => ref.invalidate(companiesProvider),
      );
    } else if (!companiesAsync.hasValue) {
      list = const AmcLoadingState();
    } else {
      list = RefreshIndicator(
        color: _green,
        onRefresh: () => ref.refresh(companiesProvider.future),
        child: visible.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [SizedBox(height: 300, child: _buildEmpty())],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: visible.length,
                itemBuilder: (_, i) => _buildCard(visible[i], canRenew),
              ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      body: Stack(
        children: [
          // Soft patterned background, matching the Home page.
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
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(flagged.length),
                _buildSummary(expiringCount, expiredCount),
                _buildFilters(),
                const SizedBox(height: 4),
                Expanded(child: list),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Web layout: summary tiles, a segmented filter and a grid of renewal cards.
  // ---------------------------------------------------------------------------

  Widget _webBuild(
    AsyncValue<List<Company>> companiesAsync,
    int dueCount,
    int expiring,
    int expired,
    List<AmcContract> visible,
    bool canRenew,
  ) {
    Widget body;
    if (companiesAsync.hasError && !companiesAsync.hasValue) {
      body = SizedBox(
        height: 360,
        child: AmcErrorState(
          error: companiesAsync.error!,
          onRetry: () => ref.invalidate(companiesProvider),
        ),
      );
    } else if (!companiesAsync.hasValue) {
      body = const SizedBox(height: 360, child: AmcLoadingState());
    } else if (visible.isEmpty) {
      body = Container(
        height: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8E3)),
        ),
        child: _buildEmpty(),
      );
    } else {
      body = LayoutBuilder(
        builder: (context, c) => _webGrid(
          c.maxWidth,
          [for (final a in visible) _webCard(a, canRenew)],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: _green,
        onRefresh: () => ref.refresh(companiesProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 32),
          children: [
            LayoutBuilder(
              builder: (context, c) {
                final filters = WebFilterTiles(
                  options: [
                    for (final f
                        in <(String, AmcStatus?, int, IconData, Color)>[
                      ('All', null, dueCount, Icons.dashboard_outlined, _green),
                      (
                        'Expiring Soon',
                        AmcStatus.expiringSoon,
                        expiring,
                        Icons.schedule,
                        const Color(0xFFE08600),
                      ),
                      (
                        'Expired',
                        AmcStatus.expired,
                        expired,
                        Icons.error_outline,
                        const Color(0xFFD32F2F),
                      ),
                    ])
                      WebFilterOption(
                        label: f.$1,
                        count: f.$3,
                        icon: f.$4,
                        color: f.$5,
                        selected: _filter == f.$2,
                        onTap: () => setState(() => _filter = f.$2),
                      ),
                  ],
                );
                if (c.maxWidth < 900) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _webDueTile(dueCount),
                      const SizedBox(height: 14),
                      filters,
                    ],
                  );
                }
                return Row(
                  children: [
                    SizedBox(
                      width: (c.maxWidth - 44) / 4,
                      child: _webDueTile(dueCount),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: filters),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            body,
          ],
        ),
      ),
    );
  }

  Widget _webDueTile(int count) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF106220), Color(0xFF0B4517)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.autorenew, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count due',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _webMonths = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  /// Tear-off calendar block showing the contract end date.
  Widget _webCalendarTile(DateTime d, Color accent) {
    return Container(
      width: 58,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: accent,
            alignment: Alignment.center,
            child: Text(
              _webMonths[d.month - 1],
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              '${d.day}',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 21,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: Color(0xFF14201A),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              '${d.year}',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A988E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _webGrid(double width, List<Widget> cards) {
    const gap = 18.0;
    final cols = width >= 1050
        ? 3
        : width >= 680
            ? 2
            : 1;
    return Column(
      children: [
        for (var i = 0; i < cards.length; i += cols)
          Padding(
            padding: const EdgeInsets.only(bottom: gap),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = i; j < i + cols; j++) ...[
                    if (j > i) const SizedBox(width: gap),
                    Expanded(
                      child:
                          j < cards.length ? cards[j] : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _webCard(AmcContract c, bool canRenew) {
    final status = c.status();
    final days = c.daysUntilExpiry();
    final (Color accent, Color bg) = switch (status) {
      AmcStatus.expired => (const Color(0xFFD32F2F), const Color(0xFFFDE8E8)),
      AmcStatus.expiringSoon => (
          const Color(0xFFE08600),
          const Color(0xFFFFF4E5)
        ),
      AmcStatus.active => (_green, const Color(0xFFEBF0EA)),
    };
    final expiryText = days < 0
        ? 'Expired ${-days} day${days == -1 ? '' : 's'} ago'
        : days == 0
            ? 'Expires today'
            : 'Expires in $days day${days == 1 ? '' : 's'}';

    return _WebLift(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8E3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _webCalendarTile(c.endDate, accent),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.companyName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                  color: Color(0xFF14201A),
                                ),
                              ),
                              if (c.branchName.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 13,
                                      color: Color(0xFF8A8A8A),
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        c.branchName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF6B6B6B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            status.label,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: bg.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            status == AmcStatus.expired
                                ? Icons.event_busy_outlined
                                : Icons.event_outlined,
                            size: 20,
                            color: accent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              expiryText,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _metaRow(
                      Icons.calendar_today_outlined,
                      'Ends ${_fmt(c.endDate)}',
                    ),
                    const SizedBox(height: 8),
                    _metaRow(
                      Icons.person_outline,
                      'POC ${c.pocName.isEmpty ? '—' : c.pocName}',
                    ),
                    if (canRenew) ...[
                      const Spacer(),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmRenew(c),
                          icon: const Icon(
                            Icons.autorenew,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Renew',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          if (kIsWeb)
            const Spacer()
          else ...[
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: Color(0xFF1F1F1F),
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'AMC Renewals',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F1F),
                ),
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count due',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(int expiring, int expired) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              'Expiring Soon',
              expiring,
              const Color(0xFFFFF4E5),
              const Color(0xFFE08600),
              Icons.schedule,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryCard(
              'Expired',
              expired,
              const Color(0xFFFDE8E8),
              const Color(0xFFD32F2F),
              Icons.error_outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    String label,
    int value,
    Color bg,
    Color fg,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: fg, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fg.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final chips = <MapEntry<String, AmcStatus?>>[
      const MapEntry('All', null),
      const MapEntry('Expiring Soon', AmcStatus.expiringSoon),
      const MapEntry('Expired', AmcStatus.expired),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = _filter == chips[i].value;
          return GestureDetector(
            onTap: () => setState(() => _filter = chips[i].value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: selected ? _green : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? _green : const Color(0xFFE3E3E3),
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _green.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                chips[i].key,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF545454),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(AmcContract c, bool canRenew) {
    final status = c.status();
    final days = c.daysUntilExpiry();
    final (Color accent, Color bg) = switch (status) {
      AmcStatus.expired => (const Color(0xFFD32F2F), const Color(0xFFFDE8E8)),
      AmcStatus.expiringSoon => (
          const Color(0xFFE08600),
          const Color(0xFFFFF4E5)
        ),
      AmcStatus.active => (_green, const Color(0xFFEBF0EA)),
    };
    final expiryText = days < 0
        ? 'Expired ${-days} day${days == -1 ? '' : 's'} ago'
        : days == 0
            ? 'Expires today'
            : 'Expires in $days day${days == 1 ? '' : 's'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE0D9EE),
            blurRadius: 28,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status accent stripe down the left edge.
              Container(width: 6, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.companyName,
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F1F1F),
                                  ),
                                ),
                                if (c.branchName.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                        color: Color(0xFF8A8A8A),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        c.branchName,
                                        style: const TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF6B6B6B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.label,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Expiry highlight row with a tinted icon badge.
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: bg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              status == AmcStatus.expired
                                  ? Icons.event_busy_outlined
                                  : Icons.event_outlined,
                              size: 18,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              expiryText,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Meta rows.
                      _metaRow(
                        Icons.calendar_today_outlined,
                        'Ends ${_fmt(c.endDate)}',
                      ),
                      const SizedBox(height: 6),
                      _metaRow(
                        Icons.person_outline,
                        'POC ${c.pocName.isEmpty ? '—' : c.pocName}',
                      ),
                      if (canRenew) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF125420), Color(0xFF106220)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: _green.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _confirmRenew(c),
                                child: const Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.autorenew,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Renew',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF9A9A9A)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B6B6B),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRenew(AmcContract c) async {
    final result = await showGeneralDialog<_RenewResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Renew AMC',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, __, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 4 * anim.value,
            sigmaY: 4 * anim.value,
          ),
          child: Opacity(
            opacity: anim.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.85 + 0.15 * curved.value,
              child: _RenewAmcDialog(contract: c),
            ),
          ),
        );
      },
    );
    final company = c.company;
    if (result == null || company == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(amcRepositoryProvider).renewCompany(
            company,
            startDate: result.startDate,
            endDate: result.endDate,
            amcType: result.amcType,
          );
      ref.invalidate(companiesProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${c.companyName} renewed until ${_fmt(result.endDate)}',
          ),
          backgroundColor: _green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: const Color(0xFFD32F2F)),
      );
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No renewals due',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B6B6B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'All AMC contracts are active.',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              color: Color(0xFF9B9B9B),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
}

/// Lifts its child slightly while hovered (web cards).
class _WebLift extends StatefulWidget {
  const _WebLift({required this.child});
  final Widget child;

  @override
  State<_WebLift> createState() => _WebLiftState();
}

class _WebLiftState extends State<_WebLift> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        child: widget.child,
      ),
    );
  }
}

/// The user's chosen renewal term, returned from [_RenewAmcDialog].
class _RenewResult {
  const _RenewResult(this.startDate, this.endDate, this.amcType);
  final DateTime startDate;
  final DateTime endDate;
  final AmcType? amcType;
}

/// Renewal dialog that lets the user pick a term (6 months, 1 year, 2 years,
/// or a custom end date) and a start date, with the resulting end date shown
/// live before confirming.
class _RenewAmcDialog extends StatefulWidget {
  const _RenewAmcDialog({required this.contract});

  final AmcContract contract;

  @override
  State<_RenewAmcDialog> createState() => _RenewAmcDialogState();
}

class _RenewAmcDialogState extends State<_RenewAmcDialog> {
  static const Color _green = Color(0xFF106220);

  // Preset terms in months; null = custom end date.
  static const List<(String, int?)> _terms = [
    ('6 Months', 6),
    ('1 Year', 12),
    ('2 Years', 24),
    ('Custom', null),
  ];

  late DateTime _startDate;
  int _termIndex = 1; // default to 1 Year
  DateTime? _customEnd;

  /// Legacy companies have no AMC type yet; the backend needs one to save.
  late final bool _needsAmcType = widget.contract.company?.amcType == null;
  AmcType? _amcType;
  bool _amcTypeMissing = false;

  @override
  void initState() {
    super.initState();
    // Start a renewal from today, or from the old end date if it's still in
    // the future (so an early renewal extends rather than shortens the term).
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = widget.contract.endDate;
    _startDate = end.isAfter(today) ? end : today;
  }

  int? get _months => _terms[_termIndex].$2;

  DateTime get _endDate {
    final m = _months;
    if (m == null) {
      // Custom: fall back to +1 year from start until a date is picked.
      return _customEnd ?? addMonthsClamped(_startDate, 12);
    }
    return addMonthsClamped(_startDate, m);
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 10),
      builder: _greenPickerTheme,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Keep a custom end valid relative to the new start.
        if (_customEnd != null && !_customEnd!.isAfter(picked)) {
          _customEnd = null;
        }
      });
    }
  }

  Future<void> _pickCustomEnd() async {
    final initial = _customEnd ?? addMonthsClamped(_startDate, 12);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: DateTime(DateTime.now().year + 15),
      builder: _greenPickerTheme,
    );
    if (picked != null) {
      setState(() => _customEnd = picked);
    }
  }

  Widget _greenPickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: _green,
          onPrimary: Colors.white,
          onSurface: Color(0xFF1F1F1F),
        ),
      ),
      child: child!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = _months == null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33106220),
                  blurRadius: 40,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F0E8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.autorenew, color: _green, size: 30),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Renew AMC',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.contract.companyName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
                const SizedBox(height: 20),

                // Term selector.
                _sectionLabel('Renewal term'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _terms.length; i++)
                      _termChip(_terms[i].$1, i),
                  ],
                ),
                if (_needsAmcType) ...[
                  const SizedBox(height: 18),
                  _sectionLabel('AMC category'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in const [AmcType.ncAmc, AmcType.cAmc])
                        _chip(
                          t.label,
                          selected: _amcType == t,
                          onTap: () => setState(() {
                            _amcType = t;
                            _amcTypeMissing = false;
                          }),
                        ),
                    ],
                  ),
                  if (_amcTypeMissing) ...[
                    const SizedBox(height: 6),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Please select an AMC category',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 18),

                // Start date row.
                _dateRow(
                  label: 'Start date',
                  value: _fmt(_startDate),
                  onTap: _pickStartDate,
                ),

                // Custom end date row (only when Custom is selected).
                if (isCustom) ...[
                  const SizedBox(height: 10),
                  _dateRow(
                    label: 'End date',
                    value: _customEnd == null ? 'Select date' : _fmt(_endDate),
                    onTap: _pickCustomEnd,
                    highlight: true,
                    placeholder: _customEnd == null,
                  ),
                ],

                const SizedBox(height: 16),

                // New end summary.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7F4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _summaryPill(
                        'Current end',
                        _fmt(widget.contract.endDate),
                        false,
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: _green,
                      ),
                      _summaryPill('New end', _fmt(_endDate), true),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD8D8D8)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF545454),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF125420), Color(0xFF106220)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _green.withValues(alpha: 0.32),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _confirm,
                              child: const Center(
                                child: Text(
                                  'Confirm Renewal',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8A8A8A),
        ),
      ),
    );
  }

  void _confirm() {
    if (_needsAmcType && _amcType == null) {
      setState(() => _amcTypeMissing = true);
      return;
    }
    Navigator.pop(context, _RenewResult(_startDate, _endDate, _amcType));
  }

  Widget _termChip(String label, int index) => _chip(
        label,
        selected: _termIndex == index,
        onTap: () => setState(() => _termIndex = index),
      );

  Widget _chip(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _green : const Color(0xFFE3E3E3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF545454),
          ),
        ),
      ),
    );
  }

  Widget _dateRow({
    required String label,
    required String value,
    required VoidCallback onTap,
    bool highlight = false,
    bool placeholder = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E3E3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 17,
              color: highlight ? _green : const Color(0xFF8A8A8A),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B6B6B),
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: placeholder
                    ? const Color(0xFFB0B0B0)
                    : (highlight ? _green : const Color(0xFF1F1F1F)),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Color(0xFF9A9A9A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryPill(String label, String date, bool highlight) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9A9A9A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            date,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: highlight ? _green : const Color(0xFF444444),
            ),
          ),
        ],
      ),
    );
  }
}
