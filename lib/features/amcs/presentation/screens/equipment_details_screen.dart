import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../qr/data/qr_pdf.dart';
import '../../../scanner/presentation/widgets/foreign_equipment_notice.dart';
import '../../data/equipment_provider.dart';

class EquipmentDetailsScreen extends ConsumerStatefulWidget {
  /// Equipment id (or EG serial / serial number; the backend resolves both).
  final String equipmentId;
  final String? equipmentName;
  final String? location;
  final String? imageUrl;
  final String? make;
  final String? model;
  final String? serialNumber;

  /// The company this equipment belongs to (passed when navigating from the
  /// company's equipment list), used to pre-fill the Add Task form.
  final String? companyId;
  final String? companyName;

  const EquipmentDetailsScreen({
    super.key,
    required this.equipmentId,
    this.equipmentName,
    this.location,
    this.imageUrl,
    this.make,
    this.model,
    this.serialNumber,
    this.companyId,
    this.companyName,
  });

  @override
  ConsumerState<EquipmentDetailsScreen> createState() =>
      _EquipmentDetailsScreenState();
}

class _EquipmentDetailsScreenState
    extends ConsumerState<EquipmentDetailsScreen> {
  static const Color _green = Color(0xFF125420);
  static const Color _greenTitle = Color(0xFF278245);
  static const Color _badgeBg = Color(0xFFEBF0EA);

  bool _downloading = false;
  int? _reportTaskId;

  Future<void> _openEdit(Equipment e) async {
    final companyId = e.companyId?.toString() ?? widget.companyId ?? '';
    await context.push<bool>(
      '${Routes.addEquipment}/$companyId',
      extra: {
        'companyName': e.company?.displayName ?? widget.companyName,
        'editEquipment': <String, dynamic>{
          'id': e.id,
          'companyId': companyId,
          'name': e.name,
          'make': e.make,
          'model': e.model,
          'serialNumber': e.serialNumber,
          'location': e.location,
          'year': e.manufacturerDate?.year.toString(),
          'frequency': e.tmFrequency?.key,
          'description': e.description,
          'imageUrl': e.imageUrl,
          'status': e.status.key,
          'type': e.type,
          'installedAt': e.installedAt?.toIso8601String(),
        },
      },
    );
  }

  void _createTask(Equipment e) {
    final companyId = e.companyId?.toString() ?? widget.companyId;
    if (companyId == null || companyId.isEmpty) return;
    context.push(
      '${Routes.addTask}/$companyId',
      extra: {
        'companyName': e.company?.displayName ?? widget.companyName,
        'preselectEquipment': e.name,
        'preselectEquipmentSpecs': <String, String>{
          'make': e.make ?? '',
          'model': e.model ?? '',
          'serialNumber': e.serialNumber ?? '',
          'mfgYear': e.manufacturerDate?.year.toString() ?? '',
          'maintenanceFrequency': e.tmFrequency?.label ?? '',
          'egSerialNumber': e.egSerialNumber,
          'description': e.description ?? '',
        },
      },
    );
  }

  Future<void> _downloadReport(ServiceTask task) async {
    if (_reportTaskId != null) return;
    setState(() => _reportTaskId = task.id);
    try {
      final bytes =
          await ref.read(equipmentApiProvider).serviceReportPdf(task.id);
      final name = task.ticketNo.isEmpty ? '${task.id}' : task.ticketNo;
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'service_report_${qrFileSlug(name)}.pdf',
      );
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$err'), backgroundColor: Colors.red.shade400),
        );
      }
    } finally {
      if (mounted) setState(() => _reportTaskId = null);
    }
  }

  Future<void> _downloadQr(Equipment e) async {
    setState(() => _downloading = true);
    try {
      await shareQrStickerPdf(
        ref,
        equipmentIds: [e.id],
        filename:
            'qr_${qrFileSlug(e.egSerialNumber.isEmpty ? e.name : e.egSerialNumber)}.pdf',
      );
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$err'), backgroundColor: Colors.red.shade400),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(equipmentInfoProvider(widget.equipmentId));
    final role = ref.watch(currentUserRoleProvider);
    final canManage = Permissions.canAccessRoute(role, Routes.addEquipment);
    final canAddTask = Permissions.canAccessRoute(role, Routes.addTask);
    final info = async.valueOrNull;

    if (async.error is ForeignEquipmentException) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => context.pop(),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: ForeignEquipmentNotice(
                      actionLabel: 'Go Back',
                      onAction: () => context.pop(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: _green,
        onRefresh: () =>
            ref.refresh(equipmentInfoProvider(widget.equipmentId).future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header image with title + actions overlaid
              _buildHeaderImage(
                context,
                info?.equipment,
                canManage: canManage,
                canAddTask: canAddTask,
              ),

              const SizedBox(height: 20),

              if (info != null) ...[
                // Equipment name + location + action icons
                _buildEquipmentInfo(context, info.equipment),

                const SizedBox(height: 16),

                // Equipment Information card
                _buildEquipmentInformationCard(info.equipment),

                const SizedBox(height: 24),

                // Repair History
                _buildRepairHistorySection(info),

                const SizedBox(height: 32),
              ] else if (async.hasError)
                _stateMessage(
                  'Could not load equipment',
                  '${async.error}',
                  onRetry: () =>
                      ref.invalidate(equipmentInfoProvider(widget.equipmentId)),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child: CircularProgressIndicator(color: _green),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stateMessage(String title, String subtitle, {VoidCallback? onRetry}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
      child: Center(
        child: Column(
          children: [
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
                  side: const BorderSide(color: _green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontFamily: 'Montserrat', color: _green),
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
  Widget _buildHeaderImage(
    BuildContext context,
    Equipment? equipment, {
    required bool canManage,
    required bool canAddTask,
  }) {
    final image = mediaUrl(equipment?.imageUrl ?? widget.imageUrl);
    Widget fallback() => Image.asset(
          'assets/images/equipment_header.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFC68A5E), Color(0xFFE8D4C4)],
                ),
              ),
              child: Icon(
                Icons.kitchen,
                size: 90,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            );
          },
        );

    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full-width equipment image
          if (image.startsWith('http'))
            Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback(),
            )
          else
            fallback(),

          // Subtle dark gradient at top for text legibility
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    // Back arrow
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Equipment Details',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const Spacer(),
                    // Edit button (green filled circle)
                    if (canManage) ...[
                      _circleAction(
                        onTap: () {
                          if (equipment != null) _openEdit(equipment);
                        },
                        backgroundColor: _green,
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    // Task-add button (white circle, green icon)
                    if (canAddTask)
                      _circleAction(
                        onTap: () {
                          if (equipment != null) _createTask(equipment);
                        },
                        backgroundColor: Colors.white,
                        child: const Icon(
                          Icons.add_task,
                          color: _green,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleAction({
    required VoidCallback onTap,
    required Color backgroundColor,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Equipment name + location
  // ---------------------------------------------------------------------------
  Widget _buildEquipmentInfo(BuildContext context, Equipment e) {
    final location = e.location ?? e.company?.location;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  e.name,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              // QR icon
              GestureDetector(
                onTap: () {
                  context.push(
                    '${Routes.equipmentQr}/${e.id}',
                    extra: {
                      'equipmentName': e.name,
                      'serialNumber': e.egSerialNumber,
                    },
                  );
                },
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.black87,
                  size: 22,
                ),
              ),
              const SizedBox(width: 18),
              // Download QR sticker PDF
              GestureDetector(
                onTap: _downloading ? null : () => _downloadQr(e),
                child: _downloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _green,
                        ),
                      )
                    : const Icon(
                        Icons.file_download_outlined,
                        color: Colors.black87,
                        size: 22,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: _green, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  location ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _green,
                    letterSpacing: -0.42,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String status, {bool active = true}) {
    final color = active ? _green : const Color(0xFFD32F2F);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? _badgeBg : const Color(0xFFFDE8E8),
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
            status,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Equipment Information card
  // ---------------------------------------------------------------------------
  Widget _buildEquipmentInformationCard(Equipment e) {
    String v(String? value) =>
        value == null || value.trim().isEmpty ? '-' : value.trim();
    final rows = <(String, String)>[
      ('Make', v(e.make)),
      ('Model', v(e.model)),
      ('S.No', v(e.serialNumber)),
      ('Mfg.Year', v(e.manufacturerDate?.year.toString())),
      ('Maintainance Frequency', v(e.tmFrequency?.label)),
      ('EG Serial Number', v(e.egSerialNumber)),
      ('Description', v(e.description)),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0D9EE).withValues(alpha: 0.75),
            blurRadius: 32,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Decorative faint background
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  'assets/images/equipment_detail_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                children: [
                  // Wrench icon in green circle
                  Container(
                    width: 51,
                    height: 51,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCEBDD),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.build,
                      color: _greenTitle,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Equipment Information',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _greenTitle,
                      letterSpacing: -0.54,
                    ),
                  ),
                  const SizedBox(height: 22),
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    _infoText(rows[i].$1, rows[i].$2),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoText(String label, String value) {
    return Align(
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.45,
          ),
          children: [
            TextSpan(
              text: '$label  :  ',
              style: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Repair History
  // ---------------------------------------------------------------------------
  Widget _buildRepairHistorySection(EquipmentInfo info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.build,
                  color: Color(0xFF5B5B5B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Repair History',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: -0.54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (info.history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'No service history yet',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
          )
        else
          for (final task in info.history)
            _buildRepairHistoryItem(task, info.equipment),
      ],
    );
  }

  Widget _buildRepairHistoryItem(ServiceTask task, Equipment equipment) {
    final isOpen =
        task.status != TaskStatus.completed && task.status != TaskStatus.closed;
    final title = task.name.isNotEmpty
        ? task.name
        : (task.description.isNotEmpty ? task.description : task.ticketNo);
    final date = task.createdAt;

    return GestureDetector(
      onTap: () => context.push(
        '${Routes.taskDetails}/${task.id}',
        extra: {
          'taskTitle': title,
          'status': task.status.label,
          'companyName': equipment.company?.displayName,
          'clientName': task.client?.name,
          'mobile': task.client?.phone,
          'technician': task.technician?.name,
          'technicianMobile': task.technician?.phone,
          'createdOn': date == null ? null : _fmtDate(date),
          'serialNumber': equipment.egSerialNumber,
          'description': task.description,
        },
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(11, 0, 11, 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE0D9EE).withValues(alpha: 0.75),
              blurRadius: 32,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status icon in light circle
            Container(
              width: 39,
              height: 39,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF1F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOpen ? Icons.incomplete_circle : Icons.check_circle,
                color: const Color(0xFF5B899E),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            letterSpacing: -0.45,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Green status pill with dot
                      _statusPill(isOpen ? 'Active' : 'Closed'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    date == null ? '' : _fmtDate(date),
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withValues(alpha: 0.4),
                      letterSpacing: -0.42,
                    ),
                  ),
                  const SizedBox(height: 5),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        letterSpacing: -0.42,
                      ),
                      children: [
                        TextSpan(
                          text: 'Service Engineer : ',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                        TextSpan(
                          text: task.technician?.name ?? 'Unassigned',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // PDF download (plain green download + label)
            GestureDetector(
              onTap: () => _downloadReport(task),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_reportTaskId == task.id)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: Padding(
                        padding: EdgeInsets.all(3),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _green,
                        ),
                      ),
                    )
                  else
                    const Icon(Icons.download, color: _green, size: 24),
                  const SizedBox(height: 4),
                  const Text(
                    'PDF',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: -0.42,
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

  String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }
}
