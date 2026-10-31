import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/environment_config.dart';
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
  void initState() {
    super.initState();
    if (widget.isDialog) unawaited(_wakeBackend());
  }

  /// The Render backend sleeps when idle and takes ~50s to wake, so ping it
  /// as soon as the dialog opens; by the time the form is submitted it is up.
  static Future<void> _wakeBackend() async {
    try {
      await Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      ).get<dynamic>(EnvironmentConfig.backendUrl);
    } catch (_) {}
  }

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
          final router = GoRouter.of(context);
          Navigator.of(context, rootNavigator: true).pop();
          router.go(Routes.webDashboard);
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

    if (widget.isDialog) {
      return _buildWebLoginDialog(authState, size);
    }

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
          ? 'Signing in...'
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

  static const _webGreen = Color(0xFF0B5D1E);
  static const _webAccentGreen = Color(0xFF6BD35A);

  Widget _buildWebLoginDialog(AuthState authState, Size size) {
    final isWide = size.width >= 820;
    final dialogWidth = isWide
        ? (size.width - 48).clamp(0.0, 960.0)
        : (size.width - 32).clamp(0.0, 460.0);
    final dialogHeight = (size.height - 48).clamp(0.0, isWide ? 620.0 : 560.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: LoadingOverlay(
            isLoading: authState.isLoading,
            message: _showSlowLoginNotice
                ? 'Connecting to the sign-in server. The first request after inactivity may take longer.'
                : 'Signing in...',
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isWide) Expanded(flex: 54, child: _buildWebBrandPanel()),
                    Expanded(
                      flex: 46,
                      child: _buildWebFormPanel(authState, isWide),
                    ),
                  ],
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Material(
                    color: const Color(0xFFF1F2F4),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebBrandPanel() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/login_bg.png',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                const Color(0xFF04230C).withValues(alpha: 0.92),
                const Color(0xFF04230C).withValues(alpha: 0.70),
                const Color(0xFF04230C).withValues(alpha: 0.35),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 32, 32, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 40,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Evergreen',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Reliable\nAppliance Care\nfor a\n'),
                    TextSpan(
                      text: 'Better Home',
                      style: TextStyle(color: _webAccentGreen),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 32,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Expert repairs. Trusted service.\nA greener tomorrow.',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              _buildWebFeature(Icons.build_rounded, 'Fast & Reliable\nService'),
              const SizedBox(height: 16),
              _buildWebFeature(Icons.verified_user_rounded, 'Certified\nTechnicians'),
              const SizedBox(height: 16),
              _buildWebFeature(Icons.eco_rounded, 'Eco-Friendly\nSolutions'),
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebFeature(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF138A2E),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildWebFormPanel(AuthState authState, bool isWide) {
    return Form(
      key: _formKey,
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sign in to your Evergreen account\nto continue.',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8A8F98),
                ),
              ),
              const SizedBox(height: 36),
              _buildWebTextField(
                controller: _mobileController,
                focusNode: _mobileFocusNode,
                hintText: 'Mobile Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: Validators.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onSubmitted: (_) => _passwordFocusNode.requestFocus(),
              ),
              const SizedBox(height: 18),
              _buildWebTextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                hintText: 'Password',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                validator: Validators.loginPassword,
                onSubmitted: (_) => _handleLogin(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF6B7280),
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(Routes.forgotPassword);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _webGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _webGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _webGreen.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sign In',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      inputFormatters: inputFormatters,
      onFieldSubmitted: onSubmitted,
      cursorColor: _webGreen,
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Color(0xFF111827),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF9CA3AF),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF111827), size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        border: border(const Color(0xFFE5E7EB)),
        enabledBorder: border(const Color(0xFFE5E7EB)),
        focusedBorder: border(_webGreen, 1.6),
        errorBorder: border(AppColors.error),
        focusedErrorBorder: border(AppColors.error, 1.6),
      ),
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
