import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../core/data/evergreen_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/push/push_service.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/scaffold_with_bottom_nav.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../users/data/users_repository.dart';
import '../../data/settings_preferences.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  static const Color _green = Color(0xFF106220);
  static const Color _green2 = Color(0xFF0D5119);

  /// Mirrors the OS notification permission for this app.
  bool _pushNotifications = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPushStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The permission can change in system settings while the app is paused.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPushStatus();
  }

  Future<void> _refreshPushStatus() async {
    bool enabled;
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      enabled =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      enabled = false;
    }
    if (mounted) setState(() => _pushNotifications = enabled);
  }

  /// Turning on asks for the permission and registers this device's token
  /// with the backend; the OS only lets the user revoke it in system settings.
  Future<void> _setPushNotifications(bool value) async {
    if (!value) {
      _toast(
        'To turn off notifications, disable them for EverGreen in your '
        'phone’s Settings',
      );
      return;
    }
    await ref.read(pushServiceProvider).registerForUser();
    await _refreshPushStatus();
    if (!mounted) return;
    _toast(
      _pushNotifications
          ? 'Notifications enabled'
          : 'Allow notifications for EverGreen in your phone’s Settings',
      error: !_pushNotifications,
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentUserRoleProvider);
    final prefs = ref.watch(settingsPreferencesProvider);

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
            // Same decorative background as the Home page: faint patterned
            // image at 30% opacity over white.
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
            Column(
              children: [
                _header(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      context.canPop()
                          ? 32
                          : ScaffoldWithBottomNav.bottomInset(context) + 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Preferences'),
                        _card([
                          _switchTile(
                            Icons.dark_mode_outlined,
                            'Dark Mode',
                            prefs.darkMode,
                            (v) {
                              ref
                                  .read(settingsPreferencesProvider.notifier)
                                  .setDarkMode(v);
                              _toast(v ? 'Dark mode on' : 'Dark mode off');
                            },
                          ),
                          _divider(),
                          _switchTile(
                            Icons.notifications_outlined,
                            'Push Notifications',
                            _pushNotifications,
                            _setPushNotifications,
                          ),
                          _divider(),
                          _navTile(
                            Icons.language_outlined,
                            'Language',
                            trailing: prefs.language,
                            onTap: _showLanguagePicker,
                          ),
                        ]),
                        const SizedBox(height: 22),
                        _sectionLabel('Account'),
                        _card([
                          _navTile(
                            Icons.lock_outline,
                            'Change Password',
                            onTap: _showChangePassword,
                          ),
                          if (Permissions.canManageUsers(role)) ...[
                            _divider(),
                            _navTile(
                              Icons.admin_panel_settings_outlined,
                              'Manage Roles & Permissions',
                              onTap: () => context.push(Routes.usersList),
                            ),
                            _divider(),
                            _navTile(
                              Icons.palette_outlined,
                              'Company Branding',
                              onTap: _showBranding,
                            ),
                          ],
                        ]),
                        if (Permissions.canViewAnalytics(role)) ...[
                          const SizedBox(height: 22),
                          _sectionLabel('Reports'),
                          _card([
                            _navTile(
                              Icons.summarize_outlined,
                              'Export Service Report (CSV)',
                              onTap: () => _exportServiceReport(context),
                            ),
                            _divider(),
                            _navTile(
                              Icons.cloud_done_outlined,
                              'Offline Data',
                              trailing: 'Cached',
                              onTap: _showOfflineInfo,
                            ),
                          ]),
                        ],
                        const SizedBox(height: 22),
                        _sectionLabel('Support'),
                        _card([
                          _navTile(
                            Icons.help_outline,
                            'Help Center',
                            onTap: () => _showInfoDialog(
                              'Help Center',
                              Icons.help_outline,
                              'Browse FAQs and how-to guides, or reach our support '
                                  'team at support@evergreen.com. Average response '
                                  'time is under 4 hours on business days.',
                            ),
                          ),
                          _divider(),
                          _navTile(
                            Icons.feedback_outlined,
                            'Send Feedback',
                            onTap: _showFeedbackSheet,
                          ),
                          _divider(),
                          _navTile(
                            Icons.description_outlined,
                            'Terms of Service',
                            onTap: () => _showInfoDialog(
                              'Terms of Service',
                              Icons.description_outlined,
                              'By using EverGreen you agree to use the platform for '
                                  'legitimate equipment and maintenance management. '
                                  'Full terms are available on our website.',
                            ),
                          ),
                          _divider(),
                          _navTile(
                            Icons.privacy_tip_outlined,
                            'Privacy Policy',
                            onTap: () => _showInfoDialog(
                              'Privacy Policy',
                              Icons.privacy_tip_outlined,
                              'Your data is stored securely and never sold. Service '
                                  'records are retained for the life of the AMC '
                                  'contract. See our website for the full policy.',
                            ),
                          ),
                        ]),
                        const SizedBox(height: 22),
                        _logoutButton(),
                        const SizedBox(height: 18),
                        const Center(
                          child: Text(
                            'EverGreen v1.0.0',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              color: Color(0xFF9B9B9B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------
  Widget _header() {
    final canPop = context.canPop();
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 14,
        left: 8,
        right: 8,
        bottom: 12,
      ),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1C2B20)),
              tooltip: 'Back',
            )
          else
            const SizedBox(width: 48),
          const Expanded(
            child: Text(
              'Settings',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C2B20),
              ),
            ),
          ),
          // Balance the back button so the title stays centered.
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Color(0xFF6B6B6B),
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(children: children),
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.only(left: 56),
        child: Divider(height: 1, color: Colors.grey.shade200),
      );

  Widget _iconChip(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 19, color: _green),
    );
  }

  Widget _navTile(
    IconData icon,
    String title, {
    String? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            _iconChip(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _green,
                ),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _switchTile(
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          _iconChip(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: _green,
          ),
        ],
      ),
    );
  }

  Widget _logoutButton() {
    return GestureDetector(
      onTap: _handleLogout,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFFDE8E8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Color(0xFFE52020), size: 20),
            SizedBox(width: 10),
            Text(
              'Logout',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE52020),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Change Password — redesigned to match the app style
  // ---------------------------------------------------------------------------
  Future<void> _showChangePassword() async {
    final message = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: _ChangePasswordBody(
          submit: (current, next) => ref
              .read(usersRepositoryProvider)
              .changePassword(currentPassword: current, newPassword: next),
        ),
      ),
    );
    if (message != null && mounted) _toast(message);
  }

  void _showLanguagePicker() {
    const langs = [
      'English',
      'हिन्दी (Hindi)',
      'తెలుగు (Telugu)',
      'தமிழ் (Tamil)',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetHandle(),
          _sheetHeader('Select Language', Icons.language_outlined),
          for (final l in langs)
            ListTile(
              leading: Icon(
                l == ref.read(settingsPreferencesProvider).language
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: _green,
              ),
              title: Text(l, style: const TextStyle(fontFamily: 'Montserrat')),
              onTap: () {
                ref.read(settingsPreferencesProvider.notifier).setLanguage(l);
                Navigator.pop(context);
                _toast('Language set to $l');
              },
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  static const List<Color> _brandAccents = [
    Color(0xFF106220),
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFFE08600),
    Color(0xFFD32F2F),
  ];

  /// The design's branding dialog; the chosen accent is kept on this device.
  void _showBranding() {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final selected = ref.watch(settingsPreferencesProvider).brandAccent ??
              _green.toARGB32();
          return Dialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sheetHeader('Company Branding', Icons.palette_outlined),
                  const SizedBox(height: 8),
                  const Text(
                    'Pick a brand accent color for this device. Logo upload '
                    'and app-wide theming arrive with the admin web console.',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      height: 1.55,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final c in _brandAccents)
                        GestureDetector(
                          onTap: () => ref
                              .read(settingsPreferencesProvider.notifier)
                              .setBrandAccent(c.toARGB32()),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: c.toARGB32() == selected
                                    ? const Color(0xFF1C2B20)
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: c.toARGB32() == selected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _gradientButton('Got it', () => Navigator.pop(ctx)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showOfflineInfo() {
    _showInfoDialog(
      'Offline Data',
      Icons.cloud_done_outlined,
      'Your sign-in session and app preferences are cached on this device. '
          'Tasks, AMCs, users and schedules are loaded live from the EverGreen '
          'server, so changes need a connection.',
    );
  }

  void _showFeedbackSheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(),
            _sheetHeader('Send Feedback', Icons.feedback_outlined),
            const SizedBox(height: 4),
            TextField(
              controller: controller,
              maxLines: 4,
              style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tell us what’s working or what could be better…',
                filled: true,
                fillColor: const Color(0xFFF2F7F3),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _gradientButton('Submit Feedback', () async {
              final text = controller.text.trim();
              if (text.isEmpty) {
                _toast('Please write your feedback first', error: true);
                return;
              }
              Navigator.pop(ctx);
              await _shareFeedback(text);
            }),
          ],
        ),
      ),
    );
  }

  /// Read-only info is shown in a lightweight dialog rather than a bottom
  /// sheet — a sheet is only warranted when there's real interaction.
  void _showInfoDialog(String title, IconData icon, String body) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHeader(title, icon),
              const SizedBox(height: 8),
              Text(
                body,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  height: 1.55,
                  color: Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 20),
              _gradientButton('Got it', () => Navigator.pop(ctx)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _sheetHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _green, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C2B20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_green, _green2]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Montserrat')),
        backgroundColor: error ? AppColors.error : _green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reports / logout
  // ---------------------------------------------------------------------------
  /// Builds the design's two-part CSV from live tickets and companies and
  /// hands it to the system share sheet (clipboard if sharing is unavailable).
  Future<void> _exportServiceReport(BuildContext context) async {
    _toast('Preparing service report…');
    final repo = ref.read(evergreenRepositoryProvider);
    final List<ServiceTask> tasks;
    final List<Company> companies;
    try {
      final results = await Future.wait([repo.getTasks(), repo.getCompanies()]);
      tasks = results[0] as List<ServiceTask>;
      companies = results[1] as List<Company>;
    } catch (e) {
      if (mounted) _toast('Could not load report data: $e', error: true);
      return;
    }

    final now = DateTime.now();
    String date(DateTime? d) => d == null
        ? ''
        : '${d.year}-${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';
    bool done(ServiceTask t) =>
        t.status == TaskStatus.completed || t.status == TaskStatus.closed;

    final b = StringBuffer();
    b.writeln('EVERGREEN SERVICE REPORT');
    b.writeln('Generated,$now');
    b.writeln('');
    b.writeln(
      'Ticket,Title,Equipment,Company,Status,Priority,Assignee,Overdue,Rating',
    );
    for (final t in tasks) {
      final overdue = !done(t) && t.dueDate != null && t.dueDate!.isBefore(now);
      b.writeln(
        [
          t.ticketNo,
          t.name,
          t.equipment?.name ?? '',
          t.equipment?.company?.displayName ?? t.client?.name ?? '',
          t.status.label,
          t.priority.label,
          t.technician?.name ?? '',
          overdue ? 'YES' : 'no',
          t.rating?.toString() ?? '',
        ].map(_csv).join(','),
      );
    }
    b.writeln('');
    b.writeln('AMC Company,Branch,Status,End Date');
    for (final c in companies) {
      b.writeln(
        [
          c.name,
          c.branchName,
          _amcStatusLabel(c, now),
          date(c.endDate),
        ].map(_csv).join(','),
      );
    }

    final csv = b.toString();
    final filename = 'evergreen_service_report_${date(now)}.csv';
    var shared = false;
    try {
      shared = await Printing.sharePdf(
        bytes: utf8.encode(csv),
        filename: filename,
        subject: 'EverGreen service report',
      );
    } catch (_) {
      shared = false;
    }
    if (shared) return;
    await Clipboard.setData(ClipboardData(text: csv));
    if (!context.mounted) return;
    _toast('Service report (CSV) copied to clipboard');
  }

  /// Same buckets as the design's AMC status (30-day expiry window).
  String _amcStatusLabel(Company c, DateTime now) {
    if (!c.isActive) return 'Inactive';
    if (c.serviceType != CompanyServiceType.amc) return c.serviceLabel;
    final end = c.endDate;
    if (end == null) return 'Active';
    final days = end.difference(now).inDays;
    if (end.isBefore(now)) return 'Expired';
    if (days <= 30) return 'Expiring Soon';
    return 'Active';
  }

  String _csv(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  /// No feedback endpoint exists, so feedback goes out through the share sheet
  /// (mail, chat, ...) as a text attachment with the message in the body.
  Future<void> _shareFeedback(String text) async {
    final user = ref.read(currentUserProvider);
    final body = StringBuffer(text);
    if (user != null) {
      body
        ..writeln()
        ..writeln()
        ..writeln('From: ${user.name} (${user.phone})');
    }
    var shared = false;
    try {
      shared = await Printing.sharePdf(
        bytes: utf8.encode(body.toString()),
        filename: 'evergreen_feedback.txt',
        subject: 'EverGreen app feedback',
        body: body.toString(),
      );
    } catch (_) {
      shared = false;
    }
    if (shared || !mounted) return;
    await Clipboard.setData(ClipboardData(text: body.toString()));
    if (mounted) _toast('Feedback copied to clipboard');
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style:
              TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(
              'Logout',
              style: TextStyle(fontFamily: 'Montserrat', color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authControllerProvider).logout();
      if (mounted) context.go(Routes.login);
    }
  }
}

/// Owns the three password fields and the request; pops with the backend
/// success message.
class _ChangePasswordBody extends StatefulWidget {
  final Future<Either<Failure, String>> Function(String current, String next)
      submit;

  const _ChangePasswordBody({required this.submit});

  @override
  State<_ChangePasswordBody> createState() => _ChangePasswordBodyState();
}

class _ChangePasswordBodyState extends State<_ChangePasswordBody> {
  static const Color _green = Color(0xFF106220);
  static const Color _green2 = Color(0xFF0D5119);
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

  Future<void> _onSubmit() async {
    String? err;
    if (_current.text.isEmpty) {
      err = 'Enter your current password';
    } else if (_next.text.length < 6) {
      err = 'New password must be at least 6 characters';
    } else if (_next.text.length > 20) {
      err = 'New password must be at most 20 characters';
    } else if (_next.text != _confirm.text) {
      err = 'Passwords do not match';
    }
    if (err != null) {
      setState(() => _error = err);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await widget.submit(_current.text, _next.text);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = failure.displayMessage;
      }),
      (message) => Navigator.pop(context, message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, color: _green),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Change Password',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C2B20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _field(
            _current,
            'Current password',
            _hideCurrent,
            () => setState(() => _hideCurrent = !_hideCurrent),
          ),
          const SizedBox(height: 12),
          _field(
            _next,
            'New password',
            _hideNext,
            () => setState(() => _hideNext = !_hideNext),
          ),
          const SizedBox(height: 12),
          _field(
            _confirm,
            'Confirm new password',
            _hideConfirm,
            () => setState(() => _hideConfirm = !_hideConfirm),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _error ?? 'Use 6 to 20 characters.',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                color:
                    _error == null ? const Color(0xFF9B9B9B) : AppColors.error,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _saving ? null : () => Navigator.pop(context),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F7F3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _saving ? null : _onSubmit,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_green, _green2]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Update',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 15,
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
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint,
    bool hide,
    VoidCallback toggle,
  ) {
    return TextField(
      controller: c,
      obscureText: hide,
      enabled: !_saving,
      style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _green, width: 1.4),
        ),
      ),
    );
  }
}
