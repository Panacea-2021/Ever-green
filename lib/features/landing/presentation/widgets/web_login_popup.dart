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
import '../../../auth/presentation/providers/auth_provider.dart';
import 'web_login_popup_styles.dart';

/// Opens the website sign-in popup. On success it closes and goes to the web
/// dashboard.
Future<void> showWebLoginPopup(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const WebLoginPopup(),
  );
}

class WebLoginPopup extends ConsumerStatefulWidget {
  const WebLoginPopup({super.key});

  @override
  ConsumerState<WebLoginPopup> createState() => _WebLoginPopupState();
}

class _WebLoginPopupState extends ConsumerState<WebLoginPopup> {
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

  @override
  void initState() {
    super.initState();
    unawaited(_wakeBackend());
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    _mobileFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// The Render backend sleeps when idle and takes ~50s to wake, so ping it
  /// as soon as the popup opens; by the time the form is submitted it is up.
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _mobileController.text.trim();
    if (!_websiteAllowedPhones.contains(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This account is not authorized for website sign-in.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await ref.read(authControllerProvider).login(
          email: phone,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final size = MediaQuery.sizeOf(context);

    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.isAuthenticated) {
        final router = GoRouter.of(context);
        Navigator.of(context, rootNavigator: true).pop();
        router.go(Routes.webDashboard);
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final isWide = size.width >= WebLoginPopupStyles.wideBreakpoint;
    final width = isWide
        ? (size.width - 48).clamp(0.0, WebLoginPopupStyles.maxWideWidth)
        : (size.width - 32).clamp(0.0, WebLoginPopupStyles.maxNarrowWidth);
    final height = (size.height - 48).clamp(
      0.0,
      isWide
          ? WebLoginPopupStyles.maxWideHeight
          : WebLoginPopupStyles.maxNarrowHeight,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(WebLoginPopupStyles.cardRadius),
            boxShadow: WebLoginPopupStyles.cardShadow,
          ),
          child: LoadingOverlay(
            isLoading: authState.isLoading,
            message: 'Signing in...',
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isWide) Expanded(flex: 54, child: _buildBrandPanel()),
                    Expanded(
                      flex: 46,
                      child: _buildFormPanel(authState, isWide),
                    ),
                  ],
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Material(
                    color: WebLoginPopupStyles.closeButton,
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

  Widget _buildBrandPanel() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          WebLoginPopupStyles.brandImage,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
        DecoratedBox(
          decoration:
              BoxDecoration(gradient: WebLoginPopupStyles.brandOverlay),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 32, 32, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    WebLoginPopupStyles.logoImage,
                    height: 40,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(width: 12),
                  const Text('Evergreen', style: WebLoginPopupStyles.brandName),
                ],
              ),
              const Spacer(),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Reliable\nAppliance Care\nfor a\n'),
                    TextSpan(
                      text: 'Better Home',
                      style: TextStyle(color: WebLoginPopupStyles.accentGreen),
                    ),
                  ],
                ),
                style: WebLoginPopupStyles.headline,
              ),
              const SizedBox(height: 16),
              const Text(
                'Expert repairs. Trusted service.\nA greener tomorrow.',
                style: WebLoginPopupStyles.tagline,
              ),
              const SizedBox(height: 28),
              _buildFeature(Icons.build_rounded, 'Fast & Reliable\nService'),
              const SizedBox(height: 16),
              _buildFeature(
                Icons.verified_user_rounded,
                'Certified\nTechnicians',
              ),
              const SizedBox(height: 16),
              _buildFeature(Icons.eco_rounded, 'Eco-Friendly\nSolutions'),
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeature(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: WebLoginPopupStyles.featureBadge,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Text(label, style: WebLoginPopupStyles.featureLabel),
      ],
    );
  }

  Widget _buildFormPanel(AuthState authState, bool isWide) {
    return Form(
      key: _formKey,
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 40 : 24,
            vertical: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Welcome Back', style: WebLoginPopupStyles.title),
              const SizedBox(height: 10),
              const Text(
                'Sign in to your Evergreen account\nto continue.',
                style: WebLoginPopupStyles.subtitle,
              ),
              const SizedBox(height: 36),
              TextFormField(
                controller: _mobileController,
                focusNode: _mobileFocusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: Validators.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                cursorColor: WebLoginPopupStyles.green,
                style: WebLoginPopupStyles.fieldText,
                decoration: WebLoginPopupStyles.fieldDecoration(
                  hintText: 'Mobile Number',
                  icon: Icons.phone_outlined,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                validator: Validators.loginPassword,
                onFieldSubmitted: (_) => _handleLogin(),
                cursorColor: WebLoginPopupStyles.green,
                style: WebLoginPopupStyles.fieldText,
                decoration: WebLoginPopupStyles.fieldDecoration(
                  hintText: 'Password',
                  icon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: WebLoginPopupStyles.iconMuted,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    final router = GoRouter.of(context);
                    Navigator.of(context).pop();
                    router.go(Routes.forgotPassword);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: WebLoginPopupStyles.green,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: WebLoginPopupStyles.link,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: WebLoginPopupStyles.buttonHeight,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleLogin,
                  style: WebLoginPopupStyles.primaryButton,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Sign In', style: WebLoginPopupStyles.button),
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
}
