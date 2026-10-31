import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/landing/presentation/screens/landing_page.dart';
import '../../features/landing/presentation/screens/terms_page.dart';
import '../../features/landing/presentation/screens/privacy_page.dart';
import '../../features/landing/presentation/screens/contact_page.dart';
import '../../features/landing/presentation/screens/services_page.dart';
import '../../features/landing/presentation/screens/technicians_page.dart';
import '../../features/landing/presentation/screens/website_info_page.dart';
import '../../web/screens/web_dashboard_screen.dart';
import '../../web/screens/web_task_board_screen.dart';
import '../../features/amcs/presentation/screens/add_equipment_screen.dart';
import '../../features/amcs/presentation/screens/add_task_screen.dart';
import '../../features/amcs/presentation/screens/amcs_screen.dart';
import '../../features/amcs/presentation/screens/create_amc_screen.dart';
import '../../features/amcs/presentation/screens/company_details_screen.dart';
import '../../features/amcs/presentation/screens/company_equipments_screen.dart';
import '../../features/amcs/presentation/screens/company_tasks_screen.dart';
import '../../features/amcs/presentation/screens/equipment_details_screen.dart';
import '../../features/amcs/presentation/screens/equipment_qr_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/registration_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/home_screen.dart';
import '../../features/dashboard/presentation/screens/analytics_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/get_started_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/scanner/presentation/screens/scanner_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tasks/domain/models/task_item.dart';
import '../../features/tasks/presentation/screens/task_details_screen.dart';
import '../../features/tasks/presentation/screens/task_board_screen.dart';
import '../../features/tasks/presentation/screens/unassigned_queue_screen.dart';
import '../../features/tasks/presentation/screens/assign_tasks_screen.dart';
import '../../features/tasks/presentation/screens/create_individual_task_screen.dart';
import '../../features/technicians/presentation/screens/technician_performance_screen.dart';
import '../../features/search/presentation/screens/global_search_screen.dart';
import '../../features/upload/presentation/screens/upload_equipments_screen.dart';
import '../../features/upload/presentation/screens/upload_amc_screen.dart';
import '../../features/upload/presentation/screens/upload_technicians_screen.dart';
import '../../features/qr/presentation/screens/download_qr_screen.dart';
import '../../features/users/presentation/screens/users_list_screen.dart';
import '../../features/users/presentation/screens/add_user_screen.dart';
import '../../features/technicians/presentation/screens/technicians_list_screen.dart';
import '../../features/technicians/presentation/screens/technician_tasks_screen.dart';
import '../../features/scanner/presentation/screens/verified_equipments_screen.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/audit/presentation/screens/audit_log_screen.dart';
import '../../features/amcs/presentation/screens/amc_renewals_screen.dart';
import '../../features/pm/presentation/screens/pm_schedule_screen.dart';
import '../../shared/providers/auth_state_provider.dart';
import '../../shared/widgets/unauthorized_screen.dart';
import '../auth/permissions.dart';
import '../widgets/scaffold_with_bottom_nav.dart';
import 'routes.dart';

/// Re-runs the router redirect whenever the auth state changes (sign-in,
/// sign-out, or a 401 flipping the session to unauthenticated) without
/// rebuilding the router and losing the navigation stack.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (previous?.status != next.status ||
          previous?.user?.role != next.user?.role) {
        notifyListeners();
      }
    });
  }
}

/// Sub-screens that `Permissions` doesn't list, gated by the route the user
/// opens them from (the backend scopes the data itself).
const _gateVia = {
  Routes.taskDetails: Routes.taskBoard,
  Routes.companyDetails: Routes.amcs,
  Routes.companyTasks: Routes.amcs,
  Routes.companyEquipments: Routes.amcs,
  Routes.equipmentDetails: Routes.scanner,
  Routes.equipmentQr: Routes.scanner,
  Routes.verifiedEquipments: Routes.scanner,
  Routes.editProfile: Routes.profile,
  Routes.dashboard: Routes.home,
};

String _gatePath(String path) {
  final segments = Uri.parse(path).pathSegments;
  final root = segments.isEmpty ? path : '/${segments.first}';
  return _gateVia[root] ?? path;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isAuthenticated = authState.isAuthenticated;
      final currentPath = state.matchedLocation;

      // Define public routes that don't require authentication
      final publicRoutes = [
        Routes.splash,
        Routes.getStarted,
        Routes.login,
        Routes.register,
        Routes.forgotPassword,
        // On the website the landing page is a public marketing page.
        if (kIsWeb) Routes.home,
        if (kIsWeb) Routes.terms,
        if (kIsWeb) Routes.privacy,
        if (kIsWeb) Routes.contact,
        if (kIsWeb) Routes.services,
        if (kIsWeb) Routes.industries,
        if (kIsWeb) Routes.technicians,
        if (kIsWeb) Routes.about,
        if (kIsWeb) Routes.howItWorks,
      ];

      final isPublicRoute = publicRoutes.contains(currentPath);

      // On web, send the splash straight to the public landing page instead of
      // the mobile onboarding/login flow.
      if (kIsWeb && currentPath == Routes.splash) {
        return Routes.home;
      }

      // Session restore still running: wait on the splash screen.
      if (authState.status == AuthStatus.unknown && !isPublicRoute) {
        return Routes.splash;
      }

      // If not authenticated (signed out, or a 401 expired the session) and
      // trying to access a protected route.
      if (!isAuthenticated && !isPublicRoute) {
        return Routes.login;
      }

      // If authenticated and on auth routes (except splash/getStarted which auto-navigate)
      if (isAuthenticated &&
          (currentPath == Routes.login || currentPath == Routes.register)) {
        return Routes.home;
      }

      // RBAC: block authenticated users from routes their role can't access.
      if (isAuthenticated &&
          !isPublicRoute &&
          currentPath != Routes.unauthorized) {
        final role = authState.user?.role ?? UserRole.client;
        if (!Permissions.canAccessRoute(role, _gatePath(currentPath))) {
          return Routes.unauthorized;
        }
      }

      return null;
    },
    routes: [
      // Onboarding routes
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.getStarted,
        name: 'getStarted',
        builder: (context, state) => const GetStartedScreen(),
      ),

      // Auth routes (no bottom navigation)
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        name: 'register',
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // Website pages open without a transition, like the landing page.
      GoRoute(
        path: Routes.terms,
        name: 'terms',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: TermsPage()),
      ),
      GoRoute(
        path: Routes.privacy,
        name: 'privacy',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: PrivacyPage()),
      ),
      GoRoute(
        path: Routes.contact,
        name: 'contact',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ContactPage()),
      ),
      GoRoute(
        path: Routes.services,
        name: 'services',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ServicesPage()),
      ),
      GoRoute(
        path: Routes.technicians,
        name: 'technicians',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: TechniciansPage()),
      ),
      GoRoute(
        path: Routes.industries,
        name: 'industries',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: WebsiteInfoPage(kind: WebsiteInfoKind.industries),
        ),
      ),
      GoRoute(
        path: Routes.about,
        name: 'about',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: WebsiteInfoPage(kind: WebsiteInfoKind.about),
        ),
      ),
      GoRoute(
        path: Routes.howItWorks,
        name: 'howItWorks',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: WebsiteInfoPage(kind: WebsiteInfoKind.howItWorks),
        ),
      ),

      // Feature routes (full screen, no bottom nav)
      GoRoute(
        path: Routes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: Routes.scanner,
        name: 'scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: Routes.assignTasks,
        name: 'assignTasks',
        builder: (context, state) => const AssignTasksScreen(),
      ),
      GoRoute(
        path: Routes.createIndividualTask,
        name: 'createIndividualTask',
        builder: (context, state) => const CreateIndividualTaskScreen(),
      ),
      GoRoute(
        path: Routes.createAmc,
        name: 'createAmc',
        builder: (context, state) => CreateAmcScreen(
          editCompany: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: Routes.uploadEquipments,
        name: 'uploadEquipments',
        builder: (context, state) => const UploadEquipmentsScreen(),
      ),
      GoRoute(
        path: Routes.uploadAmc,
        name: 'uploadAmc',
        builder: (context, state) => const UploadAmcScreen(),
      ),
      GoRoute(
        path: Routes.uploadTechnicians,
        name: 'uploadTechnicians',
        builder: (context, state) => const UploadTechniciansScreen(),
      ),
      GoRoute(
        path: Routes.downloadQr,
        name: 'downloadQr',
        builder: (context, state) => const DownloadQrScreen(),
      ),
      GoRoute(
        path: Routes.usersList,
        name: 'usersList',
        builder: (context, state) => UsersListScreen(
          initialTab:
              (state.extra as Map<String, dynamic>?)?['tab'] as int? ?? 0,
        ),
      ),
      GoRoute(
        path: Routes.addUser,
        name: 'addUser',
        builder: (context, state) => const AddUserScreen(),
      ),
      GoRoute(
        path: Routes.techniciansList,
        name: 'techniciansList',
        builder: (context, state) => const TechniciansListScreen(),
      ),
      GoRoute(
        path: Routes.technicianTasks,
        name: 'technicianTasks',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TechnicianTasksScreen(
            technicianId: extra?['technicianId'],
            technicianName: extra?['technicianName'],
          );
        },
      ),
      GoRoute(
        path: Routes.verifiedEquipments,
        name: 'verifiedEquipments',
        builder: (context, state) => const VerifiedEquipmentsScreen(),
      ),
      GoRoute(
        path: Routes.auditLog,
        name: 'auditLog',
        builder: (context, state) => const AuditLogScreen(),
      ),
      GoRoute(
        path: Routes.amcRenewals,
        name: 'amcRenewals',
        builder: (context, state) => const AmcRenewalsScreen(),
      ),
      GoRoute(
        path: Routes.pmSchedule,
        name: 'pmSchedule',
        builder: (context, state) => const PmScheduleScreen(),
      ),
      GoRoute(
        path: Routes.analytics,
        name: 'analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: Routes.editProfile,
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: Routes.changePassword,
        name: 'changePassword',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: Routes.taskBoard,
        name: 'taskBoard',
        builder: (context, state) => TaskBoardScreen(
          initialStatus:
              state.extra is TaskStatus ? state.extra! as TaskStatus : null,
        ),
      ),
      GoRoute(
        path: Routes.ticketQueue,
        name: 'ticketQueue',
        builder: (context, state) => const UnassignedQueueScreen(),
      ),
      GoRoute(
        path: Routes.technicianPerformance,
        name: 'technicianPerformance',
        builder: (context, state) => const TechnicianPerformanceScreen(),
      ),
      GoRoute(
        path: Routes.globalSearch,
        name: 'globalSearch',
        builder: (context, state) => const GlobalSearchScreen(),
      ),
      GoRoute(
        path: Routes.unauthorized,
        name: 'unauthorized',
        builder: (context, state) => const UnauthorizedScreen(),
      ),
      GoRoute(
        path: '${Routes.companyDetails}/:companyId',
        name: 'companyDetails',
        builder: (context, state) {
          final companyId = state.pathParameters['companyId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return CompanyDetailsScreen(
            companyId: companyId,
            companyName: extra?['companyName'],
            location: extra?['location'],
            imageUrl: extra?['imageUrl'],
          );
        },
      ),
      GoRoute(
        path: '${Routes.companyTasks}/:companyId',
        name: 'companyTasks',
        builder: (context, state) {
          final companyId = state.pathParameters['companyId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return CompanyTasksScreen(
            companyId: companyId,
            companyName: extra?['companyName'],
          );
        },
      ),
      GoRoute(
        path: '${Routes.companyEquipments}/:companyId',
        name: 'companyEquipments',
        builder: (context, state) {
          final companyId = state.pathParameters['companyId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return CompanyEquipmentsScreen(
            companyId: companyId,
            companyName: extra?['companyName'],
          );
        },
      ),
      GoRoute(
        path: '${Routes.equipmentDetails}/:equipmentId',
        name: 'equipmentDetails',
        builder: (context, state) {
          final equipmentId = state.pathParameters['equipmentId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return EquipmentDetailsScreen(
            equipmentId: equipmentId,
            equipmentName: extra?['equipmentName'],
            location: extra?['location'],
            imageUrl: extra?['imageUrl'],
            make: extra?['make'],
            model: extra?['model'],
            serialNumber: extra?['serialNumber'],
            companyId: extra?['companyId'] as String?,
            companyName: extra?['companyName'] as String?,
          );
        },
      ),
      GoRoute(
        path: '${Routes.equipmentQr}/:equipmentId',
        name: 'equipmentQr',
        builder: (context, state) {
          final equipmentId = state.pathParameters['equipmentId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return EquipmentQrScreen(
            equipmentId: equipmentId,
            equipmentName: extra?['equipmentName'],
            serialNumber: extra?['serialNumber'],
          );
        },
      ),
      GoRoute(
        path: '${Routes.addEquipment}/:companyId',
        name: 'addEquipment',
        builder: (context, state) {
          final companyId = state.pathParameters['companyId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return AddEquipmentScreen(
            companyId: companyId,
            companyName: extra?['companyName'],
            editEquipment: extra?['editEquipment'] as Map<String, dynamic>?,
          );
        },
      ),
      GoRoute(
        path: '${Routes.addTask}/:companyId',
        name: 'addTask',
        builder: (context, state) {
          final companyId = state.pathParameters['companyId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return AddTaskScreen(
            companyId: companyId,
            companyName: extra?['companyName'] as String?,
            preselectEquipment: extra?['preselectEquipment'] as String?,
            preselectEquipmentSpecs: (extra?['preselectEquipmentSpecs'] as Map?)
                ?.map((k, v) => MapEntry(k.toString(), v.toString())),
            isEdit: extra?['isEdit'] == true,
            editTask: extra?['editTask'] as Map<String, dynamic>?,
          );
        },
      ),
      GoRoute(
        path: '${Routes.taskDetails}/:taskId',
        name: 'taskDetails',
        builder: (context, state) {
          final taskId = state.pathParameters['taskId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return TaskDetailsScreen(
            taskId: taskId,
            taskTitle: extra?['taskTitle'],
            location: extra?['location'],
            status: extra?['status'],
            imageUrl: extra?['imageUrl'],
            companyName: extra?['companyName'],
            clientName: extra?['clientName'],
            mobile: extra?['mobile'],
            technician: extra?['technician'],
            technicianMobile: extra?['technicianMobile'],
            createdOn: extra?['createdOn'],
            serialNumber: extra?['serialNumber'],
            description: extra?['description'],
            lastUpdatedOn: extra?['lastUpdatedOn'],
          );
        },
      ),

      // Main app routes with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          // On web the screens render their own full-page layout (top nav +
          // footer), so skip the mobile bottom-nav shell.
          if (kIsWeb) return child;
          return ScaffoldWithBottomNav(child: child);
        },
        routes: [
          GoRoute(
            path: Routes.home,
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              // Completely different design on web vs mobile; same providers.
              child: kIsWeb ? LandingPage() : HomeScreen(),
            ),
          ),
          GoRoute(
            path: Routes.amcs,
            name: 'amcs',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AmcsScreen(),
            ),
          ),
          GoRoute(
            path: Routes.tasks,
            name: 'tasks',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: kIsWeb
                  ? WebTaskBoardScreen()
                  : TaskBoardScreen(isRootTab: true),
            ),
          ),
          GoRoute(
            path: Routes.profile,
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
          GoRoute(
            path: Routes.settings,
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),

      // Legacy dashboard (superseded by home, kept for old links).
      GoRoute(
        path: Routes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // Web-only authenticated dashboard (full-page web shell, no bottom nav).
      GoRoute(
        path: Routes.webDashboard,
        name: 'webDashboard',
        builder: (context, state) => const WebDashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.error?.message ?? 'Unknown error'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(Routes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
