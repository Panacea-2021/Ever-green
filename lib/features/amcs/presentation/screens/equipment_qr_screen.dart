import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../qr/data/qr_pdf.dart';
import '../../data/equipment_provider.dart';

/// QR preview for one equipment. Encodes the bare equipment id, exactly like
/// the backend sticker PDF (`qrCodeGenerator`) and the scanner expect.
class EquipmentQrScreen extends ConsumerStatefulWidget {
  final String equipmentId;
  final String? equipmentName;
  final String? serialNumber;

  const EquipmentQrScreen({
    super.key,
    required this.equipmentId,
    this.equipmentName,
    this.serialNumber,
  });

  @override
  ConsumerState<EquipmentQrScreen> createState() => _EquipmentQrScreenState();
}

class _EquipmentQrScreenState extends ConsumerState<EquipmentQrScreen> {
  static const Color _qrBorder = Color(0xFF1D7A33);
  bool _downloading = false;

  bool get _hasDetails =>
      widget.equipmentName != null &&
      (widget.serialNumber?.isNotEmpty ?? false) &&
      int.tryParse(widget.equipmentId) != null;

  @override
  Widget build(BuildContext context) {
    // Deep links may arrive without name/serial (or with a serial as the id);
    // resolve them from the backend.
    final info = _hasDetails
        ? null
        : ref.watch(equipmentInfoProvider(widget.equipmentId));
    final equipment = info?.valueOrNull?.equipment;
    final id = equipment?.id.toString() ?? widget.equipmentId;
    final name = equipment?.name ?? widget.equipmentName ?? 'Equipment';
    final serial = equipment?.egSerialNumber ?? widget.serialNumber ?? '';
    final loading = info?.isLoading ?? false;
    final error = info?.hasError ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Faint background texture
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_bg.png',
              fit: BoxFit.cover,
              color: Colors.white.withValues(alpha: 0.7),
              colorBlendMode: BlendMode.srcOver,
              errorBuilder: (_, __, ___) => Container(color: Colors.white),
            ),
          ),

          // Soft decorative circles
          _buildBackgroundDecorations(),

          // Main content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context, name, id, serial, canDownload: !loading && !error),
                Expanded(
                  child: Center(
                    child: loading
                        ? const CircularProgressIndicator(color: _qrBorder)
                        : error
                            ? _buildError('${info!.error}')
                            : _buildQrCodeCard(id, serial),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () =>
                ref.invalidate(equipmentInfoProvider(widget.equipmentId)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    Widget circle(double size) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.025),
            shape: BoxShape.circle,
          ),
        );

    return Stack(
      children: [
        Positioned(top: 40, right: -40, child: circle(160)),
        Positioned(top: 180, left: -40, child: circle(120)),
        Positioned(bottom: 120, right: -50, child: circle(150)),
        Positioned(bottom: -40, left: 20, child: circle(120)),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String name,
    String id,
    String serial, {
    required bool canDownload,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 8),
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
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: -0.6,
              ),
            ),
          ),
          // Download icon (plain, dark)
          if (_downloading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: _qrBorder),
            )
          else
            GestureDetector(
              onTap: canDownload
                  ? () => _download(id, serial.isEmpty ? name : serial)
                  : null,
              child: const Icon(
                Icons.download,
                color: Colors.black87,
                size: 26,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQrCodeCard(String id, String serial) {
    return Container(
      width: 299,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // QR with green rounded border
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: _qrBorder, width: 4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: id,
              version: QrVersions.auto,
              size: 180,
              gapless: true,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
          if (serial.isNotEmpty) ...[
            const SizedBox(height: 20),
            // Serial number
            Text(
              serial,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: -0.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _download(String id, String label) async {
    final equipmentId = int.tryParse(id);
    if (equipmentId == null) return;
    setState(() => _downloading = true);
    try {
      await shareQrStickerPdf(
        ref,
        equipmentIds: [equipmentId],
        filename: 'qr_${qrFileSlug(label)}.pdf',
      );
      if (mounted) _showDownloadSnackbar(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _showDownloadSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'QR Code downloaded successfully',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFF106220),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
