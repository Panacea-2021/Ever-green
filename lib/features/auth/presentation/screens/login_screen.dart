import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    this.isDialog = false,
  });

  final bool isDialog;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _websiteAllowedPhones = {
    '9963477567',
    '8688193983',
    '6300662566',
    '9963917712',
    '1234567890',
  };

  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _showSlowLoginNotice = false;
  Timer? _loginWaitTimer;

  @override
  void dispose() {
    _loginWaitTimer?.cancel();
    _mobileController.dispose();
    _passwordController.dispose();
    _mobileFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final phone = _mobileController.text.trim();
    if (widget.isDialog && !_websiteAllowedPhones.contains(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This account is not authorized for website sign-in.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (widget.isDialog) {
      setState(() => _showSlowLoginNotice = false);
      _loginWaitTimer?.cancel();
      _loginWaitTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showSlowLoginNotice = true);
      });
    }
    try {
      await ref.read(authControllerProvider).login(
            email: phone,
            password: _passwordController.text,
          );
    } finally {
      _loginWaitTimer?.cancel();
      if (mounted && widget.isDialog) {
        setState(() => _showSlowLoginNotice = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final size = MediaQuery.of(context).size;
    // How much the keyboard currently covers at the bottom.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;
    // System navigation bar / gesture inset, so the Sign In button never
    // hides behind the phone's on-screen navigation buttons. Take the larger
    // of padding/viewPadding (either can be 0 depending on resize behavior)
    // and enforce a minimum safe gap.
    final mq = MediaQuery.of(context);
    final rawSystemBottom = mq.viewPadding.bottom > mq.padding.bottom
        ? mq.viewPadding.bottom
        : mq.padding.bottom;
    final systemBottom = rawSystemBottom < 24 ? 24.0 : rawSystemBottom;

    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.isAuthenticated) {
        if (widget.isDialog) {
          Navigator.of(context, rootNavigator: true).pop();
        } else {
          context.go(Routes.home);
        }
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    // Figma design: 393x852 screen. Card starts at ~54.34% from top when the
    // keyboard is closed. When the keyboard opens, the card expands upward so
    // the fields stay visible above the keyboard.
    final dialogHeight = size.height < 792 ? size.height - 32 : 760.0;
    final cardTopPosition = widget.isDialog
        ? dialogHeight * 0.3
        : isKeyboardOpen
            ? size.height * 0.22
            : size.height * 0.5434;

    final loginContent = LoadingOverlay(
      isLoading: authState.isLoading,
      message: widget.isDialog
          ? _showSlowLoginNotice
              ? 'Connecting to the sign-in server. The first request after inactivity may take longer.'
              : 'Signing in...'
          : null,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            // Background image covering full screen with gradient overlay
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/login_bg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // White card. Top animates up when the keyboard opens, and the
            // content scrolls with the keyboard inset as bottom padding so
            // the focused field is never hidden.
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              top: cardTopPosition,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: widget.isDialog
                      ? BorderRadius.circular(28)
                      : const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                ),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      36,
                      16,
                      // Clear the keyboard when open, and always clear the
                      // system nav bar so the Sign In button stays visible.
                      24 + bottomInset + systemBottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        const Text(
                          'Sign in to your account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            letterSpacing: -0.66,
                          ),
                        ),
                        const SizedBox(height: 13),
                        Text(
                          'Provide Mobile Number and Password',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Mobile Number field
                        _buildTextField(
                          controller: _mobileController,
                          focusNode: _mobileFocusNode,
                          hintText: 'Mobile Number',
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: Validators.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          onSubmitted: (_) {
                            _passwordFocusNode.requestFocus();
                          },
                        ),
                        const SizedBox(height: 17),

                        // Password field
                        _buildTextField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          hintText: 'Password',
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          validator: Validators.loginPassword,
                          onSubmitted: (_) => _handleLogin(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Forgot Password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              if (widget.isDialog) {
                                Navigator.of(context).pop();
                              }
                              context.go(Routes.forgotPassword);
                            },
                            child: Text(
                              'Forgot Password ?',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Sign In button
                        _buildPrimaryButton(
                          text: 'Sign In',
                          onPressed: _handleLogin,
                          isLoading: authState.isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (widget.isDialog)
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.48),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (widget.isDialog) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: size.width < 552 ? size.width - 32 : 520,
          height: dialogHeight,
          child: loginContent,
        ),
      );
    }

    return Scaffold(
      // Keep the background image fixed; the card + SafeArea handle insets.
      resizeToAvoidBottomInset: false,
      // Explicitly let the body extend behind system bars so our own SafeArea
      // controls spacing precisely.
      body: loginContent,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        validator: validator,
        inputFormatters: inputFormatters,
        onFieldSubmitted: onSubmitted,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black.withValues(alpha: 0.2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: const BorderSide(
              color: Color(0xFF106220),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF106220),
              Color(0xFF106220),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Overlay gradient matching Figma
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.grey.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
            // Button content
            Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showWebsiteLoginDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const LoginScreen(isDialog: true),
  );
}
