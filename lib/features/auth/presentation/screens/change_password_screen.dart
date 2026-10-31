import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../users/data/users_repository.dart';

/// Change the signed-in user's password through `POST user/changePassword`.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  /// Backend limits for the new password.
  static const int minLength = 6;
  static const int maxLength = 20;

  /// Client-side check before calling the backend; null when valid.
  static String? validate({
    required String current,
    required String next,
    required String confirm,
  }) {
    if (current.isEmpty) return 'Enter your current password';
    if (next.length < minLength) {
      return 'New password must be at least $minLength characters';
    }
    if (next.length > maxLength) {
      return 'New password must be at most $maxLength characters';
    }
    if (next == current) {
      return 'New password must be different from the current one';
    }
    if (next != confirm) return 'Passwords do not match';
    return null;
  }

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  static const Color _green = Color(0xFF106220);
  static const Color _green2 = Color(0xFF0D5119);
  static const Color _ink = Color(0xFF1C2B20);

  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _hideCurrent = true;
  bool _hideNext = true;
  bool _hideConfirm = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final err = ChangePasswordScreen.validate(
      current: _current.text,
      next: _next.text,
      confirm: _confirm.text,
    );
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(usersRepositoryProvider).changePassword(
        currentPassword: _current.text, newPassword: _next.text);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = _sentence(failure.displayMessage);
      }),
      (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_sentence(message)),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.home);
        }
      },
    );
  }

  /// The backend sends lower-case messages ("password updated").
  static String _sentence(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
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
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildIntro(),
                          const SizedBox(height: 20),
                          _buildFormCard(),
                          const SizedBox(height: 24),
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                context.canPop() ? context.pop() : context.go(Routes.home),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 14),
          const Text(
            'Change Password',
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

  Widget _buildIntro() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_outline, color: _green, size: 34),
        ),
        const SizedBox(height: 14),
        const Text(
          'Update your password',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your current password, then choose a new one.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Current password'),
          _field(
            _current,
            'Enter current password',
            _hideCurrent,
            () => setState(() => _hideCurrent = !_hideCurrent),
            TextInputAction.next,
          ),
          const SizedBox(height: 14),
          _label('New password'),
          _field(
            _next,
            'Enter new password',
            _hideNext,
            () => setState(() => _hideNext = !_hideNext),
            TextInputAction.next,
          ),
          const SizedBox(height: 14),
          _label('Confirm new password'),
          _field(
            _confirm,
            'Re-enter new password',
            _hideConfirm,
            () => setState(() => _hideConfirm = !_hideConfirm),
            TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _error == null ? Icons.info_outline : Icons.error_outline,
                size: 14,
                color:
                    _error == null ? const Color(0xFF9B9B9B) : AppColors.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _error ??
                      'Use ${ChangePasswordScreen.minLength} to '
                          '${ChangePasswordScreen.maxLength} characters.',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    color: _error == null
                        ? const Color(0xFF9B9B9B)
                        : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _ink,
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint,
    bool hide,
    VoidCallback toggle,
    TextInputAction action, {
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: c,
      obscureText: hide,
      enabled: !_saving,
      textInputAction: action,
      onSubmitted: onSubmitted,
      maxLength: ChangePasswordScreen.maxLength,
      cursorColor: _green,
      style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        hintStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          color: Color(0xFF9B9B9B),
        ),
        filled: true,
        fillColor: const Color(0xFFF2F7F3),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: IconButton(
          tooltip: hide ? 'Show password' : 'Hide password',
          icon: Icon(
            hide ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: const Color(0xFF808080),
          ),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _green, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _saving ? null : _submit,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_green, _green2]),
          borderRadius: BorderRadius.circular(27),
          boxShadow: [
            BoxShadow(
              color: _green.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Update Password',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
