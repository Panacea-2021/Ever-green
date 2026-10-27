import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../data/equipment_provider.dart';

class CompanyEquipmentsScreen extends ConsumerStatefulWidget {
  final String companyId;
  final String? companyName;

  const CompanyEquipmentsScreen({
    super.key,
    required this.companyId,
    this.companyName,
  });

  @override
  ConsumerState<CompanyEquipmentsScreen> createState() =>
      _CompanyEquipmentsScreenState();
}

class _CompanyEquipmentsScreenState
    extends ConsumerState<CompanyEquipmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  final Set<int> _busy = {};

  static const Color _green = Color(0xFF125420);
  static const Color _addGreen = Color(0xFF106220);
  static const Color _footerBg = Color(0xFFEBF0EA);
  static const Color _red = Color(0xFFD32F2F);

  int? get _companyId => int.tryParse(widget.companyId);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canManage = canManageEquipment(ref.watch(currentUserRoleProvider));
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Faint background image
            Positioned.fill(
              child: Image.asset(
                'assets/images/home_bg.png',
                fit: BoxFit.cover,
                color: Colors.white.withValues(alpha: 0.7),
                colorBlendMode: BlendMode.srcOver,
                errorBuilder: (_, __, ___) => Container(color: Colors.white),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(context, canManage),
                  _buildSearchBar(),
                  Expanded(child: _buildBody(canManage)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool canManage) {
    final companyId = _companyId;
    if (companyId == null) {
      return _message('Unknown company', 'This company could not be found.');
    }
    final async = ref.watch(equipmentsProvider(companyId));
    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: _addGreen),
      ),
      error: (e, _) => _message(
        'Could not load equipment',
        '$e',
        onRetry: () => ref.invalidate(equipmentsProvider(companyId)),
      ),
      data: (items) {
        final q = _query.toLowerCase();
        final filtered = q.isEmpty
            ? items
            : items.where((e) {
                return [
                  e.name,
                  e.make,
                  e.model,
                  e.serialNumber,
                  e.egSerialNumber,
                ].whereType<String>().any((v) => v.toLowerCase().contains(q));
              }).toList();
        return RefreshIndicator(
          color: _addGreen,
          onRefresh: () => ref.refresh(equipmentsProvider(companyId).future),
          child: filtered.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 80),
                    _message(
                      items.isEmpty ? 'No equipment yet' : 'No matches',
                      items.isEmpty
                          ? 'Equipment added to this company will show here.'
                          : 'Try a different search.',
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(17, 0, 17, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _buildEquipmentCard(filtered[index], canManage),
                ),
        );
      },
    );
  }

  Widget _message(String title, String subtitle, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.kitchen_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B6B6B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                color: Color(0xFF9B9B9B),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _addGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontFamily: 'Montserrat', color: _addGreen),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, bool canManage) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.black,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Equipments',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.6,
            ),
          ),
          const Spacer(),
          // Add button (outlined pill with green text + filled circle)
          if (canManage && _companyId != null)
            GestureDetector(
              onTap: () {
                context.push(
                  '${Routes.addEquipment}/${widget.companyId}',
                  extra: {'companyName': widget.companyName},
                );
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _addGreen, width: 1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Add',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _addGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: _addGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Search bar
  // ---------------------------------------------------------------------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v.trim()),
          cursorColor: _addGreen,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            hintText: 'Search Equipments',
            hintStyle: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.2),
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 24,
              color: Colors.black.withValues(alpha: 0.4),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: const BorderSide(color: _addGreen, width: 1.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------
  void _openDetails(Equipment equipment) {
    context.push(
      '${Routes.equipmentDetails}/${equipment.id}',
      extra: {
        'equipmentName': equipment.name,
        'location': equipment.location,
        'imageUrl': equipment.imageUrl,
        'make': equipment.make,
        'model': equipment.model,
        'serialNumber': equipment.serialNumber,
        'companyId': widget.companyId,
        'companyName': widget.companyName,
      },
    );
  }

  Future<void> _toggleActive(Equipment equipment) async {
    final activate = !equipment.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(activate ? 'Activate equipment?' : 'Deactivate equipment?'),
        content: Text(
          activate
              ? '${equipment.name} will be marked active again.'
              : '${equipment.name} will be marked inactive. You can activate it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              activate ? 'Activate' : 'Deactivate',
              style: TextStyle(color: activate ? _addGreen : _red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy.add(equipment.id));
    try {
      await ref.read(equipmentApiProvider).setActive(equipment.id, activate);
      ref.invalidate(equipmentsProvider);
      ref.invalidate(equipmentInfoProvider);
      _snack(activate ? 'Equipment marked active' : 'Equipment marked inactive');
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(equipment.id));
    }
  }

  void _snack(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red.shade400 : _addGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Equipment card
  // ---------------------------------------------------------------------------
  Widget _buildEquipmentCard(Equipment equipment, bool canManage) {
    final active = equipment.isActive;
    final image = mediaUrl(equipment.imageUrl);
    Widget placeholder() => Container(
          width: 108,
          height: 135,
          decoration: BoxDecoration(
            color: const Color(0xFFE8D4C4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.kitchen, size: 40, color: Colors.brown.shade300),
        );

    return GestureDetector(
      onTap: () => _openDetails(equipment),
      child: Container(
        height: 221,
        margin: const EdgeInsets.only(bottom: 17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFE0D9EE),
              blurRadius: 32,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Equipment image - left
            Positioned(
              left: 15,
              top: 19,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: image.isEmpty
                    ? placeholder()
                    : Image.network(
                        image,
                        width: 108,
                        height: 135,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => placeholder(),
                      ),
              ),
            ),

            // Equipment name
            Positioned(
              left: 138,
              right: 44,
              top: 16,
              child: Text(
                equipment.name,
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

            // More options
            Positioned(
              right: 23,
              top: 20,
              child: _busy.contains(equipment.id)
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _addGreen,
                      ),
                    )
                  : PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      onSelected: (v) {
                        switch (v) {
                          case 'details':
                            _openDetails(equipment);
                          case 'qr':
                            context.push(
                              '${Routes.equipmentQr}/${equipment.id}',
                              extra: {
                                'equipmentName': equipment.name,
                                'serialNumber': equipment.egSerialNumber,
                              },
                            );
                          case 'toggle':
                            _toggleActive(equipment);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'details',
                          child: Text('View details'),
                        ),
                        const PopupMenuItem(value: 'qr', child: Text('QR code')),
                        if (canManage)
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(active ? 'Deactivate' : 'Activate'),
                          ),
                      ],
                      child: const Icon(
                        Icons.more_vert,
                        color: Colors.black54,
                        size: 16,
                      ),
                    ),
            ),

            // Active badge
            Positioned(
              left: 138,
              top: 44,
              child: Container(
                height: 25,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: _footerBg,
                  borderRadius: BorderRadius.circular(48),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      active ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Make row
            Positioned(
              left: 138,
              right: 12,
              top: 79,
              child: _infoRow(
                Icons.handyman_outlined,
                'Make',
                equipment.make ?? '-',
              ),
            ),

            // Model row
            Positioned(
              left: 138,
              right: 12,
              top: 108,
              child: _infoRow(
                Icons.devices_other_outlined,
                'Model',
                equipment.model ?? '-',
              ),
            ),

            // S.No row
            Positioned(
              left: 137,
              right: 12,
              top: 137,
              child: _infoRow(
                Icons.tag,
                'S.No',
                equipment.serialNumber ?? equipment.egSerialNumber,
              ),
            ),

            // Footer - Maintenance Frequency
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 52,
                decoration: const BoxDecoration(
                  color: _footerBg,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 19),
                  child: Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.42,
                          ),
                          children: [
                            TextSpan(
                              text: 'Maintainance Frequency ',
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.4),
                              ),
                            ),
                            TextSpan(
                              text: ':  ${equipment.tmFrequency?.label ?? '-'}',
                              style: const TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.black54, size: 14),
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
                  text: '$label ',
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
                ),
                TextSpan(
                  text: ': $value',
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
