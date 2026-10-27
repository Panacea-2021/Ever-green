import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart' hide TaskStatus;
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../pickers/presentation/screens/company_picker_screen.dart';
import '../../../pickers/presentation/screens/equipment_picker_screen.dart';
import '../../../tasks/data/task_provider.dart';
import '../../../tasks/domain/models/task_item.dart';
import '../../../tasks/presentation/widgets/task_workflow.dart';

/// Raise a ticket (`user/createTask`) or edit one (`user/updateTask`).
///
/// Company and equipment come from the backend; client roles are limited to
/// their own companies (and locked when they have just one). The backend
/// generates the ticket number. Images are uploaded to the `tasks` folder
/// first and sent as URLs (new tickets only; the update API has no images).
class AddTaskScreen extends ConsumerStatefulWidget {
  /// Backend company id to preselect (non-numeric values are ignored).
  final String companyId;
  final String? companyName;

  /// When opened from an equipment's detail screen, the equipment to
  /// pre-select by name.
  final String? preselectEquipment;

  /// Kept for callers; specs now come from the selected backend equipment.
  final Map<String, String>? preselectEquipmentSpecs;

  /// Edit mode: `{'taskId': <backend task id>}`.
  final Map<String, dynamic>? editTask;

  /// Whether this is edit mode
  final bool isEdit;

  const AddTaskScreen({
    super.key,
    required this.companyId,
    this.companyName,
    this.preselectEquipment,
    this.preselectEquipmentSpecs,
    this.editTask,
    this.isEdit = false,
  });

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  /// Selected company name; each backend company row is one branch of it.
  String? _companyName;

  /// Selected branch (backend company id).
  int? _companyId;
  int? _equipmentId;
  CallType? _callType;
  final _locationController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  /// Locally picked image paths (uploaded on save).
  final List<String> _selectedImages = [];

  bool _prefilledEdit = false;
  bool _preselectedEquipment = false;

  String? get _editTaskId => widget.editTask?['taskId']?.toString();

  @override
  void initState() {
    super.initState();
    _companyId = int.tryParse(widget.companyId);
  }

  @override
  void dispose() {
    _locationController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  TaskItem? _editingTask(List<TaskItem> tasks) {
    final id = _editTaskId;
    if (!widget.isEdit || id == null) return null;
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  void _prefillFrom(TaskItem t) {
    _prefilledEdit = true;
    _companyId = t.companyId ?? _companyId;
    _equipmentId = t.equipmentId;
    _callType = t.callType;
    _subjectController.text = t.source?.name ?? t.title;
    _descriptionController.text = t.description;
  }

  void _showImagePickerDialog() {
    if (widget.isEdit) {
      _snack('Images can only be attached when raising a task');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Upload Image',
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
                _buildImagePickerOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _addImage(ImageSource.camera);
                  },
                ),
                _buildImagePickerOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _addImage(ImageSource.gallery);
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

  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF106220),
              size: 28,
            ),
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

  Future<void> _addImage(ImageSource source) async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 3 images allowed'),
          backgroundColor: Color(0xFF106220),
        ),
      );
      return;
    }
    final path = await pickImageFrom(source);
    if (path != null && mounted) setState(() => _selectedImages.add(path));
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _resetForm() {
    setState(() {
      if (!_companyLocked) {
        _companyName = null;
        _companyId = null;
        _locationController.clear();
      }
      _equipmentId = null;
      _callType = null;
      _subjectController.clear();
      _descriptionController.clear();
      _selectedImages.clear();
    });
  }

  bool _companyLocked = false;

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _saveTask(TaskItem? editing) async {
    final subject = _subjectController.text.trim();
    if (_companyName == null) return _snack('Please select a company');
    if (_companyId == null) return _snack('Please select a branch');
    if (_equipmentId == null) return _snack('Please select equipment');
    if (_callType == null) return _snack('Please choose an issue type');
    if (subject.isEmpty) return _snack('Please enter a subject');

    final actions = ref.read(taskActionsProvider);
    final description = _descriptionController.text.trim();
    final bool ok;
    if (widget.isEdit) {
      if (editing == null) return _snack('This task is no longer available');
      ok = await runTaskAction(
        context,
        () => actions.update(
          editing,
          name: subject,
          description: description,
          callType: _callType,
          equipmentId: _equipmentId,
        ),
        success: 'Task updated successfully',
      );
    } else {
      final user = ref.read(currentUserProvider);
      if (user == null) return _snack('Please sign in again');
      ok = await runTaskAction(
        context,
        () => actions.create(
          equipmentId: _equipmentId!,
          name: subject,
          description: description,
          callType: _callType!,
          clientId: user.backendId,
          imagePaths: List.of(_selectedImages),
        ),
        success: 'Task created successfully',
      );
    }
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(currentUserRoleProvider);
    final tasksAsync = ref.watch(taskItemsProvider);
    final editing = _editingTask(tasksAsync.valueOrNull ?? const []);
    if (editing != null && !_prefilledEdit) _prefillFrom(editing);

    // Client roles may only raise tickets for their own companies.
    var companies = ref.watch(companiesProvider);
    final ownIds = user?.companies.map((c) => c.id).toSet() ?? const <int>{};
    _allowedCompanyIds =
        role.isClientSide && ownIds.isNotEmpty ? ownIds : null;
    if (role.isClientSide && ownIds.isNotEmpty) {
      companies = companies.whenData(
        (list) => list.where((c) => ownIds.contains(c.id)).toList(),
      );
    }
    final companyList = companies.valueOrNull ?? const <Company>[];
    _companyLocked = role.isClientSide && companyList.length == 1;
    if (_companyLocked && _companyId != companyList.first.id) {
      _companyId = companyList.first.id;
      _equipmentId = null;
    }
    Company? selectedCompany;
    for (final c in companyList) {
      if (c.id == _companyId) selectedCompany = c;
    }
    if (selectedCompany != null) {
      _companyName ??= selectedCompany.name;
      final loc = selectedCompany.location ?? '';
      if (_locationController.text != loc) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _locationController.text = loc;
        });
      }
    } else if (_companyName == null && companyList.isNotEmpty) {
      final pre = widget.companyName?.trim().toLowerCase();
      if (pre != null && pre.isNotEmpty) {
        for (final c in companyList) {
          if (c.name.toLowerCase() == pre) _companyName = c.name;
        }
      }
    }

    final equipments =
        _companyId == null ? null : ref.watch(equipmentsProvider(_companyId));
    final equipmentList = equipments?.valueOrNull ?? const <Equipment>[];
    final preEquip = widget.preselectEquipment?.trim().toLowerCase();
    if (!_preselectedEquipment &&
        _equipmentId == null &&
        preEquip != null &&
        preEquip.isNotEmpty &&
        equipmentList.isNotEmpty) {
      _preselectedEquipment = true;
      for (final e in equipmentList) {
        if (e.name.toLowerCase() == preEquip) _equipmentId = e.id;
      }
    }
    Equipment? selectedEquipment;
    for (final e in equipmentList) {
      if (e.id == _equipmentId) selectedEquipment = e;
    }

    final waitingForEdit = widget.isEdit &&
        editing == null &&
        tasksAsync.isLoading &&
        !tasksAsync.hasValue;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      body: Stack(
        children: [
          // Same patterned background treatment as the Home screen.
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/images/home_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Form Content
                Expanded(
                  child: waitingForEdit
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF106220)),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Task Information Card
                              _buildTaskInformationCard(
                                companies,
                                _companyLocked,
                                equipments,
                                selectedEquipment,
                              ),

                              const SizedBox(height: 16),

                              // Issue Type Dropdown
                              _buildInlineDropdownField<CallType>(
                                label: 'Issue Type',
                                value: _callType,
                                items: [for (final c in CallType.values) (c, c.label)],
                                onChanged: (value) => setState(() => _callType = value),
                              ),

                              const SizedBox(height: 16),

                              // Subject Field
                              _buildTextField(
                                label: 'Subject',
                                controller: _subjectController,
                                hintText: 'Enter subject',
                              ),

                              const SizedBox(height: 16),

                              // Description Field
                              _buildTextField(
                                label: 'Description',
                                controller: _descriptionController,
                                hintText: 'Enter description',
                                maxLines: 4,
                              ),

                              const SizedBox(height: 16),

                              // Image Upload Section
                              _buildImageUploadSection(),

                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                ),

                // Bottom Buttons
                _buildBottomButtons(editing),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Companies a client role may pick from (null = all).
  Set<int>? _allowedCompanyIds;

  Widget _companyField(AsyncValue<List<Company>> companies, bool locked) {
    if (!companies.hasValue) {
      return _statusField(
        companies.hasError ? 'Couldn\'t load companies — tap to retry' : 'Loading companies…',
        onTap: companies.hasError ? () => ref.invalidate(companiesProvider) : null,
      );
    }
    return _pickerField(
      label: 'Company',
      value: _companyName,
      onTap: locked ? null : _pickCompany,
    );
  }

  Future<void> _pickCompany() async {
    final picked = await CompanyPickerScreen.open(
      context,
      selectedId: _companyId,
      allowedIds: _allowedCompanyIds,
    );
    if (picked == null || !mounted || picked.id == _companyId) return;
    setState(() {
      _companyName = picked.name;
      _companyId = picked.id;
      _equipmentId = null;
      _locationController.text = picked.location ?? '';
    });
  }

  Future<void> _pickEquipment() async {
    final companyId = _companyId;
    if (companyId == null) return;
    final picked = await EquipmentPickerScreen.open(
      context,
      companyId: companyId,
      selectedId: _equipmentId,
    );
    if (picked == null || !mounted) return;
    setState(() => _equipmentId = picked.id);
  }

  /// A pill field that opens a full-page picker; greyed out when [onTap] is
  /// null.
  Widget _pickerField({
    required String label,
    required String? value,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? Colors.white : const Color(0xFFF4F4F4),
      elevation: enabled ? 2 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? label,
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
                Icons.chevron_right,
                color: enabled
                    ? const Color(0xFF6B6B6B)
                    : Colors.black.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _branchDropdown(AsyncValue<List<Company>> companies, bool locked) {
    final branches = (companies.valueOrNull ?? const <Company>[])
        .where((c) => c.name == _companyName)
        .toList();
    return _buildInlineDropdownField<int>(
      label: 'Branch',
      value: _companyId,
      items: [
        for (final c in branches)
          (c.id, c.branchName.isEmpty ? c.displayName : c.branchName),
      ],
      onChanged: locked || _companyName == null
          ? null
          : (value) => setState(() {
                if (value != _companyId) _equipmentId = null;
                _companyId = value;
              }),
    );
  }

  Widget _buildInlineTextField({
    required String label,
    required TextEditingController controller,
  }) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(32),
      child: TextField(
        controller: controller,
        readOnly: true,
        cursorColor: const Color(0xFF106220),
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black.withValues(alpha: 0.4),
          ),
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
            borderSide: const BorderSide(color: Color(0xFF106220), width: 1.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _equipmentField(
    AsyncValue<List<Equipment>>? equipments,
    Equipment? selected,
  ) {
    if (equipments == null) {
      return _pickerField(
        label: 'Equipment (select a company first)',
        value: null,
        onTap: null,
      );
    }
    if (equipments.hasError && !equipments.hasValue) {
      return _statusField(
        'Couldn\'t load equipment — tap to retry',
        onTap: () => ref.invalidate(equipmentsProvider(_companyId)),
      );
    }
    final e = selected;
    return _pickerField(
      label: 'Equipment',
      value: e == null
          ? null
          : e.egSerialNumber.isEmpty
              ? e.name
              : '${e.name} (${e.egSerialNumber})',
      onTap: _pickEquipment,
    );
  }

  Widget _statusField(String text, {VoidCallback? onTap}) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black87,
              size: 24,
            ),
          ),
          Text(
            widget.isEdit ? 'Edit Task' : 'Add Task',
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

  Widget _buildTaskInformationCard(
    AsyncValue<List<Company>> companies,
    bool lockCompany,
    AsyncValue<List<Equipment>>? equipments,
    Equipment? selectedEquipment,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
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
      child: Column(
        children: [
          // Circular green icon badge (matches Figma).
          Container(
            width: 51,
            height: 51,
            decoration: const BoxDecoration(
              color: Color(0xFFDCEBDD),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_box_outlined,
              color: Color(0xFF278245),
              size: 26,
            ),
          ),

          const SizedBox(height: 14),

          // Title
          const Text(
            'Task Information',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.54,
            ),
          ),

          const SizedBox(height: 6),

          // Subtitle
          Text(
            'Provide basic details of the Task',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.4),
              letterSpacing: -0.45,
            ),
          ),

          const SizedBox(height: 22),

          _companyField(companies, lockCompany),

          const SizedBox(height: 19),

          // Branch Dropdown
          _branchDropdown(companies, lockCompany),

          const SizedBox(height: 19),

          // Location Field
          _buildInlineTextField(
            label: 'Location',
            controller: _locationController,
          ),

          const SizedBox(height: 19),

          _equipmentField(equipments, selectedEquipment),

          // Equipment Specifications (shown when equipment is selected)
          if (selectedEquipment != null) ...[
            const SizedBox(height: 16),
            _buildEquipmentSpecifications(selectedEquipment),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineDropdownField<T>({
    required String label,
    required T? value,
    required List<(T, String)> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: items.any((e) => e.$1 == value) ? value : null,
            hint: Text(
              label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
            isExpanded: true,
            borderRadius: BorderRadius.circular(16),
            icon: const Icon(
              Icons.arrow_drop_down,
              color: Color(0xFF6B6B6B),
            ),
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item.$1,
                child: Text(
                  item.$2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentSpecifications(Equipment e) {
    String v(String? s) => (s == null || s.isEmpty) ? '-' : s;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF106220).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Equipment Specifications',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF106220),
            ),
          ),
          const SizedBox(height: 12),

          // Specs in two columns
          Row(
            children: [
              Expanded(child: _buildSpecItem('Make', v(e.make))),
              const SizedBox(width: 16),
              Expanded(child: _buildSpecItem('Model', v(e.model))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildSpecItem('S.No', v(e.serialNumber))),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSpecItem(
                  'Mfg.Year',
                  v(e.manufacturerDate?.year.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSpecItem('Maintainance Frequency', v(e.tmFrequency?.label)),
          const SizedBox(height: 8),
          _buildSpecItem('EG Serial Number', v(e.egSerialNumber)),
          const SizedBox(height: 8),
          _buildSpecItem('Description', v(e.description ?? e.specifications)),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Row(
      children: [
        Text(
          '$label : ',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    int maxLines = 1,
  }) {
    final radius = maxLines > 1 ? 24.0 : 32.0;
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(radius),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        cursorColor: const Color(0xFF106220),
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: hintText ?? label,
          hintStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black.withValues(alpha: 0.4),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: Color(0xFF106220), width: 1.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lavender upload block (matches Figma).
        GestureDetector(
          onTap: _showImagePickerDialog,
          child: Container(
            width: double.infinity,
            height: 169,
            decoration: BoxDecoration(
              color: const Color(0xFFEBEDFF),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    color: Colors.black.withValues(alpha: 0.55),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Please upload your image here',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jpg,Png upto 5MB (Max 3 images)',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Selected image thumbnails (dashed-style tile with a cross).
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: localImageThumb(_selectedImages[index], size: 88),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD32F2F),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomButtons(TaskItem? editing) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(color: Colors.white),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Reset Button (outlined pill)
            Expanded(
              child: GestureDetector(
                onTap: _resetForm,
                child: Container(
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: const Color(0x80155622),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0E501B),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

          // Save Button (green gradient pill, matches Figma)
          Expanded(
            child: GestureDetector(
              onTap: () => _saveTask(editing),
              child: Container(
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF138A2A), Color(0xFF106220)],
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
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
}
