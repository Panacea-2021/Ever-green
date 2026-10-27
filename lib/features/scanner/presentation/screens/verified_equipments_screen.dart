import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/router/routes.dart';
import '../../../amcs/data/equipment_provider.dart';

class VerifiedEquipmentsScreen extends ConsumerStatefulWidget {
  const VerifiedEquipmentsScreen({super.key});

  @override
  ConsumerState<VerifiedEquipmentsScreen> createState() =>
      _VerifiedEquipmentsScreenState();
}

class _VerifiedEquipmentsScreenState
    extends ConsumerState<VerifiedEquipmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  /// Rows from `getVerifiedEquipments`, refreshed on every build.
  List<VerifiedEquipment> _verifiedEquipments = const [];

  List<VerifiedEquipment> get _filteredEquipments {
    var filtered = _verifiedEquipments;

    // Filter by status
    if (_selectedFilter != 'All') {
      filtered = filtered.where((e) {
        switch (_selectedFilter) {
          case 'Verified':
            return e.status == VerificationStatus.verified;
          case 'Needs Attention':
            return e.status == VerificationStatus.needsAttention;
          case 'Failed':
            return e.status == VerificationStatus.failed;
          default:
            return true;
        }
      }).toList();
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((e) {
        return e.name.toLowerCase().contains(query) ||
            e.serialNumber.toLowerCase().contains(query) ||
            e.location.toLowerCase().contains(query) ||
            e.companyName.toLowerCase().contains(query) ||
            e.verifiedBy.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  int get _verifiedCount => _verifiedEquipments
      .where((e) => e.status == VerificationStatus.verified)
      .length;

  int get _needsAttentionCount => _verifiedEquipments
      .where((e) => e.status == VerificationStatus.needsAttention)
      .length;

  int get _failedCount => _verifiedEquipments
      .where((e) => e.status == VerificationStatus.failed)
      .length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(verifiedEquipmentsProvider);
    _verifiedEquipments = (async.valueOrNull ?? const <Equipment>[])
        .map(VerifiedEquipment.fromEquipment)
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Status Summary Cards
            _buildStatusSummary(),

            // Search Bar
            _buildSearchBar(),

            // Filter Chips
            _buildFilterChips(),

            // Equipment List
            Expanded(
              child: async.isLoading && !async.hasValue
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF106220),
                      ),
                    )
                  : async.hasError && !async.hasValue
                      ? _buildErrorState('${async.error}')
                      : RefreshIndicator(
                          color: const Color(0xFF106220),
                          onRefresh: () =>
                              ref.refresh(verifiedEquipmentsProvider.future),
                          child: _filteredEquipments.isEmpty
                              ? LayoutBuilder(
                                  builder: (context, constraints) =>
                                      SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: SizedBox(
                                      height: constraints.maxHeight,
                                      child: _buildEmptyState(),
                                    ),
                                  ),
                                )
                              : _buildEquipmentList(),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(Routes.scanner);
        },
        backgroundColor: const Color(0xFF106220),
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text(
          'Scan QR',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => context.pop(),
            child:
                const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
          ),

          const SizedBox(width: 16),

          // Title
          const Expanded(
            child: Text(
              'Verified Equipments',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),

          // Notification Button
          GestureDetector(
            onTap: () {
              context.push(Routes.notifications);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: Colors.grey.shade700,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummary() {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatusCard(
            icon: Icons.verified,
            iconBgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF4CAF50),
            count: _verifiedCount,
            label: 'Verified',
          ),
          const SizedBox(width: 12),
          _buildStatusCard(
            icon: Icons.warning_amber_outlined,
            iconBgColor: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFFF9800),
            count: _needsAttentionCount,
            label: 'Needs Attention',
          ),
          const SizedBox(width: 12),
          _buildStatusCard(
            icon: Icons.error_outline,
            iconBgColor: const Color(0xFFFFEBEE),
            iconColor: const Color(0xFFE53935),
            count: _failedCount,
            label: 'Failed',
          ),
          const SizedBox(width: 12),
          _buildStatusCard(
            icon: Icons.inventory_2_outlined,
            iconBgColor: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF2196F3),
            count: _verifiedEquipments.length,
            label: 'Total',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required int count,
    required String label,
  }) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration:
                    BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search equipment...',
            hintStyle: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade500,
            ),
            prefixIcon:
                Icon(Icons.search, color: Colors.grey.shade500, size: 22),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Verified', 'Needs Attention', 'Failed'];

    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF106220) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF106220)
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEquipmentList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _filteredEquipments.length,
      itemBuilder: (context, index) {
        return _buildEquipmentCard(_filteredEquipments[index]);
      },
    );
  }

  Widget _buildEquipmentCard(VerifiedEquipment equipment) {
    return GestureDetector(
      onTap: () {
        context.push(
          '${Routes.equipmentDetails}/${equipment.id}',
          extra: {
            'equipmentName': equipment.name,
            'location': equipment.location,
            'imageUrl': equipment.imageUrl,
            'serialNumber': equipment.serialNumber,
            'companyId': equipment.companyId,
            'companyName': equipment.companyName,
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Equipment Image
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: equipment.imageUrl.isEmpty
                            ? _imagePlaceholder()
                            : Image.network(
                                equipment.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _imagePlaceholder();
                                },
                              ),
                      ),
                      // Status indicator
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: equipment.status.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            equipment.status.icon,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // Equipment Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Arrow
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                equipment.name,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_right,
                                color: Colors.black54,
                                size: 18,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Serial Number and Status Badge
                        Row(
                          children: [
                            const Icon(
                              Icons.qr_code,
                              color: Color(0xFF106220),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              equipment.serialNumber,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF106220),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(equipment.status),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Location
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: Colors.grey.shade500,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                equipment.location,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Company
                        Row(
                          children: [
                            Icon(
                              Icons.business_outlined,
                              color: Colors.grey.shade500,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                equipment.companyName,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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

            // Verification Info Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Verified By
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF106220).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF106220),
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Verified by ',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        equipment.verifiedBy,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  // Verification Time
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.grey.shade500,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(equipment.verifiedAt),
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
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

  Widget _imagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.kitchen,
        size: 32,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(verifiedEquipmentsProvider),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Color(0xFF106220),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(VerificationStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: status.color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration:
                BoxDecoration(color: status.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Color(0xFF106220),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Equipment Found',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan a QR code to verify equipment',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.push(Routes.scanner);
            },
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            label: const Text(
              'Scan QR Code',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF106220),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

// Verification Status Enum
enum VerificationStatus { verified, needsAttention, failed }

extension VerificationStatusExtension on VerificationStatus {
  Color get color {
    switch (this) {
      case VerificationStatus.verified:
        return const Color(0xFF4CAF50);
      case VerificationStatus.needsAttention:
        return const Color(0xFFFF9800);
      case VerificationStatus.failed:
        return const Color(0xFFE53935);
    }
  }

  IconData get icon {
    switch (this) {
      case VerificationStatus.verified:
        return Icons.check;
      case VerificationStatus.needsAttention:
        return Icons.warning_amber;
      case VerificationStatus.failed:
        return Icons.close;
    }
  }

  String get label {
    switch (this) {
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.needsAttention:
        return 'Attention';
      case VerificationStatus.failed:
        return 'Failed';
    }
  }
}

// Verified Equipment Model
class VerifiedEquipment {
  final String id;
  final String name;
  final String serialNumber;
  final String location;
  final DateTime verifiedAt;
  final String verifiedBy;
  final VerificationStatus status;
  final String companyName;
  final String imageUrl;
  final String? companyId;

  VerifiedEquipment({
    required this.id,
    required this.name,
    required this.serialNumber,
    required this.location,
    required this.verifiedAt,
    required this.verifiedBy,
    required this.status,
    required this.companyName,
    required this.imageUrl,
    this.companyId,
  });

  /// The verification outcome follows the equipment's condition: operational
  /// is verified, under maintenance needs attention, faulty/retired failed.
  factory VerifiedEquipment.fromEquipment(Equipment e) {
    final status = switch (e.status) {
      EquipmentCondition.operational => VerificationStatus.verified,
      EquipmentCondition.underMaintenance => VerificationStatus.needsAttention,
      EquipmentCondition.faulty ||
      EquipmentCondition.retired =>
        VerificationStatus.failed,
    };
    final companyId = e.companyId ?? e.company?.id;
    return VerifiedEquipment(
      id: '${e.id}',
      name: e.name,
      serialNumber: e.egSerialNumber.isNotEmpty
          ? e.egSerialNumber
          : (e.serialNumber ?? ''),
      location: e.location ?? e.company?.location ?? '',
      verifiedAt: e.verifiedAt ?? DateTime.now(),
      verifiedBy: e.verifier?.name ?? '',
      status: status,
      companyName: e.company?.displayName ?? '',
      imageUrl: mediaUrl(e.imageUrl),
      companyId: companyId?.toString(),
    );
  }
}
