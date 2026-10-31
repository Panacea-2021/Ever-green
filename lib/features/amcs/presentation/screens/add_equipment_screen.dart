import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../pickers/presentation/screens/company_picker_screen.dart';
import '../../data/equipment_provider.dart';
import '../../domain/models/equipment_item.dart';

class AddEquipmentScreen extends ConsumerStatefulWidget {
  final String companyId;
  final String? companyName;

  /// When provided, the screen runs in "edit" mode: title "Update Equipment",
  /// fields pre-filled from this data, and Save calls `updateEquipment`.
  /// Keys: id (required for edit), companyId, name, make, model,
  /// serialNumber, location, year, frequency ([TmFrequency.key]),
  /// description, imageUrl, status ([EquipmentCondition.key]), type,
  /// installedAt (ISO). Pops `true` after saving.
  final Map<String, dynamic>? editEquipment;

  const AddEquipmentScreen({
    super.key,
    required this.companyId,
    this.companyName,
    this.editEquipment,
  });

  bool get isEdit => editEquipment != null;

  @override
  ConsumerState<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends ConsumerState<AddEquipmentScreen> {
  final _equipmentNameController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedYear;
  String? _selectedFrequency;
  int? _companyId;
  String? _imageUrl;
  bool _uploadingImage = false;
  bool _saving = false;

  static const Color _green = Color(0xFF106220);
  static const Color _resetBorder = Color(0x80155622); // rgba(21,86,34,0.5)

  /// PM frequency labels shown in the form and their backend values.
  static const Map<String, TmFrequency> _frequencyValues = {
    'Daily': TmFrequency.daily,
    'Weekly': TmFrequency.weekly,
    'Monthly': TmFrequency.monthly,
    'Bi-Monthly': TmFrequency.biMonthly,
    'Bi-Weekly': TmFrequency.biweekly,
  };

  List<String> get _years {
    final now = DateTime.now().year;
    final years = [for (var y = now; y > now - 5; y--) '$y'];
    if (_selectedYear != null && !years.contains(_selectedYear)) {
      years.add(_selectedYear!);
    }
    return years;
  }

  List<String> get _frequencies {
    final labels = _frequencyValues.keys.toList();
    if (_selectedFrequency != null && !labels.contains(_selectedFrequency)) {
      labels.add(_selectedFrequency!);
    }
    return labels;
  }

  bool get _needsCompany =>
      !widget.isEdit && int.tryParse(widget.companyId) == null;

  @override
  void initState() {
    super.initState();
    _companyId = int.tryParse(widget.companyId);
    if (widget.isEdit) _applyEditData();
  }

  String _frequencyLabel(TmFrequency f) {
    for (final e in _frequencyValues.entries) {
      if (e.value == f) return e.key;
    }
    return f.label;
  }

  TmFrequency? _frequencyFor(String? label) {
    if (label == null) return null;
    final known = _frequencyValues[label];
    if (known != null) return known;
    for (final f in TmFrequency.values) {
      if (f.label == label) return f;
    }
    return null;
  }

  void _applyEditData() {
    final d = widget.editEquipment!;
    String s(String k) => d[k]?.toString().trim() ?? '';
    _equipmentNameController.text = s('name');
    _makeController.text = s('make');
    _modelController.text = s('model');
    _serialNumberController.text = s('serialNumber');
    _locationController.text = s('location');
    _descriptionController.text = s('description');
    final year = s('year');
    _selectedYear = year.isEmpty ? null : year;
    final freq = TmFrequency.fromKey(s('frequency'));
    _selectedFrequency = freq == null ? null : _frequencyLabel(freq);
    _companyId = int.tryParse(s('companyId')) ?? int.tryParse(widget.companyId);
    final image = s('imageUrl');
    _imageUrl = image.isEmpty ? null : image;
  }

  @override
  void dispose() {
    _equipmentNameController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _serialNumberController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      child: _buildFormCard(),
                    ),
                  ),
                  _buildBottomButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 14),
          Text(
            widget.isEdit ? 'Update Equipment' : 'Add Equipment',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.6,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Form card
  // ---------------------------------------------------------------------------
  Widget _buildFormCard() {
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      child: Column(
        children: [
          // Icon
          Container(
            width: 51,
            height: 51,
            decoration: const BoxDecoration(
              color: Color(0xFFDCEBDD),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.apartment, color: _green, size: 26),
          ),
          const SizedBox(height: 14),
          const Text(
            'Equipment Information',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Provide basic details of the Equipment',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.4),
              letterSpacing: -0.45,
            ),
          ),
          const SizedBox(height: 22),

          if (_needsCompany) ...[
            _buildCompanyPicker(),
            const SizedBox(height: 19),
          ],

          // Fields
          _pillField(_equipmentNameController, 'Fridge'),
          const SizedBox(height: 19),
          _pillField(_makeController, 'Make'),
          const SizedBox(height: 19),
          _pillField(_modelController, 'Model Number'),
          const SizedBox(height: 19),
          _pillField(_serialNumberController, 'Serial Number'),
          const SizedBox(height: 19),

          // Upload box
          _buildUploadBox(),
          const SizedBox(height: 19),

          // Location
          _pillField(_locationController, 'Hyderabad'),
          const SizedBox(height: 19),

          // Manufacturer Year dropdown
          _dropdownField(
            'Manufacturer Year',
            _selectedYear,
            _years,
            (v) => setState(() => _selectedYear = v),
          ),
          const SizedBox(height: 19),

          // PM Frequency dropdown
          _dropdownField(
            'PM Frequency',
            _selectedFrequency,
            _frequencies,
            (v) => setState(() => _selectedFrequency = v),
          ),
          const SizedBox(height: 19),

          // Description
          _buildDescriptionField(),
        ],
      ),
    );
  }

  Widget _buildCompanyPicker() {
    final async = ref.watch(companiesProvider);
    final companies = async.valueOrNull ?? const <Company>[];
    Company? selected;
    for (final c in companies) {
      if (c.id == _companyId) selected = c;
    }
    return _dropdownField(
      async.hasError ? 'Company (tap to retry)' : 'Company',
      selected?.displayName,
      const [],
      (_) {},
      onTapOverride: async.hasError
          ? () => ref.invalidate(companiesProvider)
          : _pickCompany,
    );
  }

  Future<void> _pickCompany() async {
    final picked =
        await CompanyPickerScreen.open(context, selectedId: _companyId);
    if (picked != null && mounted) setState(() => _companyId = picked.id);
  }

  // Pill-shaped text field with soft shadow, no border
  Widget _pillField(TextEditingController controller, String hint) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(32),
      child: TextField(
        controller: controller,
        cursorColor: _green,
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
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black.withValues(alpha: 0.4),
          ),
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
      ),
    );
  }

  Widget _dropdownField(
    String hint,
    String? value,
    List<String> items,
    Function(String?) onChanged, {
    VoidCallback? onTapOverride,
  }) {
    return GestureDetector(
      onTap: onTapOverride ??
          () => _showDropdownSheet(hint, items, value, onChanged),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(32),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: value != null
                        ? Colors.black
                        : Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: Colors.black.withValues(alpha: 0.6),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(24),
      child: TextField(
        controller: _descriptionController,
        cursorColor: _green,
        maxLines: 6,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Description',
          hintStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black.withValues(alpha: 0.4),
          ),
          contentPadding: const EdgeInsets.all(16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: _green, width: 1.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Upload box (light lavender)
  // ---------------------------------------------------------------------------
  Widget _buildUploadBox() {
    final image = mediaUrl(_imageUrl);
    return GestureDetector(
      onTap: _uploadingImage ? null : _showImagePickerDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: const Color(0xFFEBEDFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: _uploadingImage
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _green,
                      ),
                    )
                  : image.isNotEmpty
                      ? Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _uploadIcon(),
                        )
                      : _uploadIcon(),
            ),
            const SizedBox(height: 14),
            const Text(
              'Please upload your image here',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Jpg,Png upto 5MB',
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
    );
  }

  Widget _uploadIcon() {
    return Icon(
      Icons.cloud_upload_outlined,
      color: Colors.black.withValues(alpha: 0.55),
      size: 24,
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom buttons
  // ---------------------------------------------------------------------------
  Widget _buildBottomButtons() {
    final showBulkUpload = !widget.isEdit &&
        Permissions.canBulkUpload(ref.watch(currentUserRoleProvider));
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (showBulkUpload) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push(Routes.uploadEquipments),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: _resetBorder, width: 1),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          color: Color(0xFF0E501B),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Bulk Upload',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0E501B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            // Save (gradient)
            Expanded(
              child: GestureDetector(
                onTap: _saving ? null : _saveEquipment,
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF138A2A), _green],
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.isEdit ? 'Update' : 'Save',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dialogs / actions
  // ---------------------------------------------------------------------------
  void _showDropdownSheet(
    String title,
    List<String> items,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isSelected = item == selectedValue;
              return GestureDetector(
                onTap: () {
                  onChanged(item);
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE8F5E9)
                        : Colors.transparent,
                    borderRadius: i == 0
                        ? const BorderRadius.vertical(top: Radius.circular(16))
                        : i == items.length - 1
                            ? const BorderRadius.vertical(
                                bottom: Radius.circular(16),
                              )
                            : null,
                  ),
                  child: Center(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose One',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _pickerOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                _pickerOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _pickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFEBEDFF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _green, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
    } catch (e) {
      _snack('Could not open ${source.name}: $e', error: true);
      return;
    }
    if (file == null || !mounted) return;
    setState(() => _uploadingImage = true);
    try {
      final url = await ref
          .read(evergreenRepositoryProvider)
          .uploadFile(file.path, folderName: 'equipment_info');
      if (mounted) setState(() => _imageUrl = url);
    } catch (e) {
      _snack('Image upload failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: error ? Colors.red.shade400 : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _saveEquipment() async {
    final name = _equipmentNameController.text.trim();
    if (name.isEmpty) {
      _snack('Please enter equipment name', error: true);
      return;
    }
    final edit = widget.editEquipment;
    final editId = int.tryParse('${edit?['id'] ?? ''}');
    if (widget.isEdit && editId == null) {
      _snack('Missing equipment id', error: true);
      return;
    }
    if (!widget.isEdit && _companyId == null) {
      _snack('Please select a company', error: true);
      return;
    }
    final year = int.tryParse(_selectedYear ?? '');
    // createEquipment always parses manufacturer_date.
    if (!widget.isEdit && year == null) {
      _snack('Please select the manufacturer year', error: true);
      return;
    }

    String? text(TextEditingController c) {
      final v = c.text.trim();
      return v.isEmpty ? null : v;
    }

    final make = text(_makeController);
    final model = text(_modelController);
    final frequency = _frequencyFor(_selectedFrequency);
    final status = widget.isEdit
        ? EquipmentStatusX.fromKey(edit?['status']?.toString())
        : EquipmentStatus.operational;
    final editType = edit?['type']?.toString().trim() ?? '';
    final type =
        widget.isEdit ? (editType.isEmpty ? null : editType) : (model ?? make);
    final installedAt = widget.isEdit
        ? DateTime.tryParse('${edit?['installedAt'] ?? ''}')
        : DateTime.now();

    final fields = <String, dynamic>{
      'name': name,
      'make': make,
      'model': model,
      // updateEquipment falls back to specifications when serial_number is
      // null, so always send a string.
      'serial_number': _serialNumberController.text.trim(),
      'location': text(_locationController),
      'description': text(_descriptionController),
      if (year != null)
        'manufacturer_date': DateTime.utc(year).toIso8601String(),
      if (frequency != null) 'tm_frequency': frequency.key,
      if (_imageUrl != null) 'image_url': _imageUrl,
      'status': status.condition.key,
      if (type != null) 'type': type,
      if (installedAt != null)
        'installed_at': installedAt.toUtc().toIso8601String(),
    };

    setState(() => _saving = true);
    try {
      final api = ref.read(equipmentApiProvider);
      if (widget.isEdit) {
        await api.update(editId!, fields);
      } else {
        await api.create({...fields, 'company_link': _companyId});
      }
      ref.invalidate(equipmentsProvider);
      ref.invalidate(equipmentInfoProvider);
      _snack(
        widget.isEdit
            ? 'Equipment updated successfully'
            : 'Equipment added successfully',
      );
      if (mounted) context.pop(true);
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
