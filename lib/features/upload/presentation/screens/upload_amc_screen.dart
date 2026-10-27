import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../amcs/data/amc_provider.dart';
import '../../data/xlsx_template.dart';

class UploadAmcScreen extends ConsumerStatefulWidget {
  const UploadAmcScreen({super.key});

  @override
  ConsumerState<UploadAmcScreen> createState() => _UploadAmcScreenState();
}

class _UploadAmcScreenState extends ConsumerState<UploadAmcScreen> {
  String? uploadedFileName;
  String? _filePath;
  Uint8List? _fileBytes;
  bool isUploading = false;
  CompanyUploadResult? _result;

  static const Color _green = Color(0xFF106220);
  static const Color _lavender = Color(0xFFEBEDFF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Faint background
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
              'Upload Company Excel Data',
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
          // Illustration
          Image.asset(
            'assets/images/upload_illustration.png',
            width: 180,
            height: 180,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.cloud_upload_outlined,
              size: 90,
              color: Color(0xFF42A5F5),
            ),
          ),
          const SizedBox(height: 16),

          // Download Sample Excel
          _buildDownloadTemplateCard(),
          const SizedBox(height: 19),

          // File upload box
          _buildFileUploadArea(),
          const SizedBox(height: 24),

          // Submit button
          _buildSubmitButton(),

          if (_result != null) ...[
            const SizedBox(height: 20),
            _buildResult(_result!),
          ],
        ],
      ),
    );
  }

  Widget _buildDownloadTemplateCard() {
    return GestureDetector(
      onTap: _downloadTemplate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _lavender,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Excel icon in light circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFF217346),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Center(
                    child: Text(
                      'X',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Download Sample Excel',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Click to Download',
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
      ),
    );
  }

  /// Saves the sample .xlsx (headers `user/uploadCompanyData` reads plus
  /// example rows).
  Future<void> _downloadTemplate() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final saved = await saveXlsxTemplate(
        'company_upload_sample.xlsx',
        companyTemplateHeaders,
        rows: companySampleRows,
      );
      if (!mounted || (saved == null && !kIsWeb)) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Sample Excel saved. Replace the example rows with your companies.',
          ),
          backgroundColor: _green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not save the sample Excel: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  Widget _buildFileUploadArea() {
    return GestureDetector(
      onTap: isUploading ? null : _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: _lavender,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                color: Colors.black.withValues(alpha: 0.55),
                size: 24,
              ),
            ),
            const SizedBox(height: 14),
            if (uploadedFileName != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.insert_drive_file,
                    color: Color(0xFF217346),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      uploadedFileName!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: isUploading ? null : _clearFile,
                    child: const Icon(Icons.close, color: Colors.red, size: 18),
                  ),
                ],
              ),
            ] else ...[
              const Text(
                'Drop your File here',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Supports .xlsx',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _clearFile() {
    setState(() {
      uploadedFileName = null;
      _filePath = null;
      _fileBytes = null;
    });
  }

  Future<void> _pickFile() async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        withData: kIsWeb,
      );
      final file = picked?.files.single;
      if (file == null || !mounted) return;
      setState(() {
        uploadedFileName = file.name;
        _filePath = kIsWeb ? null : file.path;
        _fileBytes = file.bytes;
        _result = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open file: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: isUploading ? null : _submitForm,
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
          child: isUploading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Submit',
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

  Future<void> _submitForm() async {
    final name = uploadedFileName;
    final messenger = ScaffoldMessenger.of(context);
    if (name == null || (_filePath == null && _fileBytes == null)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please choose an .xlsx file first'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }
    setState(() {
      isUploading = true;
      _result = null;
    });
    try {
      final result = await ref.read(amcRepositoryProvider).uploadCompanyData(
            path: _filePath,
            bytes: _fileBytes,
            fileName: name,
          );
      if (result.added > 0) ref.invalidate(companiesProvider);
      if (!mounted) return;
      if (result.errors.isEmpty && result.skipped == 0) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Company data uploaded successfully!'),
            backgroundColor: _green,
          ),
        );
        context.pop();
        return;
      }
      setState(() {
        isUploading = false;
        _result = result;
      });
      messenger.showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: _green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isUploading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  Widget _buildResult(CompanyUploadResult r) {
    Widget stat(String label, int value, Color color) => Expanded(
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        );

    final rowErrors = r.errors.length -
        r.errors.where((e) => e.startsWith('Duplicate skipped')).length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r.message,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              stat('Added', r.added, _green),
              stat('Duplicates', r.skipped, const Color(0xFFE08600)),
              stat('Errors', rowErrors, const Color(0xFFD32F2F)),
            ],
          ),
          if (r.errors.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final e in r.errors)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      e.startsWith('Duplicate')
                          ? Icons.content_copy
                          : Icons.error_outline,
                      size: 15,
                      color: e.startsWith('Duplicate')
                          ? const Color(0xFFE08600)
                          : const Color(0xFFD32F2F),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
