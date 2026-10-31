import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';
import '../../data/qr_pdf.dart';

/// Downloads the backend QR sticker PDF for every equipment of a company
/// branch.
class DownloadQrScreen extends ConsumerStatefulWidget {
  const DownloadQrScreen({super.key});

  @override
  ConsumerState<DownloadQrScreen> createState() => _DownloadQrScreenState();
}

class _DownloadQrScreenState extends ConsumerState<DownloadQrScreen> {
  String? selectedCompany;
  String? selectedBranch;
  bool isDownloading = false;

  static const Color _green = Color(0xFF106220);
  static const Color _lavender = Color(0xFFEBEDFF);

  static const String _noBranch = 'Main';

  String _branchOf(Company c) =>
      c.branchName.trim().isEmpty ? _noBranch : c.branchName.trim();

  Company? _selected(List<Company> companies) {
    for (final c in companies) {
      if (c.name == selectedCompany && _branchOf(c) == selectedBranch) {
        return c;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/home_bg.png',
                fit: BoxFit.cover,
                color: Colors.white.withValues(alpha: 0.78),
                colorBlendMode: BlendMode.srcOver,
                errorBuilder: (_, __, ___) => Container(color: Colors.white),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: _buildCard(),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Download QR',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: -0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 32,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        children: [
          _buildIllustration(),
          const SizedBox(height: 16),
          ref.watch(companiesProvider).when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(color: _green),
                ),
                error: (e, _) => Column(
                  children: [
                    Text(
                      'Could not load companies: $e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Montserrat'),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(companiesProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
                data: _buildForm,
              ),
        ],
      ),
    );
  }

  Widget _buildForm(List<Company> companies) {
    final names = {for (final c in companies) c.name}.toList()..sort();
    final branches = selectedCompany == null
        ? <String>[]
        : ({
            for (final c in companies)
              if (c.name == selectedCompany) _branchOf(c),
          }.toList()
          ..sort());
    final company = _selected(companies);

    return Column(
      children: [
        _pillDropdown(
          hint: 'Company Name',
          value: selectedCompany,
          items: names,
          onChanged: (v) => setState(() {
            selectedCompany = v;
            final options = {
              for (final c in companies)
                if (c.name == v) _branchOf(c),
            };
            selectedBranch = options.length == 1 ? options.first : null;
          }),
        ),
        const SizedBox(height: 19),
        _pillDropdown(
          key: ValueKey('branch-$selectedCompany'),
          hint: 'Branch Name',
          value: selectedBranch,
          items: branches,
          onChanged: (v) => setState(() => selectedBranch = v),
        ),
        const SizedBox(height: 19),
        _buildDownloadQrCard(),
        const SizedBox(height: 24),
        _buildDownloadButton(company),
      ],
    );
  }

  // Simple QR illustration (3 tilted blue QR cards)
  Widget _buildIllustration() {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 80,
            child: Transform.rotate(
              angle: -0.18,
              child: _qrCard(const Color(0xFF2E7BE4), 72, Colors.white),
            ),
          ),
          Positioned(
            right: 80,
            child: Transform.rotate(
              angle: 0.18,
              child: _qrCard(const Color(0xFF2E7BE4), 72, Colors.white),
            ),
          ),
          _qrCard(Colors.white, 86, const Color(0xFF1565C0), elevated: true),
        ],
      ),
    );
  }

  Widget _qrCard(Color bg, double size, Color dot, {bool elevated = false}) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: List.generate(9, (i) {
          final filled = [0, 2, 4, 6, 8].contains(i);
          return Container(
            decoration: BoxDecoration(
              color: filled ? dot : dot.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }

  Widget _pillDropdown({
    Key? key,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(32),
      child: DropdownButtonFormField<String>(
        key: key,
        initialValue: value,
        isExpanded: true,
        hint: Text(
          hint,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black.withValues(alpha: 0.4),
          ),
        ),
        icon: Icon(
          Icons.arrow_drop_down,
          color: Colors.black.withValues(alpha: 0.6),
          size: 26,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: const BorderSide(color: _green, width: 1.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
        selectedItemBuilder: (context) {
          return items.map((item) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            );
          }).toList();
        },
        items: items.map((item) {
          final isSelected = item == value;
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? _green : Colors.black87,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDownloadQrCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lavender,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.qr_code_2, color: Colors.black87, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Download QR',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scan QR  to get the Template',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.download, color: Colors.black, size: 24),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(Company? company) {
    return GestureDetector(
      onTap: isDownloading
          ? null
          : company == null
              ? () => _snack(
                    'Please select the company and branch',
                    error: true,
                  )
              : () => _downloadQr(company),
      child: Container(
        width: double.infinity,
        height: 47,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF138A2A), _green],
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Center(
          child: isDownloading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Download QR',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _downloadQr(Company company) async {
    setState(() => isDownloading = true);
    try {
      final equipment = await ref.read(equipmentsProvider(company.id).future);
      if (equipment.isEmpty) {
        _snack('This branch has no equipment yet', error: true);
        return;
      }
      await shareQrStickerPdf(
        ref,
        companyId: company.id,
        filename: 'qr_${qrFileSlug(company.displayName)}.pdf',
      );
      _snack('QR Code downloaded successfully!');
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => isDownloading = false);
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade400 : _green,
      ),
    );
  }
}
