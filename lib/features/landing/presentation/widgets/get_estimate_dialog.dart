import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../free_estimates/data/free_estimates_repository.dart';
import '../landing_theme.dart';

Future<void> showGetEstimateDialog(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Get Estimate',
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (_, __, ___) => const _GetEstimateDialog(),
    transitionBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class _GetEstimateDialog extends ConsumerStatefulWidget {
  const _GetEstimateDialog();

  @override
  ConsumerState<_GetEstimateDialog> createState() => _GetEstimateDialogState();
}

class _GetEstimateDialogState extends ConsumerState<_GetEstimateDialog> {
  List<Map<String, dynamic>> _equipment = const [];
  List<dynamic> _services = const [];
  bool _loadingOptions = true;
  String? _optionsError;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _problemController = TextEditingController();

  String? _selectedEquipmentId;
  dynamic _selectedService;
  List<PlatformFile> _photos = [];
  String? _photoError;

  bool _submitting = false;
  String? _reference;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _problemController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loadingOptions = true;
      _optionsError = null;
    });
    try {
      final repo = ref.read(freeEstimatesRepositoryProvider);
      final results = await Future.wait<dynamic>([
        repo.fetchEquipment(),
        repo.fetchServices(),
      ]);
      if (!mounted) return;
      setState(() {
        _equipment = results[0] as List<Map<String, dynamic>>;
        _services = results[1] as List<dynamic>;
        _loadingOptions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _optionsError = e.toString();
        _loadingOptions = false;
      });
    }
  }

  Future<void> _pickPhotos() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (!mounted || result == null) return;
      final files = result.files.take(5).toList();
      setState(() {
        _photos = files;
        _photoError = null;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() => _photoError = 'Could not open photos. Please try again.');
    }
  }

  String _serviceLabel(dynamic s) {
    if (s is Map) return '${s['name'] ?? s['service'] ?? s['id'] ?? ''}';
    return '$s';
  }

  Future<void> _requestEstimate() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEquipmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select equipment first')),
      );
      return;
    }
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service first')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final repo = ref.read(freeEstimatesRepositoryProvider);
      final equipmentId = int.tryParse(_selectedEquipmentId!) ?? 0;
      final reference = await repo.submit(
        equipmentId: equipmentId,
        service: _selectedService.toString(),
        problemDescription: _problemController.text.trim(),
        customerName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        photos: _photos,
      );
      if (!mounted) return;
      setState(() {
        _reference = reference ?? 'EG-${100000 + (DateTime.now().millisecondsSinceEpoch % 900000)}';
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estimate request failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      key: const ValueKey('get-estimate-dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: size.width < 592 ? size.width - 32 : 560,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: size.height - 32),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(size.width < 600 ? 20 : 28),
            child: _reference == null ? _buildForm(size) : _buildSuccess(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(Size size) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Get a Free Estimate',
                  style: TextStyle(
                    fontFamily: LandingTypography.fontFamily,
                    fontSize: size.width < 600 ? 21 : 24,
                    fontWeight: FontWeight.w700,
                    color: LandingColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('get-estimate-close'),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('Select Equipment'),
          const SizedBox(height: 8),
          if (_loadingOptions)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (_optionsError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text('Could not load options: $_optionsError', style: const TextStyle(color: Colors.red, fontSize: 12))),
                    TextButton(onPressed: _loadOptions, child: const Text('Retry')),
                  ],
                ),
              ),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedEquipmentId,
              decoration: _decoration('Choose equipment'),
              items: _equipment
                  .map((e) => DropdownMenuItem<String>(
                        value: '${e['id']}',
                        child: Text('${e['name'] ?? e['equipment'] ?? e['id']}'),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedEquipmentId = value),
              validator: (value) => value == null ? 'Equipment is required' : null,
            ),
            const SizedBox(height: 18),
            _sectionTitle('Select Service'),
            const SizedBox(height: 8),
            DropdownButtonFormField<dynamic>(
              isExpanded: true,
              initialValue: _selectedService,
              decoration: _decoration('Choose a service'),
              items: _services
                  .map((s) => DropdownMenuItem<dynamic>(
                        value: s,
                        child: Text(_serviceLabel(s)),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedService = value),
              validator: (value) => value == null ? 'Service is required' : null,
            ),
          ],
          const SizedBox(height: 18),
          _sectionTitle('Describe the Problem'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _problemController,
            minLines: 3,
            maxLines: 5,
            textAlignVertical: TextAlignVertical.top,
            decoration: _decoration(
              'Briefly explain the issue with your machinery...',
              alignLabelWithHint: true,
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Problem description is required'
                : null,
          ),
          const SizedBox(height: 18),
          _sectionTitle('Upload Photos (Optional)'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _pickPhotos,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose Photos'),
              style: OutlinedButton.styleFrom(
                foregroundColor: LandingColors.primary,
                side: const BorderSide(color: LandingColors.borderActive),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          if (_photoError != null) ...[
            const SizedBox(height: 4),
            Text(
              _photoError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (var index = 0; index < _photos.length; index++)
                  InputChip(
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        _photos[index].name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onDeleted: () {
                      setState(() => _photos.removeAt(index));
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          _sectionTitle('Customer Details'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: _decoration(null, labelText: 'Customer Name'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Customer name is required'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _decoration(null, labelText: 'Phone Number'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Phone number is required'
                : null,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _requestEstimate,
              style: ElevatedButton.styleFrom(
                backgroundColor: LandingColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontFamily: LandingTypography.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Request Free Estimate'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Our team will review your details and contact you with an estimated repair cost.',
            style: TextStyle(
              fontFamily: LandingTypography.fontFamily,
              fontSize: 13,
              height: 1.5,
              color: LandingColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle,
          color: Color(0xFF106220),
          size: 56,
        ),
        const SizedBox(height: 12),
        const Text(
          'Estimate requested!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your reference is',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF5C6B60),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE5F6EA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF106220)),
          ),
          child: Text(
            _reference!,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: Color(0xFF106220),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF106220),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontFamily: LandingTypography.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: LandingColors.textPrimary,
        ),
      );

  InputDecoration _decoration(
    String? hint, {
    String? labelText,
    bool alignLabelWithHint = false,
  }) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFD7E6DA)),
    );
    return InputDecoration(
      hintText: hint,
      labelText: labelText,
      alignLabelWithHint: alignLabelWithHint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: LandingColors.borderActive),
      ),
    );
  }
}
