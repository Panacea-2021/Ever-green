import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart' show IssueType;
import '../../data/task_provider.dart';
import '../../domain/models/task_item.dart';
import '../../../../web/widgets/web_form_kit.dart';
import '../widgets/task_workflow.dart';
import '../../../../core/theme/app_colors.dart';

/// Raise a ticket for a person rather than a company's equipment
/// (`user/createTask` without `equipment_link`). Super Admin / Manager only.
class CreateIndividualTaskScreen extends ConsumerStatefulWidget {
  const CreateIndividualTaskScreen({super.key});

  @override
  ConsumerState<CreateIndividualTaskScreen> createState() =>
      _CreateIndividualTaskScreenState();
}

class _CreateIndividualTaskScreenState
    extends ConsumerState<CreateIndividualTaskScreen> {
  static const Color _green = AppColors.primary;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  int? _issueTypeId;
  TaskPriority? _priority;

  /// Locally picked images (uploaded on save).
  final List<XFile> _selectedImages = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _resetForm() {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _nameController.clear();
      _phoneController.clear();
      _addressController.clear();
      _issueTypeId = null;
      _priority = null;
      _selectedImages.clear();
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    if (title.isEmpty) return _snack('Please enter a task title');
    if (name.isEmpty) return _snack('Please enter the person name');
    final phoneError = validateContactPhone(phone);
    if (phoneError != null) return _snack(phoneError);
    if (address.isEmpty) return _snack('Please enter the address');
    IssueType? issueType;
    for (final it
        in ref.read(issueTypesProvider).valueOrNull ?? const <IssueType>[]) {
      if (it.id == _issueTypeId) issueType = it;
    }

    final ok = await runTaskAction(
      context,
      () => ref.read(taskActionsProvider).createIndividual(
            name: title,
            description: _descriptionController.text.trim(),
            issueType: issueType,
            priority: _priority,
            contactName: name,
            contactPhone: normalizeContactPhone(phone),
            address: address,
            imageFiles: List.of(_selectedImages),
          ),
      success: 'Task created successfully',
    );
    if (ok && mounted) context.pop();
  }

  Future<void> _addImage(ImageSource source) async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 3 images allowed'),
          backgroundColor: _green,
        ),
      );
      return;
    }
    final image = await pickImageFrom(source);
    if (image != null && mounted) setState(() => _selectedImages.add(image));
  }

  Widget _issueTypeField() => _buildDropdownField<int>(
        label: 'Issue Type',
        value: _issueTypeId,
        items: [
          for (final it in ref.watch(issueTypesProvider).valueOrNull ??
              const <IssueType>[])
            (it.id, it.name),
        ],
        onChanged: (v) => setState(() => _issueTypeId = v),
      );

  Widget _priorityField() => _buildDropdownField<TaskPriority>(
        label: 'Priority',
        value: _priority,
        items: [for (final p in TaskPriority.values) (p, p.label)],
        onChanged: (v) => setState(() => _priority = v),
      );

  Widget _nameField() => _buildTextField(
        controller: _nameController,
        hintText: 'Person name *',
        textCapitalization: TextCapitalization.words,
      );

  Widget _phoneField() => _buildTextField(
        controller: _phoneController,
        hintText: 'Mobile number *',
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
          LengthLimitingTextInputFormatter(20),
        ],
      );

  Widget _addressField() => _buildTextField(
        controller: _addressController,
        hintText: 'Address *',
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
      );

  /// Web layout: centred task form with a top action bar.
  Widget _webBuild() {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F2),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6F9F6), Color(0xFFEDF4EE)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -150,
              right: -120,
              child: IgnorePointer(
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF73B980).withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -180,
              left: -140,
              child: IgnorePointer(
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF73B980).withValues(alpha: 0.06),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                _buildBottomButtons(webTop: true),
                Expanded(
                  child: WebForm.page(
                    [
                      WebForm.split(
                        _individualTaskSection(
                          icon: Icons.person_outline,
                          title: 'Contact Information',
                          subtitle: 'Who and where the work is for',
                          children: [
                            _nameField(),
                            const SizedBox(height: WebForm.gap),
                            _phoneField(),
                            const SizedBox(height: WebForm.gap),
                            _addressField(),
                          ],
                        ),
                        _individualTaskSection(
                          children: [
                            WebForm.row(_issueTypeField(), _priorityField()),
                            const SizedBox(height: WebForm.gap),
                            _buildTextField(
                              controller: _titleController,
                              hintText: 'Task title *',
                            ),
                            const SizedBox(height: WebForm.gap),
                            _buildTextField(
                              controller: _descriptionController,
                              hintText: 'Enter description',
                              maxLines: 4,
                            ),
                            const SizedBox(height: 20),
                            _buildImageUploadSection(),
                          ],
                        ),
                        leftFlex: 2,
                        rightFlex: 3,
                      ),
                    ],
                    maxWidth: 1120,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _individualTaskSection({
    IconData? icon,
    String? title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFCFEFC)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE7DE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF174A24).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE7F3E9), Color(0xFFD8EBDD)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF187333),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF14201A),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.black.withValues(alpha: 0.48),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFE2E8E3)),
            const SizedBox(height: 22),
          ],
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _webBuild();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      body: Stack(
        children: [
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
                if (!kIsWeb) _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildContactCard(),
                        const SizedBox(height: 16),
                        _buildDropdownField<int>(
                          label: 'Issue Type',
                          value: _issueTypeId,
                          items: [
                            for (final it
                                in ref.watch(issueTypesProvider).valueOrNull ??
                                    const <IssueType>[])
                              (it.id, it.name),
                          ],
                          onChanged: (v) => setState(() => _issueTypeId = v),
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField<TaskPriority>(
                          label: 'Priority',
                          value: _priority,
                          items: [
                            for (final p in TaskPriority.values) (p, p.label),
                          ],
                          onChanged: (v) => setState(() => _priority = v),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _titleController,
                          hintText: 'Task title *',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionController,
                          hintText: 'Enter description',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),
                        _buildImageUploadSection(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
                _buildBottomButtons(),
              ],
            ),
          ),
        ],
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
            icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
          ),
          const Text(
            'Create Individual Task',
            style: TextStyle(
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

  Widget _buildContactCard() {
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
          Container(
            width: 51,
            height: 51,
            decoration: const BoxDecoration(
              color: Color(0xFFDCEBDD),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: Color(0xFF278245),
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Contact Information',
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
            'Who and where the work is for',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.4),
              letterSpacing: -0.45,
            ),
          ),
          const SizedBox(height: 22),
          _buildTextField(
            controller: _nameController,
            hintText: 'Person name *',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 19),
          _buildTextField(
            controller: _phoneController,
            hintText: 'Mobile number *',
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
              LengthLimitingTextInputFormatter(20),
            ],
          ),
          const SizedBox(height: 19),
          _buildTextField(
            controller: _addressController,
            hintText: 'Address *',
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<(T, String)> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Material(
      color: Colors.white,
      elevation: kIsWeb ? 0 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: WebForm.fieldShape(32),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
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
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B6B6B)),
            items: [
              for (final item in items)
                DropdownMenuItem<T>(
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
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final radius = WebForm.radius(maxLines > 1 ? 24.0 : 32.0);
    return Material(
      color: Colors.white,
      elevation: kIsWeb ? 0 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: WebForm.fieldShape(radius),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        cursorColor: _green,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: hintText,
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
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: _green, width: 1.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => Container(
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
                _imagePickerOption(Icons.camera_alt, 'Camera', () {
                  Navigator.pop(sheet);
                  _addImage(ImageSource.camera);
                }),
                _imagePickerOption(Icons.photo_library, 'Gallery', () {
                  Navigator.pop(sheet);
                  _addImage(ImageSource.gallery);
                }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _imagePickerOption(IconData icon, String label, VoidCallback onTap) {
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

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showImagePickerDialog,
          child: Container(
            width: double.infinity,
            height: 169,
            decoration: kIsWeb
                ? WebForm.uploadDecoration()
                : BoxDecoration(
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
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) => Container(
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
                        onTap: () =>
                            setState(() => _selectedImages.removeAt(index)),
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
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomButtons({bool webTop = false}) {
    final buttons = Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _resetForm,
            child: Container(
              height: kIsWeb ? 40 : 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kIsWeb ? const Color(0xFFF4F8F4) : Colors.white,
                borderRadius: BorderRadius.circular(kIsWeb ? 12 : 32),
                border: Border.all(
                  color: kIsWeb
                      ? const Color(0xFFD5E3D7)
                      : const Color(0x80155622),
                ),
              ),
              child: kIsWeb
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded,
                            size: 16, color: Color(0xFF416B49)),
                        SizedBox(width: 6),
                        Text(
                          'Reset',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF416B49),
                          ),
                        ),
                      ],
                    )
                  : const Text(
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
        SizedBox(width: kIsWeb ? 10 : 16),
        Expanded(
          child: GestureDetector(
            onTap: _save,
            child: Container(
              height: kIsWeb ? 40 : 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kIsWeb ? const Color(0xFF106220) : null,
                gradient: kIsWeb
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF138A2A), _green],
                      ),
                borderRadius: BorderRadius.circular(kIsWeb ? 12 : 32),
                boxShadow: kIsWeb
                    ? [
                        BoxShadow(
                          color: _green.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: kIsWeb
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded,
                            size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Save',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : const Text(
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
    );

    return Container(
      padding: kIsWeb
          ? WebForm.barPadding
          : const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: kIsWeb
          ? webTop
              ? const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: WebForm.line)),
                )
              : WebForm.barDecoration
          : const BoxDecoration(color: Colors.white),
      child: SafeArea(
        top: false,
        child: kIsWeb
            ? Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 300,
                  child: buttons,
                ),
              )
            : buttons,
      ),
    );
  }
}
