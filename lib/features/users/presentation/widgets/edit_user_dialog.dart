import 'package:flutter/material.dart';

import '../../../../core/models/backend_models.dart' as backend;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/password_generator.dart';
import '../../../auth/domain/models/user_model.dart';

/// Everything the caller needs to persist an edit made in [EditUserDialog].
class EditUserDialogResult {
  const EditUserDialogResult({
    required this.phone,
    required this.email,
    required this.role,
    required this.companyIds,
    this.password,
  });

  final String phone;
  final String email;
  final UserRole role;
  final List<int> companyIds;

  /// Null when the viewer cannot set passwords or left the field blank.
  final String? password;
}

/// Edit-user form shown as a dialog. Uses labels above the inputs instead of
/// floating labels, so text can never collide with the field outline, and
/// groups the form into clear sections with consistent spacing.
class EditUserDialog extends StatefulWidget {
  const EditUserDialog({
    super.key,
    required this.userName,
    required this.initialPhone,
    required this.initialEmail,
    required this.initialRole,
    required this.roleChoices,
    required this.companies,
    required this.initialCompanyIds,
    this.showPassword = false,
  });

  final String userName;
  final String initialPhone;
  final String initialEmail;
  final UserRole initialRole;
  final List<UserRole> roleChoices;
  final List<backend.Company> companies;
  final Set<int> initialCompanyIds;

  /// Super Admin only: show the "set a new password" field.
  final bool showPassword;

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final TextEditingController _phone =
      TextEditingController(text: widget.initialPhone);
  late final TextEditingController _email =
      TextEditingController(text: widget.initialEmail);
  final TextEditingController _password = TextEditingController();
  late UserRole _role = widget.initialRole;
  late final TextEditingController _companySearch =
      TextEditingController();
  late final Set<int> _selectedCompanies = {...widget.initialCompanyIds};
  String _companyQuery = '';
  bool _passwordVisible = true;
  String? _phoneError;
  String? _passwordError;

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _companySearch.dispose();
    super.dispose();
  }

  void _submit() {
    final phone = _phone.text.trim();
    final password = widget.showPassword ? _password.text.trim() : '';
    setState(() {
      _phoneError = phone.isEmpty ? 'Mobile number is required' : null;
      _passwordError =
          password.isNotEmpty && (password.length < 6 || password.length > 20)
              ? 'Password must be 6 to 20 characters'
              : null;
    });
    if (_phoneError != null || _passwordError != null) return;

    Navigator.pop(
      context,
      EditUserDialogResult(
        phone: phone,
        email: _email.text.trim(),
        role: _role,
        companyIds: _selectedCompanies.toList(),
        password: password.isEmpty ? null : password,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    // 88 = dialog inset padding (2 x 20) + content padding (2 x 24).
    final contentWidth = (media.width - 88).clamp(260.0, 440.0);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.10),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit ${widget.userName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Update contact details, access and assignments',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: contentWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Contact details'),
              const SizedBox(height: 12),
              _field(
                label: 'Mobile number',
                controller: _phone,
                keyboardType: TextInputType.phone,
                hintText: 'Enter mobile number',
                errorText: _phoneError,
              ),
              const SizedBox(height: 16),
              _field(
                label: 'Email address',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                hintText: 'Enter email address',
              ),
              if (widget.showPassword) ...[
                const SizedBox(height: 24),
                _sectionLabel('Password'),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (context, fieldState) => _field(
                    label: 'New password',
                    controller: _password,
                    hintText: 'Leave blank to keep the current password',
                    helperText: 'Use 6 to 20 characters.',
                    errorText: _passwordError,
                    obscureText: !_passwordVisible,
                    suffix: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: _passwordVisible
                              ? 'Hide password'
                              : 'Show password',
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 19,
                          ),
                          onPressed: () => fieldState(
                            () => _passwordVisible = !_passwordVisible,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Generate new password',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.refresh, size: 19),
                          onPressed: () {
                            _password.text = generatePassword();
                            fieldState(() => _passwordVisible = true);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _sectionLabel('Access & assignment'),
              const SizedBox(height: 12),
              _fieldLabel('Access type'),
              const SizedBox(height: 8),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                isExpanded: true,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  color: AppColors.textPrimaryLight,
                ),
                decoration: _inputDecoration(hintText: 'Select access type'),
                items: [
                  for (final role in widget.roleChoices)
                    DropdownMenuItem(
                      value: role,
                      child: Text(role.label, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (role) {
                  if (role != null) setState(() => _role = role);
                },
              ),
              const SizedBox(height: 16),
              _fieldLabel('Assign to company / AMC'),
              const SizedBox(height: 8),
              _companyPicker(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondaryLight,
            textStyle: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _companyPicker() {
    final query = _companyQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.companies
        : widget.companies.where((c) {
            return [c.name, c.branchName, c.location ?? '', c.gstNumber ?? '']
                .any((f) => f.toLowerCase().contains(query));
          }).toList();

    return Material(
      color: const Color(0xFFF8FAF7),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: widget.companies.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'No companies available',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: TextField(
                    controller: _companySearch,
                    onChanged: (v) => setState(() => _companyQuery = v),
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search company / AMC…',
                      hintStyle: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'No matching companies',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 176),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: 12,
                        endIndent: 12,
                        color: AppColors.divider,
                      ),
                      itemBuilder: (context, index) {
                        final company = filtered[index];
                        return CheckboxListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          title: Text(
                            company.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13.5),
                          ),
                          value: _selectedCompanies.contains(company.id),
                          onChanged: (value) => setState(() {
                            if (value == true) {
                              _selectedCompanies.add(company.id);
                            } else {
                              _selectedCompanies.remove(company.id);
                            }
                          }),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  /// Small caps heading that groups the fields inside the dialog.
  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondaryLight,
          ),
        ),
      );

  /// Field label drawn above the input so it can never collide with the
  /// outline the way a floating label can.
  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
        ),
      );

  InputDecoration _inputDecoration({
    String? hintText,
    String? helperText,
    String? errorText,
    Widget? suffix,
  }) =>
      InputDecoration(
        isDense: true,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        helperMaxLines: 2,
        errorMaxLines: 2,
        suffixIcon: suffix,
        suffixIconConstraints: suffix == null
            ? null
            : const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: const Color(0xFFF8FAF7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.disabled),
      );

  Widget _field({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? hintText,
    String? helperText,
    String? errorText,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: const TextStyle(fontSize: 14),
          decoration: _inputDecoration(
            hintText: hintText,
            helperText: helperText,
            errorText: errorText,
            suffix: suffix,
          ),
        ),
      ],
    );
  }
}
