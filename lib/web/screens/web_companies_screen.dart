import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/permissions.dart';
import '../../core/data/evergreen_repository.dart';
import '../../core/models/backend_models.dart';
import '../../core/router/routes.dart';
import '../../features/amcs/data/amc_provider.dart';
import '../../features/amcs/domain/models/amc_contract.dart';
import '../../features/amcs/presentation/widgets/amc_async_states.dart';
import '../../shared/providers/auth_state_provider.dart';
import '../theme/web_tokens.dart';
import '../widgets/web_filter_tiles.dart';
import '../widgets/web_side_nav.dart' show WebSideNav;
import '../widgets/web_table.dart';

enum _TypeFilter {
  all('All'),
  cAmc('C-AMC'),
  ncAmc('NC-AMC'),
  nonAmc('Non AMC'),
  regular('Regular');

  const _TypeFilter(this.label);
  final String label;

  IconData get icon => switch (this) {
        _TypeFilter.all => Icons.apartment_rounded,
        _TypeFilter.cAmc => Icons.verified_outlined,
        _TypeFilter.ncAmc => Icons.handshake_outlined,
        _TypeFilter.nonAmc => Icons.build_circle_outlined,
        _TypeFilter.regular => Icons.storefront_outlined,
      };

  Color get color => switch (this) {
        _TypeFilter.all => const Color(0xFF106220),
        _TypeFilter.cAmc => const Color(0xFF2E5AAC),
        _TypeFilter.ncAmc => const Color(0xFF0F766E),
        _TypeFilter.nonAmc => const Color(0xFFB7791F),
        _TypeFilter.regular => const Color(0xFF7B4FB0),
      };

  bool matches(Company c) => switch (this) {
        _TypeFilter.all => true,
        _TypeFilter.cAmc => c.isAmc && c.amcType == AmcType.cAmc,
        _TypeFilter.ncAmc => c.isAmc && c.amcType == AmcType.ncAmc,
        _TypeFilter.nonAmc => c.serviceType == CompanyServiceType.nonAmc,
        _TypeFilter.regular => c.serviceType == CompanyServiceType.regular,
      };
}

/// Web layout of the Companies list: same search, service-type filters,
/// card fields and actions as the mobile screen, laid out as a desktop
/// toolbar + card grid. The page title comes from the web frame's top bar.
class WebCompaniesScreen extends ConsumerStatefulWidget {
  const WebCompaniesScreen({super.key});

  @override
  ConsumerState<WebCompaniesScreen> createState() => _WebCompaniesScreenState();
}

class _WebCompaniesScreenState extends ConsumerState<WebCompaniesScreen> {
  static const Color _green = Color(0xFF106220);
  static const Color _danger = Color(0xFFD32F2F);

  _TypeFilter _typeFilter = _TypeFilter.all;

  List<Company> _visible(List<Company> companies) =>
      companies.where(_typeFilter.matches).toList();

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companiesProvider);
    final canManage =
        Permissions.canManageAmcs(ref.watch(currentUserRoleProvider));

    final Widget body = companiesAsync.when(
      skipLoadingOnRefresh: true,
      loading: () => const SizedBox(height: 320, child: AmcLoadingState()),
      error: (e, _) => SizedBox(
        height: 320,
        child: AmcErrorState(
          error: e,
          onRetry: () => ref.invalidate(companiesProvider),
        ),
      ),
      data: (companies) {
        final visible = _visible(companies);
        if (visible.isEmpty) {
          return _StateBox(
            child: AmcEmptyState(
              message: companies.isEmpty
                  ? canManage
                      ? 'No companies yet'
                      : 'No companies are linked to your account. Ask your administrator to link your user to the company.'
                  : 'No companies found',
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, c) => c.maxWidth >= 900
              ? _table(visible, canManage)
              : _grid(visible, canManage),
        );
      },
    );
    final all = companiesAsync.valueOrNull ?? const <Company>[];

    return Scaffold(
      backgroundColor: WebTokens.cream,
      body: RefreshIndicator(
        color: _green,
        onRefresh: () => ref.refresh(companiesProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _toolbar(all),
                  const SizedBox(height: 18),
                  body,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolbar(List<Company> all) {
    return WebFilterTiles(
      options: [
        for (final type in _TypeFilter.values)
          WebFilterOption(
            label: type.label,
            icon: type.icon,
            color: type.color,
            count: all.isEmpty ? null : all.where(type.matches).length,
            selected: _typeFilter == type,
            onTap: () => setState(() => _typeFilter = type),
          ),
      ],
    );
  }

  Widget _table(List<Company> companies, bool canManage) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebTokens.line),
        boxShadow: WebTokens.softShadow,
      ),
      child: WebTable(
        columns: [
          const WebColumn('Company', flex: 5),
          const WebColumn('GST', flex: 3),
          const WebColumn('Service', flex: 3),
          const WebColumn('POC', flex: 3),
          const WebColumn('Company Email', flex: 4),
          const WebColumn('Contract', flex: 3),
          const WebColumn('Status', flex: 2),
          if (canManage) const WebColumn('', flex: 1),
        ],
        onRowTap: (i) => _openCompany(companies[i]),
        rows: [
          for (final c in companies)
            [
              _CompanyCell(company: c),
              WebCellText(c.gstNumber ?? ''),
              _ServiceCell(label: c.serviceLabel),
              WebCellText(
                c.poc?.name ?? '',
                subtitle: [
                  c.poc?.phone,
                  c.pocEmail,
                ]
                    .whereType<String>()
                    .where((value) => value.isNotEmpty)
                    .join(' · '),
              ),
              WebCellText(c.email),
              _contractCell(c),
              WebCellPill(
                c.isActive ? 'Active' : 'Inactive',
                c.isActive ? const Color(0xFF125420) : const Color(0xFF8A8A8A),
              ),
              if (canManage)
                Align(
                  alignment: Alignment.centerRight,
                  child: _RowMenuButton(
                    onTap: (at) => _showCompanyMenu(c, at),
                  ),
                ),
            ],
        ],
      ),
    );
  }

  Widget _contractCell(Company c) {
    final start = c.amcStartDay;
    final end = c.amcEndDay;
    if (!c.isAmc || (start == null && end == null)) {
      return const WebCellText('—');
    }
    return WebCellText(
      end != null ? longDate(end) : '—',
      subtitle: start != null ? 'From ${displayDate(start)}' : null,
    );
  }

  Widget _grid(List<Company> companies, bool canManage) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 18.0;
        final viewportWidth = MediaQuery.sizeOf(context).width;
        final width = c.hasBoundedWidth
            ? c.maxWidth
            : (viewportWidth - WebSideNav.widthFor(viewportWidth) - 56)
                .clamp(0.0, viewportWidth)
                .toDouble();
        final cols = width >= 1150
            ? 3
            : width >= 720
                ? 2
                : 1;
        final w = (width - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final company in companies)
              SizedBox(
                width: w,
                child: _WebCompanyCard(
                  company: company,
                  onTap: () => _openCompany(company),
                  onMenu:
                      canManage ? (at) => _showCompanyMenu(company, at) : null,
                ),
              ),
          ],
        );
      },
    );
  }

  void _openCompany(Company company) {
    final place = company.branchName.isNotEmpty
        ? company.branchName
        : (company.location ?? '');
    context.push(
      '${Routes.companyDetails}/${company.id}',
      extra: {
        'companyName': company.name,
        'location': place,
        'imageUrl': mediaUrl(company.logo),
      },
    );
  }

  Future<void> _showCompanyMenu(Company company, Offset at) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final size = overlay.size;
    final position = RelativeRect.fromLTRB(
      (at.dx - 200).clamp(8.0, size.width - 8),
      at.dy + 8,
      size.width - at.dx,
      size.height - at.dy,
    );

    final choice = await showMenu<String>(
      context: context,
      position: position,
      color: Colors.white,
      elevation: 10,
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 240),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: [
        _menuItem('edit', Icons.edit_outlined, 'Edit Company'),
        if (company.isActive)
          _menuItem('inactive', Icons.block, 'Mark Inactive', danger: true)
        else
          _menuItem('active', Icons.check_circle_outline, 'Mark Active'),
      ],
    );

    if (choice == null || !mounted) return;
    switch (choice) {
      case 'edit':
        await context.push<Object?>(
          Routes.createAmc,
          extra: <String, dynamic>{'companyId': company.id, 'company': company},
        );
      case 'inactive':
        _confirmStatusChange(company, activate: false);
      case 'active':
        _confirmStatusChange(company, activate: true);
    }
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    bool danger = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 44,
      child: Row(
        children: [
          Icon(icon, size: 18, color: danger ? _danger : _green),
          const SizedBox(width: 12),
          Text(
            label,
            style: WebTokens.bodyText(
              14,
              color: danger ? _danger : WebTokens.ink,
              weight: FontWeight.w600,
              h: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmStatusChange(
    Company company, {
    required bool activate,
  }) async {
    final accent = activate ? _green : _danger;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogCtx) => _StatusDialog(
        activate: activate,
        accent: accent,
        companyName: company.displayName,
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(amcRepositoryProvider)
          .setCompanyActive(company.id, isActive: activate);
      ref.invalidate(companiesProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            activate
                ? '${company.name} marked active'
                : '${company.name} marked inactive',
          ),
          backgroundColor: accent,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: _danger),
      );
    }
  }
}

class _CompanyCell extends StatelessWidget {
  const _CompanyCell({required this.company});
  final Company company;

  @override
  Widget build(BuildContext context) {
    final place = [company.branchName, company.location]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .join(' · ');
    return Row(
      children: [
        CompanyLogo(
          url: mediaUrl(company.logo),
          width: 40,
          height: 40,
          radius: 10,
        ),
        const SizedBox(width: 12),
        Expanded(child: WebCellText(company.name, bold: true, subtitle: place)),
      ],
    );
  }
}

/// Service type as wrapping chips ("AMC · C AMC" -> [AMC] [C AMC]) so the
/// full label stays visible in a narrow column.
class _ServiceCell extends StatelessWidget {
  const _ServiceCell({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const WebCellText('—');
    final parts = label.split(' · ');
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        for (var i = 0; i < parts.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: i == 0 ? WebTokens.mintSoft : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: i == 0 ? WebTokens.mint : WebTokens.line,
              ),
            ),
            child: Text(
              parts[i],
              style: WebTokens.bodyText(
                11.5,
                color: i == 0 ? WebTokens.green : WebTokens.ink,
                weight: FontWeight.w700,
                h: 1.2,
              ),
            ),
          ),
      ],
    );
  }
}

class _RowMenuButton extends StatelessWidget {
  const _RowMenuButton({required this.onTap});
  final void Function(Offset at) onTap;

  @override
  Widget build(BuildContext context) {
    Offset tapPos = Offset.zero;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => tapPos = d.globalPosition,
        onTap: () => onTap(tapPos),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.more_vert, color: Colors.black54, size: 20),
        ),
      ),
    );
  }
}

class _StateBox extends StatelessWidget {
  const _StateBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebTokens.line),
      ),
      child: child,
    );
  }
}

/// Desktop company card: same fields, labels and menu as the mobile
/// Companies card, arranged for a grid.
class _WebCompanyCard extends StatefulWidget {
  const _WebCompanyCard({
    required this.company,
    required this.onTap,
    this.onMenu,
  });

  final Company company;
  final VoidCallback onTap;
  final void Function(Offset at)? onMenu;

  @override
  State<_WebCompanyCard> createState() => _WebCompanyCardState();
}

class _WebCompanyCardState extends State<_WebCompanyCard> {
  static const Color _green = Color(0xFF106220);
  static const Color _darkGreen = Color(0xFF125420);
  static const Color _inactive = Color(0xFF8A8A8A);

  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.company;
    final place = [c.branchName, c.location]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .join(' · ');
    final start = c.amcStartDay;
    final end = c.amcEndDay;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hover ? _green.withValues(alpha: 0.35) : WebTokens.line,
            ),
            boxShadow: _hover ? WebTokens.cardShadow : WebTokens.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CompanyLogo(
                      url: mediaUrl(c.logo),
                      width: 72,
                      height: 72,
                      radius: 14,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: WebTokens.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: _darkGreen,
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  place.isEmpty ? '—' : place,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: WebTokens.fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _darkGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _statusPill(c.isActive),
                        ],
                      ),
                    ),
                    if (widget.onMenu != null) _menuButton(),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _infoRow(Icons.person_outline, 'POC', c.poc?.name ?? ''),
                    const SizedBox(height: 7),
                    _infoRow(
                      Icons.email_outlined,
                      'Company email',
                      c.email,
                    ),
                    const SizedBox(height: 7),
                    _infoRow(
                      Icons.badge_outlined,
                      'GST',
                      c.gstNumber ?? '',
                    ),
                    const SizedBox(height: 7),
                    _infoRow(
                      Icons.alternate_email,
                      'POC email',
                      c.pocEmail ?? '',
                    ),
                    const SizedBox(height: 7),
                    _infoRow(
                      Icons.phone_outlined,
                      'Mobile',
                      c.poc?.phone ?? '',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFEBF0EA),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _date(
                        'Start',
                        c.isAmc && start != null ? displayDate(start) : '—',
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _date(
                          'End',
                          c.isAmc && end != null ? longDate(end) : '—',
                        ),
                      ),
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

  Widget _menuButton() {
    Offset tapPos = Offset.zero;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => tapPos = d.globalPosition,
      onTap: () => widget.onMenu!(tapPos),
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.more_vert, color: Colors.black54, size: 20),
      ),
    );
  }

  Widget _statusPill(bool active) {
    final color = active ? _darkGreen : _inactive;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEBF0EA) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(48),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            active ? 'Active' : 'Inactive',
            style: TextStyle(
              fontFamily: WebTokens.fontFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.black.withValues(alpha: 0.4), size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: const TextStyle(
                fontFamily: WebTokens.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(
                  text: '$label : ',
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
                ),
                TextSpan(
                  text: value.isEmpty ? '—' : value,
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _date(String label, String value) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(
          fontFamily: WebTokens.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(
            text: '$label : ',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.45)),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }
}

class _StatusDialog extends StatelessWidget {
  const _StatusDialog({
    required this.activate,
    required this.accent,
    required this.companyName,
  });

  final bool activate;
  final Color accent;
  final String companyName;

  @override
  Widget build(BuildContext context) {
    final title = activate ? 'Activate company?' : 'Mark company inactive?';
    final body = activate
        ? 'Set "$companyName" back to Active?'
        : 'Set "$companyName" to Inactive? It will be marked as not currently serviced.';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 26, 26, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  activate ? Icons.check_circle_outline : Icons.block,
                  color: accent,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: WebTokens.heading(18)),
              const SizedBox(height: 8),
              Text(body, style: WebTokens.bodyText(14)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Cancel',
                      style: WebTokens.bodyText(
                        14,
                        color: WebTokens.body,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: WebTokens.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(activate ? 'Activate' : 'Mark Inactive'),
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
