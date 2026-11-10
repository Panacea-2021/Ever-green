import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../shared/providers/auth_state_provider.dart';
import '../theme/web_tokens.dart';
import 'web_side_nav.dart';

/// Shared desktop app shell for authenticated web screens: a fixed left side
/// navigation rail + a top bar, with the page [child] in the content area.
/// On narrow widths the side nav collapses to an icon rail.
class WebAppShell extends ConsumerWidget {
  const WebAppShell({
    super.key,
    required this.activeRoute,
    required this.title,
    required this.child,
  });

  final String activeRoute;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(currentUserRoleProvider);

    Future<void> signOut() async {
      await ref.read(authControllerProvider).logout();
      if (context.mounted) context.go(Routes.home);
    }

    return Scaffold(
      backgroundColor: WebTokens.cream,
      body: Row(
        children: [
          WebSideNav(
            activeRoute: activeRoute,
            onNavigate: (route) {
              if (route != activeRoute) context.go(route);
            },
            onSignOut: signOut,
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  title: title,
                  userName: user?.name ?? 'User',
                  roleLabel: role.label,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.userName,
    required this.roleLabel,
  });

  final String title;
  final String userName;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: WebTokens.line)),
      ),
      child: Row(
        children: [
          Text(title, style: WebTokens.heading(22)),
          const Spacer(),
          // Search pill.
          Container(
            width: 260,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: WebTokens.cream,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: WebTokens.line),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: WebTokens.faint),
                const SizedBox(width: 8),
                Text('Search…', style: WebTokens.bodyText(13)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WebTokens.cream,
              shape: BoxShape.circle,
              border: Border.all(color: WebTokens.line),
            ),
            child: const Icon(
              Icons.notifications_none,
              size: 20,
              color: WebTokens.ink,
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: WebTokens.mintSoft,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontFamily: WebTokens.fontFamily,
                    fontWeight: FontWeight.w700,
                    color: WebTokens.green,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userName,
                    style: WebTokens.bodyText(
                      13.5,
                      color: WebTokens.ink,
                      weight: FontWeight.w700,
                    ),
                  ),
                  Text(roleLabel, style: WebTokens.bodyText(11.5)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
