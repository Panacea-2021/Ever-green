import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../core/data/evergreen_repository.dart' as repo;
import '../../../../core/models/backend_models.dart';
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

  // Web-only embedded AMC picker state.
  bool _amcPickerOpen = false;
  final TextEditingController _amcSearchController = TextEditingController();
  String _amcQuery = '';
  final GlobalKey _amcCardKey = GlobalKey();
  final FocusNode _amcFocusNode = FocusNode();

  // Web-only embedded Access Type picker state.
  bool _accessTypePickerOpen = false;
  final GlobalKey _accessTypeCardKey = GlobalKey();
  final TextEditingController _accessTypeController = TextEditingController();

  static const Color _green = Color(0xFF106220);

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _companyController.dispose();
    _amcSearchController.dispose();
    _amcFocusNode.dispose();
    _accessTypeController.dispose();
    super.dispose();
  }

  /// Opens/closes the AMC search inside the selection card and makes sure the
  /// expanded card is scrolled into view.
  void _toggleAmcPicker() {
    if (_amcPickerOpen) {
      FocusScope.of(context).unfocus();
      setState(() {
        _amcPickerOpen = false;
        _amcQuery = '';
      });
      _amcSearchController.clear();
      return;
    }

    setState(() => _amcPickerOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amcFocusNode.requestFocus();
      final ctx = _amcCardKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 200),
          alignment: 0.05,
        );
      }
    });
  }

  /// Keeps both the display name and the backend company id in the form state
  /// so the selection survives further edits and is sent on save.
  void _selectCompany(Company company) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedCompanyId = company.id;
      _companyController.text = company.displayName;
      _amcPickerOpen = false;
      _amcQuery = '';
    });
    _amcSearchController.clear();
  }

  /// Opens/closes the Access Type picker inside the selection card.
  void _toggleAccessTypePicker() {
    if (_accessTypePickerOpen) {
      FocusScope.of(context).unfocus();
      setState(() => _accessTypePickerOpen = false);
      return;
    }
    setState(() => _accessTypePickerOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _accessTypeCardKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 200),
          alignment: 0.05,
        );
      }
    });
  }

  /// Selects an Access Type, preserving the existing role-change side effects.
  void _selectAccessType(UserRole value) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedRole = value;
      _accessTypeController.text = value.label;
      _accessTypePickerOpen = false;
      _amcPickerOpen = false;
      _amcQuery = '';
      _amcSearchController.clear();
      if (value == UserRole.superAdmin ||
          value == UserRole.manager ||
          (value.isTechnicianLevel)) {
        _selectedCompanyId = null;
        _companyController.clear();
      }
    });
  }

  Widget _buildAccessTypeField(UserRole actorRole) {
    final options = _creatableRoles(actorRole);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: _accessTypeCardKey,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _accessTypePickerOpen
                  ? _green
                  : const Color(0xFFDCE5DE),
              width: _accessTypePickerOpen ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: kIsWeb ? _toggleAccessTypePicker : null,
                behavior: HitTestBehavior.opaque,
                child: AbsorbPointer(
                  child: TextFormField(
                    readOnly: true,
                    controller: _accessTypeController,
                    validator: (v) =>
                        _selectedRole == null ? 'Please select access type' : null,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Access Type',
                      hintStyle: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: kIsWeb ? Colors.white : Colors.grey.shade50,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: kIsWeb ? 14 : 16,
                      ),
                      suffixIcon: Icon(
                        _accessTypePickerOpen
                            ? Icons.close
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
              if (kIsWeb && _accessTypePickerOpen) ...[
                const Divider(height: 1, color: Color(0xFFE6EDE7)),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final role = options[index];
                      final isSelected = role == _selectedRole;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        selectedTileColor: _green.withValues(alpha: 0.06),
                        title: Text(
                          role.label,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: _green,
                                size: 18,
                              )
                            : null,
                        onTap: () => _selectAccessType(role),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
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
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: _buildFormCard(),
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
      width: double.infinity,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assignment_ind,
                      color: _green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User Information',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Provide basic details of the User',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Name',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _nameController,
                          hintText: 'Name',
                          validator: (value) => (value == null || value.trim().isEmpty)
                              ? 'Please enter name'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mobile Number',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
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
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Email ID',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _emailController,
                          hintText: 'Email ID',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => Validators.email(value?.trim()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Password',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            TextButton.icon(
                              key: const Key('regeneratePassword'),
                              onPressed: () => setState(
                                () => _passwordController.text = generatePassword(),
                              ),
                              icon: const Icon(
                                Icons.autorenew,
                                size: 16,
                                color: _green,
                              ),
                              label: const Text(
                                'Generate new password',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  color: _green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (kIsWeb)
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
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Access Type',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildAccessTypeField(actorRole),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Company / AMC',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (!_hideCompanyField) _buildCompanyField(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
    final isTech = _selectedRole?.isTechnicianLevel == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: _amcCardKey,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _amcPickerOpen ? _green : const Color(0xFFDCE5DE),
              width: _amcPickerOpen ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: (kIsWeb && !_amcPickerOpen) ? _toggleAmcPicker : null,
                behavior: HitTestBehavior.opaque,
                child: AbsorbPointer(
                  absorbing: !kIsWeb || !_amcPickerOpen,
                  child: TextFormField(
                    controller: _amcPickerOpen
                        ? _amcSearchController
                        : _companyController,
                    focusNode: _amcPickerOpen ? _amcFocusNode : null,
                    onChanged: _amcPickerOpen
                        ? (v) => setState(() => _amcQuery = v)
                        : null,
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
                      hintText: _amcPickerOpen
                          ? 'Search AMC'
                          : (isTech
                              ? 'Allocated Site (optional)'
                              : 'Search and select AMC'),
                      hintStyle: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: _amcPickerOpen
                          ? const Icon(Icons.search, color: _green, size: 20)
                          : null,
                      suffixIcon: kIsWeb
                          ? (_amcPickerOpen
                              ? IconButton(
                                  tooltip: 'Close search',
                                  onPressed: _toggleAmcPicker,
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                )
                              : const Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                  size: 20,
                                ))
                          : const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: kIsWeb ? Colors.white : Colors.grey.shade50,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: kIsWeb ? 14 : 16,
                      ),
                    ),
                  ),
                ),
              ),
              if (kIsWeb && _amcPickerOpen) ...[
                const Divider(height: 1, color: Color(0xFFE6EDE7)),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: Builder(
                    builder: (context) {
                      final q = _amcQuery.trim().toLowerCase();
                      final filtered = q.isEmpty
                          ? companies
                          : companies
                              .where(
                                (c) => [
                                  c.name,
                                  c.branchName,
                                  c.location ?? '',
                                ].any(
                                  (f) => f.toLowerCase().contains(q),
                                ),
                              )
                              .toList();
                      if (filtered.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No results found',
                            style: TextStyle(fontFamily: 'Montserrat'),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final c = filtered[index];
                          final location = c.location ?? '';
                          final isSelected = c.id == _selectedCompanyId;
                          return ListTile(
                            dense: true,
                            selected: isSelected,
                            selectedTileColor:
                                _green.withValues(alpha: 0.06),
                            title: Text(
                              c.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: location.isNotEmpty
                                ? Text(
                                    location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: _green,
                                    size: 18,
                                  )
                                : null,
                            onTap: () => _selectCompany(c),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
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
