import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/scaffold_with_bottom_nav.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/custom_menu_icon.dart';
import '../../data/amc_provider.dart';
import '../../domain/models/amc_contract.dart';
import '../widgets/amc_async_states.dart';

/// Service-type filter chips: label -> predicate.
enum _TypeFilter {
  all('All'),
  cAmc('C-AMC'),
  ncAmc('NC-AMC'),
  nonAmc('Non AMC'),
  regular('Regular');

  const _TypeFilter(this.label);
  final String label;

  bool matches(Company c) => switch (this) {
        _TypeFilter.all => true,
        _TypeFilter.cAmc => c.isAmc && c.amcType == AmcType.cAmc,
        _TypeFilter.ncAmc => c.isAmc && c.amcType == AmcType.ncAmc,
        _TypeFilter.nonAmc => c.serviceType == CompanyServiceType.nonAmc,
        _TypeFilter.regular => c.serviceType == CompanyServiceType.regular,
      };
}

class AmcsScreen extends ConsumerStatefulWidget {
  const AmcsScreen({super.key});

  @override
  ConsumerState<AmcsScreen> createState() => _AmcsScreenState();
}

class _AmcsScreenState extends ConsumerState<AmcsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _TypeFilter _serviceTypeFilter = _TypeFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Company> _visible(List<Company> companies) {
    final q = _searchQuery.trim().toLowerCase();
    return companies.where((c) {
      if (!_serviceTypeFilter.matches(c)) return false;
      if (q.isEmpty) return true;
      return [
        c.name,
        c.branchName,
        c.location ?? '',
        c.email,
        c.poc?.name ?? '',
        c.poc?.phone ?? '',
        c.pocEmail ?? '',
        c.serviceLabel,
      ].any((v) => v.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companiesProvider);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        drawer: const AppDrawer(),
        body: Stack(
          children: [
            // Background image - separate layer
            Positioned.fill(
              child: Image.asset(
                'assets/images/home_bg.png',
                fit: BoxFit.cover,
                color: Colors.white.withValues(alpha: 0.7),
                colorBlendMode: BlendMode.srcOver,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.white);
                },
              ),
            ),
            // Main content
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Header
                  _buildHeader(context),

                  // Search Bar
                  _buildSearchBar(),

                  // Service-type filter chips (C AMC / NC AMC / Non-AMC / Regular)
                  _buildTypeFilter(),

                  const SizedBox(height: 12),

                  // Company Cards List — filtered by search + service type
                  Expanded(
                    child: companiesAsync.when(
                      skipLoadingOnRefresh: true,
                      loading: () => const AmcLoadingState(),
                      error: (e, _) => AmcErrorState(
                        error: e,
                        onRetry: () => ref.invalidate(companiesProvider),
                      ),
                      data: (companies) {
                        final visible = _visible(companies);
                        return RefreshIndicator(
                          color: _green,
                          onRefresh: () =>
                              ref.refresh(companiesProvider.future),
                          child: visible.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height: 260,
                                      child: AmcEmptyState(
                                        message: companies.isEmpty
                                            ? 'No companies yet'
                                            : 'No companies found',
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.fromLTRB(
                                    17,
                                    0,
                                    17,
                                    ScaffoldWithBottomNav.bottomInset(context),
                                  ),
                                  itemCount: visible.length,
                                  itemBuilder: (context, index) {
                                    return _buildCompanyCard(visible[index]);
                                  },
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  Company card 3-dots menu
  // ---------------------------------------------------------------------------

  static const Color _green = Color(0xFF106220);
  static const Color _danger = Color(0xFFD32F2F);

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        _companyPopupItem('edit', Icons.edit_outlined, 'Edit Company'),
        if (company.isActive)
          _companyPopupItem(
            'inactive',
            Icons.block,
            'Mark Inactive',
            danger: true,
          )
        else
          _companyPopupItem(
            'active',
            Icons.check_circle_outline,
            'Mark Active',
          ),
      ],
    );

    if (choice == null || !mounted) return;
    switch (choice) {
      case 'edit':
        _editCompany(company);
      case 'inactive':
        _confirmStatusChange(company, activate: false);
      case 'active':
        _confirmStatusChange(company, activate: true);
    }
  }

  PopupMenuItem<String> _companyPopupItem(
    String value,
    IconData icon,
    String label, {
    bool danger = false,
  }) {
    final color = danger ? _danger : const Color(0xFF1F1F1F);
    return PopupMenuItem<String>(
      value: value,
      height: 46,
      child: Row(
        children: [
          Icon(icon, size: 19, color: danger ? _danger : _green),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editCompany(Company company) async {
    await context.push<Object?>(
      Routes.createAmc,
      extra: <String, dynamic>{'companyId': company.id, 'company': company},
    );
  }

  Future<void> _confirmStatusChange(
    Company company, {
    required bool activate,
  }) async {
    final accent = activate ? _green : _danger;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'status',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
      pageBuilder: (dialogCtx, _, __) {
        return _StatusConfirmDialog(
          activate: activate,
          accent: accent,
          companyName: company.displayName,
          reduceMotion: reduceMotion,
        );
      },
      transitionBuilder: (dialogCtx, anim, _, child) {
        if (reduceMotion) return child;
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Menu Icon
          Builder(
            builder: (context) => CustomMenuIcon(
              onTap: () => Scaffold.of(context).openDrawer(),
            ),
          ),

          // Title
          const Text(
            'Companies',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.6,
            ),
          ),

          // Right Icons
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push(Routes.scanner),
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
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push(Routes.notifications),
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    const types = _TypeFilter.values;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final type = types[i];
          final sel = _serviceTypeFilter == type;
          return GestureDetector(
            onTap: () => setState(() => _serviceTypeFilter = type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? _green : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: sel ? _green : const Color(0xFFE0E0E0),
                  width: 1.2,
                ),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: _green.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                type.label,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : const Color(0xFF1F1F1F),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        cursorColor: const Color(0xFF2E7D32),
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          hintText: 'Search Companies',
          hintStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black.withValues(alpha: 0.25),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.black.withValues(alpha: 0.3),
            size: 24,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: const BorderSide(
              color: Color(0xFF2E7D32),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: const BorderSide(
              color: Color(0xFF2E7D32),
              width: 1.5,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: const BorderSide(
              color: Color(0xFF2E7D32),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {double size = 14,}) {
    return Row(
      children: [
        Icon(icon, color: Colors.black54, size: size),
        const SizedBox(width: 7),
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.36,
              ),
              children: [
                TextSpan(
                  text: label,
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
                ),
                TextSpan(
                  text: ' : ${value.isEmpty ? '—' : value}',
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _footerDate(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.42,
        ),
        children: [
          TextSpan(
            text: label,
            style: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
          ),
          TextSpan(
            text: ': $value',
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(Company company) {
    final place = company.branchName.isNotEmpty
        ? company.branchName
        : (company.location ?? '');
    final start = company.amcStartDay;
    final end = company.amcEndDay;
    final canManage =
        Permissions.canManageAmcs(ref.watch(currentUserRoleProvider));

    return GestureDetector(
      onTap: () {
        context.push(
          '${Routes.companyDetails}/${company.id}',
          extra: {
            'companyName': company.name,
            'location': place,
            'imageUrl': mediaUrl(company.logo),
          },
        );
      },
      child: Container(
        height: 221,
        margin: const EdgeInsets.only(bottom: 17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFE0D9EE), // Purple shadow from Figma
              blurRadius: 32,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Company logo - left side
            Positioned(
              left: 15,
              top: 19,
              child: CompanyLogo(
                url: mediaUrl(company.logo),
                width: 108,
                height: 135,
              ),
            ),

            // Company Name
            Positioned(
              left: 138,
              top: 16,
              right: canManage ? 44 : 16,
              child: Text(
                company.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: -0.51,
                ),
              ),
            ),

            // More options button (admin roles only)
            if (canManage)
              Positioned(
                right: 12,
                top: 10,
                child: Builder(
                  builder: (_) {
                    Offset tapPos = Offset.zero;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) => tapPos = d.globalPosition,
                      onTap: () => _showCompanyMenu(company, tapPos),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.more_vert,
                          color: Colors.black54,
                          size: 18,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Location icon
            const Positioned(
              left: 136,
              top: 48,
              child: Icon(
                Icons.location_on,
                color: Color(0xFF125420),
                size: 16,
              ),
            ),

            // Location text (kept clear of the badge at left: 242)
            Positioned(
              left: 158,
              top: 47,
              width: 80,
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

            // Active badge
            Positioned(
              left: 242,
              top: 44,
              child: Container(
                width: 70,
                height: 25,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF0EA),
                  borderRadius: BorderRadius.circular(48),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF125420),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      company.isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF125420),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // POC row
            Positioned(
              left: 137,
              top: 79,
              right: 12,
              child: _infoRow(Icons.person, 'POC', company.poc?.name ?? ''),
            ),

            // Email row
            Positioned(
              left: 137,
              top: 108,
              right: 12,
              child: _infoRow(
                Icons.email,
                'Email',
                company.pocEmail ?? company.email,
              ),
            ),

            // Mobile row
            Positioned(
              left: 139,
              top: 138,
              right: 12,
              child: _infoRow(
                Icons.phone,
                'Mobile',
                company.poc?.phone ?? '',
                size: 12,
              ),
            ),

            // Footer with dates (only AMC companies carry contract dates)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFEBF0EA),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 19),
                    _footerDate(
                      'Start ',
                      company.isAmc && start != null
                          ? '${displayDate(start)} '
                          : '— ',
                    ),
                    const Spacer(),
                    _footerDate(
                      'End ',
                      company.isAmc && end != null ? longDate(end) : '—',
                    ),
                    const SizedBox(width: 19),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated confirmation dialog for activating / deactivating a company.
/// Blurred scrim, pop-in icon badge, accent primary button + Cancel.
class _StatusConfirmDialog extends StatelessWidget {
  final bool activate;
  final Color accent;
  final String companyName;
  final bool reduceMotion;

  const _StatusConfirmDialog({
    required this.activate,
    required this.accent,
    required this.companyName,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    final icon = activate ? Icons.check_circle_outline : Icons.block;
    final title = activate ? 'Activate company?' : 'Mark company inactive?';
    final body = activate
        ? 'Set "$companyName" back to Active?'
        : 'Set "$companyName" to Inactive? It will be marked as not currently serviced.';
    final primaryLabel = activate ? 'Activate' : 'Mark Inactive';

    final card = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _iconBadge(icon),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _PrimaryButton(
                    label: primaryLabel,
                    accent: accent,
                    onTap: () => Navigator.pop(context, true),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Blurred scrim behind the dialog.
    return Stack(
      children: [
        if (!reduceMotion)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: const SizedBox.shrink(),
            ),
          ),
        card,
      ],
    );
  }

  Widget _iconBadge(IconData icon) {
    final badge = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: accent, size: 30),
        ),
      ),
    );
    if (reduceMotion) return badge;
    return badge
        .animate(delay: 120.ms)
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          duration: 360.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 200.ms);
  }
}

/// Full-width accent primary button with a soft colored shadow and a quick
/// press-scale, used by [_StatusConfirmDialog].
class _PrimaryButton extends StatefulWidget {
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.accent,
                Color.lerp(widget.accent, Colors.black, 0.12)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
