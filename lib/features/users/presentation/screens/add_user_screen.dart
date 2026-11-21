import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../core/data/evergreen_repository.dart' as repo;
import '../../../../core/models/backend_models.dart';
import 'select_amc_screen.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/password_generator.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../../features/users/data/user_provider.dart';
import '../../data/users_repository.dart';

class AddUserScreen extends ConsumerStatefulWidget {
  const AddUserScreen({super.key});

  @override
  ConsumerState<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends ConsumerState<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: generatePassword());
  final _companyController = TextEditingController();

  UserRole? _selectedRole;
  int? _selectedCompanyId;
  bool _isPasswordVisible = true;
  bool _sendCredentials = true;
  bool _isSaving = false;

  static const Color _green = Color(0xFF106220);

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  /// Only a super admin may create another super admin; client admins only
  /// manage their own company's client users.
  List<UserRole> _creatableRoles(UserRole actor) => UserRole.values.where((r) {
        if (actor == UserRole.clientAdmin) return r == UserRole.client;
        return r != UserRole.superAdmin || actor == UserRole.superAdmin;
      }).toList();

  /// Client-side users must belong to an AMC (company); technicians never do.
  bool get _needsCompany => _selectedRole?.isClientSide ?? false;

  /// Company/AMC selection is hidden for Super Admin, EG Manager and
  /// Technician/Service Engineer roles.
  bool get _hideCompanyField =>
      _selectedRole == UserRole.superAdmin ||
      _selectedRole == UserRole.manager ||
      (_selectedRole?.isTechnicianLevel ?? false);

  Future<void> _handleSave() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    final role = _selectedRole ?? UserRole.client;

    if (_needsCompany && (_selectedCompanyId == null || _selectedCompanyId! <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a company.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final result = await ref.read(usersRepositoryProvider).createUser(
          name: _nameController.text.trim(),
          phone: _mobileController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: role,
          companyIds:
              _selectedCompanyId != null ? [_selectedCompanyId!] : const [],
          sendCredentials: _sendCredentials,
          designation: null,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.displayMessage),
          backgroundColor: AppColors.error,
        ),
      ),
      (message) {
        ref.invalidate(usersListProvider);
        if (role.isTechnicianLevel) ref.invalidate(repo.techniciansProvider);
        final emailFailed = message.contains('could not be sent');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User created successfully'),
            backgroundColor: _green,
          ),
        );
        if (emailFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'User created, but the login email could not be sent',
              ),
              backgroundColor: Colors.orange.shade800,
            ),
          );
        }
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _buildWebScaffold();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildFormCard(),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildWebScaffold() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = 16.0;
                  final formWidth =
                      (constraints.maxWidth - horizontalPadding * 2)
                          .clamp(0.0, 1100.0)
                          .toDouble();
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      8,
                      horizontalPadding,
                      20,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: formWidth,
                        child: _buildFormCard(),
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildWebBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => context.pop(),
          ),
          const Text(
            'Add User',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    final actorRole = ref.watch(currentUserRoleProvider);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_ind,
                  color: _green,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'User Information',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Provide basic details of the User',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nameController,
                hintText: 'Name',
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter name'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _mobileController,
                hintText: 'Mobile Number',
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter mobile number';
                  }
                  if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                    return 'Mobile number must be 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                hintText: 'Email ID',
                keyboardType: TextInputType.emailAddress,
                validator: (value) => Validators.email(value?.trim()),
              ),
              const SizedBox(height: 16),
              if (kIsWeb) ...[
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    if (value.length < 6 || value.length > 20) {
                      return 'Password must be 6 to 20 characters';
                    }
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: const Key('regeneratePassword'),
                    onPressed: () => setState(
                      () => _passwordController.text = generatePassword(),
                    ),
                    icon: const Icon(
                      Icons.autorenew,
                      size: 18,
                      color: _green,
                    ),
                    label: const Text(
                      'Generate new password',
                      style: TextStyle(fontFamily: 'Montserrat', color: _green),
                    ),
                  ),
                ),
              ],
              CheckboxListTile(
                key: const Key('sendCredentialsCheckbox'),
                value: _sendCredentials,
                onChanged: (v) => setState(() => _sendCredentials = v ?? false),
                activeColor: _green,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Send the user these login details by email',
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              _buildDropdownField<UserRole?>(
                value: _selectedRole,
                hintText: 'Access Type',
                items: {
                  for (final r in _creatableRoles(actorRole)) r: r.label,
                },
                validator: (v) =>
                    _selectedRole == null ? 'Please select access type' : null,
                onChanged: (value) => setState(() {
                  _selectedRole = value;
                  if (value == UserRole.superAdmin ||
                      value == UserRole.manager ||
                      (value?.isTechnicianLevel ?? false)) {
                    _selectedCompanyId = null;
                    _companyController.clear();
                  }
                }),
              ),
              if (!_hideCompanyField) ...[
                const SizedBox(height: 16),
                _buildCompanyField(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Assign client users to an AMC, or optionally link technicians to an
  /// allocated site. Technician links are informational assignment metadata.
  Widget _buildCompanyField() {
    final companiesAsync = ref.watch(repo.companiesProvider);
    final companies = [...companiesAsync.valueOrNull ?? const <Company>[]]
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () async {
            final selected = await context.push<Company>(Routes.selectAmc);
            if (selected != null && mounted) {
              setState(() {
                _selectedCompanyId = selected.id;
                _companyController.text = selected.displayName;
              });
            }
          },
          child: AbsorbPointer(
            child: Autocomplete<Company>(
              displayStringForOption: (c) => c.displayName,
              optionsBuilder: (textEditingValue) => const <Company>[],
              onSelected: (_) {},
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            // Keep our controller in sync with the autocomplete controller.
            if (controller.text != _companyController.text &&
                !_companyController.selection.isValid) {
              _companyController.text = controller.text;
            }
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              onChanged: (v) {
                _companyController.text = v;
                // Clear selection if user edits the text.
                if (_selectedCompanyId != null &&
                    v.trim() != companies
                        .firstWhere(
                          (c) => c.id == _selectedCompanyId,
                          orElse: () => companies.first,
                        )
                        .displayName) {
                  setState(() => _selectedCompanyId = null);
                }
              },
              validator: (v) => _needsCompany && _selectedCompanyId == null
                  ? 'Please select a company.'
                  : null,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: _selectedRole?.isTechnicianLevel == true
                    ? 'Allocated Site (optional)'
                    : 'Search and select AMC',
                hintStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade400,
                ),
                filled: true,
                fillColor: kIsWeb ? Colors.white : Colors.grey.shade50,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    color: kIsWeb ? Color(0xFFDCE5DE) : Colors.transparent,
                  ),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    color: kIsWeb ? Color(0xFFDCE5DE) : Colors.transparent,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: _green,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: kIsWeb ? 14 : 16,
                ),
                suffixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade600,
                ),
              ),
            );
          },
        ),
        ),
      ),
        if (companiesAsync.hasError)
          TextButton.icon(
            onPressed: () => ref.invalidate(repo.companiesProvider),
            icon: const Icon(Icons.refresh, size: 16, color: AppColors.error),
            label: const Text(
              'Could not load AMCs. Retry',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword && !_isPasswordVisible,
      validator: validator,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.grey.shade400,
        ),
        filled: true,
        fillColor: kIsWeb ? Colors.white : Colors.grey.shade50,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(
            color: kIsWeb ? Color(0xFFDCE5DE) : Colors.transparent,
          ),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(
            color: kIsWeb ? Color(0xFFDCE5DE) : Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: _green,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: kIsWeb ? 14 : 16,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade400,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String hintText,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
    FormFieldValidator<T>? validator,
  }) {
    return DropdownButtonFormField<T>(
      key: ValueKey('$hintText-$value'),
      initialValue: value,
      isExpanded: true,
      validator: validator,
      hint: Text(
        hintText,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.grey.shade400,
        ),
      ),
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: Colors.grey.shade600,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: kIsWeb ? Colors.white : Colors.grey.shade50,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(
            color: kIsWeb ? Color(0xFFDCE5DE) : Colors.transparent,
          ),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(
            color: kIsWeb ? Color(0xFFDCE5DE) : Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: _green,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: kIsWeb ? 14 : 16,
        ),
      ),
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      // Clean, single-line text shown in the CLOSED field (no boxes/padding).
      selectedItemBuilder: (context) {
        return items.values.map((label) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          );
        }).toList();
      },
      // Styled items shown in the OPEN menu; selected one is highlighted.
      items: items.entries.map((entry) {
        final isSelected = entry.key == value;
        return DropdownMenuItem<T>(
          value: entry.key,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: isSelected
                ? BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Text(
              entry.value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? _green : Colors.black87,
              ),
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildBottomButtons() {
    final showBulkUpload =
        Permissions.canBulkUpload(ref.watch(currentUserRoleProvider));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showBulkUpload) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => context.push(Routes.uploadTechnicians),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _green,
                      width: 1.5,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        color: _green,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Bulk Upload',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: GestureDetector(
              onTap: _isSaving ? null : _handleSave,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebBottomButtons() {
    final showBulkUpload =
        Permissions.canBulkUpload(ref.watch(currentUserRoleProvider));
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 540;
        final bulkButton = OutlinedButton.icon(
          key: const Key('add-user-bulk-upload'),
          onPressed:
              _isSaving ? null : () => context.push(Routes.uploadTechnicians),
          icon: const Icon(Icons.cloud_upload_outlined, size: 18),
          label: const Text('Bulk Upload'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            foregroundColor: _green,
            backgroundColor: Colors.white,
            side: const BorderSide(color: _green, width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        final saveButton = FilledButton(
          key: const Key('add-user-save'),
          onPressed: _isSaving ? null : _handleSave,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            backgroundColor: _green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        );

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth < 600 ? 16 : 24,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: Color(0xFFE7ECE8)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: compact ? 360 : 600),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showBulkUpload) ...[
                          bulkButton,
                          const SizedBox(height: 10),
                        ],
                        saveButton,
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (showBulkUpload) ...[
                          SizedBox(width: 135, height: 40, child: bulkButton),
                          const SizedBox(width: 12),
                        ],
                        SizedBox(width: 120, height: 40, child: saveButton),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
