import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../web/widgets/web_upload_content.dart';
import '../../../amcs/data/equipment_provider.dart';
import '../../data/xlsx_template.dart';
import 'upload_equipments_screen.dart';
import '../../../../core/theme/app_colors.dart';

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
  List<int>? uploadedFileBytes;
  bool isUploading = false;

  static const Color _green = AppColors.primary;
  static const Color _lavender = Color(0xFFEBEDFF);
  static const Color _webUploadSurface = Color(0xFFF0F6F0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kIsWeb ? const Color(0xFFF3F7F3) : Colors.white,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            if (!kIsWeb)
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
                  if (!kIsWeb) _buildHeader(),
                  Expanded(
                    child: kIsWeb
                        ? WebUploadContent(child: _buildCard())
                        : SingleChildScrollView(
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
    const compact = kIsWeb;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: compact
                ? const Color(0xFF173B22).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: compact ? 24 : 32,
            offset: Offset(0, compact ? 8 : 4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 16,
        compact ? 12 : 20,
        compact ? 20 : 16,
        compact ? 14 : 24,
      ),
      child: Column(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Image.asset(
            'assets/images/upload_illustration.png',
            width: compact ? 76 : 180,
            height: compact ? 76 : 180,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.cloud_upload_outlined,
              size: 90,
              color: Color(0xFF42A5F5),
            ),
          ),
          SizedBox(height: compact ? 8 : 16),

          // Download Sample Excel
          _buildDownloadTemplateCard(),
          SizedBox(height: compact ? 8 : 19),

          // File upload box
          _buildFileUploadArea(),
          SizedBox(height: compact ? 10 : 24),

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
        padding: EdgeInsets.all(kIsWeb ? 10 : 16),
        decoration: BoxDecoration(
          color: kIsWeb ? _webUploadSurface : _lavender,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Excel icon in light circle
            Container(
              width: kIsWeb ? 38 : 48,
              height: kIsWeb ? 38 : 48,
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
            SizedBox(width: kIsWeb ? 10 : 14),
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
                  SizedBox(height: kIsWeb ? 2 : 4),
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
            Icon(Icons.download, color: Colors.black, size: kIsWeb ? 20 : 24),
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
        padding: EdgeInsets.symmetric(
          vertical: kIsWeb ? 10 : 28,
          horizontal: 20,
        ),
        decoration: BoxDecoration(
          color: kIsWeb ? _webUploadSurface : _lavender,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: kIsWeb ? 38 : 48,
              height: kIsWeb ? 38 : 48,
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
            SizedBox(height: kIsWeb ? 6 : 14),
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
                  if (kIsWeb)
                    SizedBox(
                      width: (MediaQuery.sizeOf(context).width - 200)
                          .clamp(0.0, 420.0)
                          .toDouble(),
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
                    )
                  else
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
                      uploadedFileBytes = null;
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
        withData: kIsWeb,
      );
      final file = result?.files.singleOrNull;
      if (file == null) return;
      if (kIsWeb && file.bytes == null) {
        _snack('Could not read the selected file. Please try again.',
            error: true);
        return;
      }
      if (!kIsWeb && file.path == null) return;
      setState(() {
        uploadedFileName = file.name;
        uploadedFilePath = kIsWeb ? null : file.path;
        uploadedFileBytes = kIsWeb ? file.bytes : null;
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
    final fileName = uploadedFileName;
    final path = uploadedFilePath;
    final bytes = uploadedFileBytes;
    if (fileName == null || (kIsWeb ? bytes == null : path == null)) {
      _snack('Please choose an Excel (.xlsx) file', error: true);
      return;
    }
    if (fileName.toLowerCase().endsWith('.xls')) {
      _snack('Please save the sheet as .xlsx and upload again', error: true);
      return;
    }
    setState(() => isUploading = true);
    try {
      final result = await ref.read(equipmentApiProvider).uploadTechnicianExcel(
            filePath: path,
            fileBytes: bytes,
            fileName: fileName,
          );
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
