import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../amcs/data/equipment_provider.dart';
import '../../data/xlsx_template.dart';
import 'upload_equipments_screen.dart';

class UploadTechniciansScreen extends ConsumerStatefulWidget {
  const UploadTechniciansScreen({super.key});

  @override
  ConsumerState<UploadTechniciansScreen> createState() =>
      _UploadTechniciansScreenState();
}

class _UploadTechniciansScreenState
    extends ConsumerState<UploadTechniciansScreen> {
  String? uploadedFileName;
  String? uploadedFilePath;
  bool isUploading = false;

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
              'Upload Service Engineers Excel Data',
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

  Widget _buildFileUploadArea() {
    return GestureDetector(
      onTap: _pickFile,
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
                    onTap: () => setState(() {
                      uploadedFileName = null;
                      uploadedFilePath = null;
                    }),
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
                'Supports .xlsx , .xls upto 10MB',
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

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx', 'xls'],
      );
      final file = result?.files.singleOrNull;
      if (file == null || file.path == null) return;
      setState(() {
        uploadedFileName = file.name;
        uploadedFilePath = file.path;
      });
      _snack('File selected: ${file.name}');
    } catch (e) {
      _snack('Could not pick the file: $e', error: true);
    }
  }

  Future<void> _downloadTemplate() async {
    try {
      final path = await saveXlsxTemplate(
        'service_engineer_upload_sample.xlsx',
        technicianTemplateHeaders,
        rows: technicianSampleRows,
      );
      if (path != null) {
        _snack(
          'Sample Excel saved. Replace the example rows with your service engineers.',
        );
      }
    } catch (e) {
      _snack('Could not save the sample Excel: $e', error: true);
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
    final path = uploadedFilePath;
    if (path == null) {
      _snack('Please choose an Excel (.xlsx) file', error: true);
      return;
    }
    if (path.toLowerCase().endsWith('.xls')) {
      _snack('Please save the sheet as .xlsx and upload again', error: true);
      return;
    }
    setState(() => isUploading = true);
    try {
      final result =
          await ref.read(equipmentApiProvider).uploadTechnicianExcel(path);
      ref.invalidate(techniciansProvider);
      if (!mounted) return;
      if (result.errors.isEmpty) {
        _snack('Service engineers data uploaded successfully!');
        context.pop();
        return;
      }
      await showUploadResultDialog(context, result);
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }
}
