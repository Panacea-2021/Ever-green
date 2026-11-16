import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../landing_theme.dart';

Future<void> showGetEstimateDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _GetEstimateDialog(),
  );
}

class _GetEstimateDialog extends StatefulWidget {
  const _GetEstimateDialog();

  @override
  State<_GetEstimateDialog> createState() => _GetEstimateDialogState();
}

class _GetEstimateDialogState extends State<_GetEstimateDialog> {
  static const _equipment = [
    'Range / Oven',
    'Refrigerator',
    'Microwave',
    'Dishwasher',
    'Hood / Ventilation',
    'Mixer',
    'Fryer',
    'Chiller / Freezer',
    'Ice Machine',
    'Coffee Machine',
  ];

  static const _services = [
    'Repair',
    'Maintenance',
    'Installation',
    'AMC Service',
    'Emergency Repair',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _problemController = TextEditingController();

  String? _selectedEquipment;
  String? _selectedService;
  List<PlatformFile> _photos = [];
  String? _photoError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _problemController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (!mounted || result == null) return;
      setState(() {
        _photos = result.files;
        _photoError = null;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() => _photoError = 'Could not open photos. Please try again.');
    }
  }

  void _requestEstimate() {
    if (!_formKey.currentState!.validate()) return;
    // Connect estimate submission here when the backend endpoint is available.
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
            child: Form(
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
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedEquipment,
                    decoration: _decoration('Choose equipment'),
                    items: _equipment
                        .map(
                          (equipment) => DropdownMenuItem(
                            value: equipment,
                            child: Text(equipment),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedEquipment = value),
                    validator: (value) =>
                        value == null ? 'Equipment is required' : null,
                  ),
                  const SizedBox(height: 18),
                  _sectionTitle('Select Service'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedService,
                    decoration: _decoration('Choose a service'),
                    items: _services
                        .map(
                          (service) => DropdownMenuItem(
                            value: service,
                            child: Text(service),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedService = value),
                    validator: (value) =>
                        value == null ? 'Service is required' : null,
                  ),
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
                        side:
                            const BorderSide(color: LandingColors.borderActive),
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
                      onPressed: _requestEstimate,
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
                      child: const Text('Request Free Estimate'),
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
            ),
          ),
        ),
      ),
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
