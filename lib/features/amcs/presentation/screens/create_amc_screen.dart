import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../audit/data/audit_logger.dart';
import '../../../audit/domain/models/audit_log_entry.dart';
import '../../data/amc_provider.dart';
import '../../domain/models/amc_contract.dart';

class CreateAmcScreen extends ConsumerStatefulWidget {
  /// When provided, the screen runs in "edit" mode: the title reads
  /// "Update Company", the fields are pre-filled from the company, and the
  /// primary button calls `user/updateCompany/:id`.
  /// Keys: `company` ([Company]) and/or `companyId` (int or String).
  final Map<String, dynamic>? editCompany;

  const CreateAmcScreen({super.key, this.editCompany});

  bool get isEdit => editCompany != null;

  @override
  ConsumerState<CreateAmcScreen> createState() => _CreateAmcScreenState();
}

class _CreateAmcScreenState extends ConsumerState<CreateAmcScreen> {
  final _formKey = GlobalKey<FormState>();

  static final RegExp _gstPattern =
      RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');
  static final RegExp _mobilePattern = RegExp(r'^(\+\d{1,3}[- ]?)?\d{10}$');

  // Company Information
  final _companyController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _gstController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  // Service classification.
  CompanyServiceType _serviceType = CompanyServiceType.amc;
  AmcType? _amcType;

  /// Only AMC companies carry an AMC type and a contract date range.
  bool get _isAmc => _serviceType == CompanyServiceType.amc;

  // Client Details
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _saving = false;

  /// Newly picked local logo file (uploaded on save).
  String? _selectedImagePath;

  /// Logo already stored on the company (edit mode).
  String? _existingLogo;

  Company? _company;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _company = _resolveCompany();
      _applyEditData();
    }
  }

  Company? _resolveCompany() {
    final d = widget.editCompany!;
    final given = d['company'];
    if (given is Company) return given;
    final id = int.tryParse('${d['companyId'] ?? ''}');
    if (id == null) return null;
    final companies = ref.read(companiesProvider).valueOrNull ?? const [];
    for (final c in companies) {
      if (c.id == id) return c;
    }
    return null;
  }

  void _applyEditData() {
    final c = _company;
    if (c == null) return;
    _companyController.text = c.name;
    _branchNameController.text = c.branchName;
    _companyEmailController.text = c.email;
    _gstController.text = c.gstNumber ?? '';
    _addressController.text = c.location ?? '';
    _nameController.text = c.poc?.name ?? '';
    _mobileController.text = c.poc?.phone ?? '';
    _emailController.text = c.pocEmail ?? '';
    _passwordController.clear();
    _serviceType = c.serviceType ?? CompanyServiceType.amc;
    _amcType = c.isAmc ? c.amcType : null;
    _startDate = c.isAmc ? c.amcStartDay : null;
    _endDate = c.isAmc ? c.amcEndDay : null;
    _existingLogo = c.logo;
    _selectedImagePath = null;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _branchNameController.dispose();
    _companyEmailController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final now = DateTime.now();
    final current = isStartDate ? _startDate : _endDate;
    final first =
        isStartDate || _startDate == null ? DateTime(2000) : _startDate!;
    var initial = current ?? (isStartDate ? now : (_startDate ?? now));
    if (initial.isBefore(first)) initial = first;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) => date == null ? '' : displayDate(date);

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFD32F2F)),
    );
  }

  /// Mirrors the backend's createCompany / updateCompany validation so the
  /// user gets the message before a round trip.
  String? _validate() {
    final name = _companyController.text.trim();
    final branch = _branchNameController.text.trim();
    final gst = _gstController.text.trim().toUpperCase();
    final address = _addressController.text.trim();
    if (name.isEmpty) return 'Please enter company name';
    if (branch.isEmpty) return 'Please enter branch name';
    if (!widget.isEdit && address.isEmpty) {
      return 'Please enter company address';
    }
    if ((!widget.isEdit || gst.isNotEmpty) && !_gstPattern.hasMatch(gst)) {
      return 'Please enter a valid GST number';
    }
    if (_isAmc) {
      if (_amcType == null) {
        return 'Please select an AMC category (NC AMC or C AMC)';
      }
      if (_startDate == null || _endDate == null) {
        return 'AMC contracts require a start and end date';
      }
      if (_endDate!.isBefore(_startDate!)) {
        return 'End date must be after the start date';
      }
    }

    final admin = [
      _nameController.text.trim(),
      _mobileController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
    ];
    final anyAdmin = admin.any((v) => v.isNotEmpty);
    final hasLinkedAdmin = _company?.poc != null;
    if (anyAdmin && !hasLinkedAdmin && admin.any((v) => v.isEmpty)) {
      return 'Please provide all client admin details or leave them all empty';
    }
    if (admin[1].isNotEmpty && !_mobilePattern.hasMatch(admin[1])) {
      return 'Please enter valid mobile number';
    }
    if (admin[3].length > 20) {
      return 'Password must be at most 20 characters';
    }
    return null;
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    if (widget.isEdit && _company == null) {
      _showError('Company not found. Go back and try again.');
      return;
    }
    final error = _validate();
    if (error != null) {
      _showError(error);
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(amcRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final company = _companyController.text.trim();
    final branch = _branchNameController.text.trim();
    final original = _company;

    // On edit, only send client admin fields that changed so an unchanged
    // POC isn't rewritten (and the password stays as-is when left blank).
    String changed(String value, String? before) =>
        original != null && value.trim() == (before ?? '').trim() ? '' : value;

    try {
      String? logo;
      if (_selectedImagePath != null) {
        logo = await repo.uploadLogo(_selectedImagePath!);
      }

      final input = CompanyInput(
        name: company,
        branchName: branch,
        email: _companyEmailController.text,
        gstNumber: _gstController.text,
        address: _addressController.text,
        serviceType: _serviceType,
        amcType: _isAmc ? _amcType : null,
        startDate: _isAmc ? _startDate : null,
        endDate: _isAmc ? _endDate : null,
        logo: logo,
        adminName: changed(_nameController.text, original?.poc?.name),
        adminPhone: changed(_mobileController.text, original?.poc?.phone),
        adminEmail: changed(_emailController.text, original?.pocEmail),
        adminPassword: _passwordController.text,
      );

      if (original != null) {
        await repo.updateCompany(original.id, input);
      } else {
        await repo.createCompany(input);
      }
      ref.invalidate(companiesProvider);

      ref.logAudit(
        action: original != null ? AuditAction.updated : AuditAction.created,
        entity: AuditEntity.amc,
        entityName: company,
        details:
            original != null ? 'Company details updated' : 'Branch: $branch',
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            original != null
                ? 'Company updated successfully!'
                : 'Company created successfully!',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showError('$e');
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file != null && mounted) {
        setState(() => _selectedImagePath = file.path);
      }
    } catch (e) {
      if (mounted) _showError('Could not pick image: $e');
    }
  }

  void _handleImageUpload() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Upload Company Image',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            if (!kIsWeb)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.photo_library, color: AppColors.primary),
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
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
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildCompanyInfoCard(),
                            const SizedBox(height: 20),
                            _buildClientDetailsCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomButtons(),
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
          Text(
            widget.isEdit ? 'Update Company' : 'Create Company',
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

  // Pill-shaped text field with soft shadow (matches Figma)
  Widget _pillField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(32),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        obscureText: isPassword && !_isPasswordVisible,
        cursorColor: AppColors.primary,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 15,
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
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.black.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // Pill-shaped dropdown matching the text fields.
  Widget _pillDropdown({
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
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            borderRadius: BorderRadius.circular(16),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.black.withValues(alpha: 0.55),
            ),
            hint: Text(
              hint,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
            items: items
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(
                      e,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  // Pill-shaped date field with calendar icon
  Widget _pillDateField({
    required String hint,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
                  value.isEmpty ? hint : value,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: value.isEmpty
                        ? Colors.black.withValues(alpha: 0.4)
                        : Colors.black,
                  ),
                ),
              ),
              Icon(
                Icons.calendar_month,
                size: 22,
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyInfoCard() {
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: Column(
          children: [
            // Company Icon - Green circle with building icon
            Container(
              width: 51,
              height: 51,
              decoration: const BoxDecoration(
                color: Color(0xFFDCEBDD),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.apartment,
                size: 26,
                color: Color(0xFF278245),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Company Information',
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
              'Provide basic details of the company',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black.withValues(alpha: 0.4),
                letterSpacing: -0.45,
              ),
            ),
            const SizedBox(height: 22),

            _pillField(controller: _companyController, hint: 'Company Name'),
            const SizedBox(height: 19),
            _pillField(controller: _branchNameController, hint: 'Branch Name'),
            const SizedBox(height: 19),
            _pillField(
              controller: _companyEmailController,
              hint: 'Company Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 19),
            _pillField(
              controller: _gstController,
              hint: 'GST Number',
              capitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 19),
            _pillField(
              controller: _addressController,
              hint: 'Company Address',
              keyboardType: TextInputType.streetAddress,
            ),
            const SizedBox(height: 19),

            // Service Type dropdown (AMC / Non-AMC / Regular).
            _pillDropdown(
              hint: 'Service Type',
              value: _serviceType.label,
              items: [for (final t in CompanyServiceType.values) t.label],
              onChanged: (v) {
                final type = CompanyServiceType.values
                    .where((t) => t.label == v)
                    .firstOrNull;
                if (type == null) return;
                setState(() {
                  _serviceType = type;
                  // AMC type and dates only apply to AMC.
                  if (!_isAmc) {
                    _amcType = null;
                    _startDate = null;
                    _endDate = null;
                  }
                });
              },
            ),

            // AMC type + contract dates only apply to AMC.
            if (_isAmc) ...[
              const SizedBox(height: 19),
              _pillDropdown(
                hint: 'AMC Category (NC AMC / C AMC)',
                value: _amcType?.label,
                items: [AmcType.ncAmc.label, AmcType.cAmc.label],
                onChanged: (v) => setState(
                  () => _amcType =
                      AmcType.values.where((t) => t.label == v).firstOrNull,
                ),
              ),
              const SizedBox(height: 19),
              _pillDateField(
                hint: 'Start Date',
                value: _formatDate(_startDate),
                onTap: () => _selectDate(context, true),
              ),
              const SizedBox(height: 19),
              _pillDateField(
                hint: 'End Date',
                value: _formatDate(_endDate),
                onTap: () => _selectDate(context, false),
              ),
            ],
            const SizedBox(height: 19),

            _buildImageUploadArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildClientDetailsCard() {
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: Column(
          children: [
            // Client icon - green circle
            Container(
              width: 51,
              height: 51,
              decoration: const BoxDecoration(
                color: Color(0xFFDCEBDD),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                size: 26,
                color: Color(0xFF278245),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Client Details',
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
              'Enter primary contact details',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black.withValues(alpha: 0.4),
                letterSpacing: -0.45,
              ),
            ),
            const SizedBox(height: 22),

            _pillField(controller: _nameController, hint: 'Name'),
            const SizedBox(height: 19),
            _pillField(
              controller: _mobileController,
              hint: 'Mobile Number',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 19),
            _pillField(
              controller: _emailController,
              hint: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 19),
            _pillField(
              controller: _passwordController,
              hint: 'Password',
              isPassword: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadArea() {
    return GestureDetector(
      onTap: _handleImageUpload,
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFFEBEDFF),
          borderRadius: BorderRadius.circular(16),
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
              child: Center(
                child: _selectedImagePath != null || _existingLogo != null
                    ? const Icon(
                        Icons.check_circle,
                        color: Color(0xFF6366F1),
                        size: 24,
                      )
                    : Icon(
                        Icons.cloud_upload_outlined,
                        color: Colors.black.withValues(alpha: 0.55),
                        size: 24,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedImagePath != null || _existingLogo != null
                  ? 'Image Selected'
                  : 'Please upload Company image here',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedImagePath?.split(RegExp(r'[/\\]')).last ??
                  'Jpg,Png upto 5MB',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildBottomButtons() {
    final showBulkUpload = !widget.isEdit &&
        Permissions.canBulkUpload(ref.watch(currentUserRoleProvider));
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (showBulkUpload) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push(Routes.uploadAmc),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: const Color(0x80155622),
                        width: 1,
                      ),
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
            // Save Button (gradient)
            Expanded(
              child: GestureDetector(
                onTap: _saving ? null : _handleSave,
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF138A2A), Color(0xFF106220)],
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
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
}
