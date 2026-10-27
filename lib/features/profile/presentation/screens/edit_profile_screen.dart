import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../users/data/users_repository.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _companyController;
  late TextEditingController _locationController;
  late TextEditingController _roleController;
  late TextEditingController _bioController;
  late TextEditingController _dobController;

  bool _isLoading = false;
  DateTime? _dateOfBirth;

  /// Photo picked in this session; uploaded when the profile is saved.
  XFile? _pickedPhoto;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _companyController = TextEditingController();
    _locationController = TextEditingController();
    _roleController = TextEditingController();
    _bioController = TextEditingController();
    _dobController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initControllers();
    });
  }

  void _initControllers() {
    final user = ref.read(currentUserProvider);
    final companies = user?.companies ?? const <UserCompany>[];
    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = user?.phone ?? '';
    _companyController.text = companies.isEmpty
        ? 'EverGreen'
        : companies
            .map(
              (c) =>
                  c.branchName.isEmpty ? c.name : '${c.name} - ${c.branchName}',
            )
            .join(', ');
    _locationController.text = user?.location ?? '';
    _roleController.text = user?.role.label ?? '';
    _bioController.text = user?.bio ?? '';
    _dateOfBirth = user?.dateOfBirth;
    _dobController.text = _formatDate(_dateOfBirth);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(date.day)}-${two(date.month)}-${date.year}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _roleController.dispose();
    _bioController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_isLoading) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 80,
      );
    } catch (e) {
      if (mounted) _snack('Could not open ${source.name}: $e', error: true);
      return;
    }
    if (file == null || !mounted) return;
    setState(() => _pickedPhoto = file);
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _dateOfBirth = picked;
      _dobController.text = _formatDate(picked);
    });
  }

  /// `PUT user/updateUser/:id` with the self-editable fields; a newly picked
  /// photo is uploaded first (`upload-file`, folder `avatar`).
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    String? avatarUrl;
    if (_pickedPhoto != null) {
      try {
        avatarUrl = await ref
            .read(evergreenRepositoryProvider)
            .uploadFile(_pickedPhoto!.path, folderName: 'avatar');
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _snack('Photo upload failed: $e', error: true);
        return;
      }
    }

    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    final bio = _bioController.text.trim();
    final result = await ref.read(usersRepositoryProvider).updateUser(
          user.backendId,
          name: name,
          location: location,
          bio: bio,
          dateOfBirth: _dateOfBirth,
          avatarUrl: avatarUrl,
        );
    if (!mounted) return;

    await result.fold(
      (failure) async {
        setState(() => _isLoading = false);
        _snack(failure.displayMessage, error: true);
      },
      (message) async {
        final notifier = ref.read(authStateProvider.notifier);
        notifier.updateUser(
          user.copyWith(
            name: name,
            location: location,
            bio: bio,
            dateOfBirth: _dateOfBirth,
            profilePictureUrl: avatarUrl,
          ),
        );
        final fresh = await ref.read(authRepositoryProvider).getCurrentUser();
        fresh.fold((_) {}, notifier.updateUser);
        if (!mounted) return;
        setState(() => _isLoading = false);
        _snack(message);
        Navigator.of(context).pop();
      },
    );
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: Image.asset(
                  'assets/images/home_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.white),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(context),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 40,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildAvatarSection(),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: _pickPhoto,
                                  child: const Text(
                                    'Change Photo',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildFormField(
                                  label: 'Full Name',
                                  controller: _nameController,
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 16),
                                _buildFormField(
                                  label: 'Email Address',
                                  controller: _emailController,
                                  icon: Icons.email_outlined,
                                  enabled: false,
                                ),
                                const SizedBox(height: 16),
                                _buildFormField(
                                  label: 'Phone Number',
                                  controller: _phoneController,
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  enabled: false,
                                ),
                                const SizedBox(height: 16),
                                _buildFormField(
                                  label: 'Company',
                                  controller: _companyController,
                                  icon: Icons.business_outlined,
                                  enabled: false,
                                ),
                                const SizedBox(height: 16),
                                _buildFormField(
                                  label: 'Location',
                                  controller: _locationController,
                                  icon: Icons.location_on_outlined,
                                  validator: (v) => (v?.trim().length ?? 0) >
                                          100
                                      ? 'Location must be at most 100 characters'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                _buildFormField(
                                  label: 'Bio',
                                  controller: _bioController,
                                  icon: Icons.info_outline,
                                  validator: (_) => null,
                                ),
                                const SizedBox(height: 16),
                                _buildFormField(
                                  label: 'Date of Birth',
                                  controller: _dobController,
                                  icon: Icons.cake_outlined,
                                  readOnly: true,
                                  onTap: _pickDateOfBirth,
                                  validator: (_) => null,
                                ),
                                const SizedBox(height: 16),
                                _buildFormField(
                                  label: 'Role',
                                  controller: _roleController,
                                  icon: Icons.work_outline,
                                  enabled: false,
                                ),
                                const SizedBox(height: 28),
                                _buildSaveButton(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF262626),
                ),
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    final user = ref.watch(currentUserProvider);
    final initials = Text(
      _getInitials(user?.name ?? ''),
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );

    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF2F7F3),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 3,
            ),
          ),
          child: Center(
            child: _pickedPhoto != null
                ? ClipOval(
                    child: Image.file(
                      File(_pickedPhoto!.path),
                      width: 94,
                      height: 94,
                      fit: BoxFit.cover,
                    ),
                  )
                : mediaUrl(user?.profilePictureUrl).isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          mediaUrl(user!.profilePictureUrl),
                          width: 94,
                          height: 94,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => initials,
                        ),
                      )
                    : initials,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: const Center(
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    const fieldRadius = 14.0;
    final fillColor = enabled ? Colors.white : const Color(0xFFF0F3F1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555),
              ),
            ),
            if (!enabled) ...[
              const SizedBox(width: 6),
              Icon(Icons.lock_outline, size: 13, color: Colors.grey.shade500),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: enabled ? const Color(0xFF1C2B20) : const Color(0xFF808080),
          ),
          validator: !enabled
              ? null
              : validator ??
                  (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'This field is required';
                    }
                    return null;
                  },
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: fillColor,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 10),
              child: Icon(
                icon,
                size: 22,
                color: enabled ? AppColors.primary : Colors.grey.shade400,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fieldRadius),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fieldRadius),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fieldRadius),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fieldRadius),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fieldRadius),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fieldRadius),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            errorStyle: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _saveProfile,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF1A801A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }
}
