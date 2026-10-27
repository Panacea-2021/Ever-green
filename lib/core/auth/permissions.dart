import '../../features/auth/domain/models/user_model.dart';
import '../router/routes.dart';

/// Central RBAC policy. Maps each [UserRole] to the set of route paths it is
/// allowed to open, plus a few capability helpers used by the UI (drawer,
/// buttons). Keeping this in one place makes the access rules auditable and
/// avoids scattering role checks across screens.
class Permissions {
  const Permissions._();

  /// Routes any authenticated user may access regardless of role.
  static const List<String> _common = [
    Routes.home,
    Routes.profile,
    Routes.settings,
    Routes.notifications,
    Routes.scanner,
    Routes.taskBoard,
    Routes.globalSearch,
    Routes.webDashboard,
    Routes.changePassword,
    // The backend scopes `getAuditLogs` per role (own actions, own company,
    // or everything for admins).
    Routes.auditLog,
  ];

  /// Super Admin can access everything, so this is only consulted for the
  /// other three roles. A role may open a route if it is in [_common] or in
  /// its own list below.
  static const Map<UserRole, List<String>> _roleRoutes = {
    UserRole.manager: [
      Routes.amcs,
      Routes.tasks,
      Routes.addTask,
      Routes.createIndividualTask,
      Routes.addEquipment,
      Routes.assignTasks,
      Routes.ticketQueue,
      Routes.createAmc,
      Routes.techniciansList,
      Routes.technicianTasks,
      Routes.amcRenewals,
      Routes.pmSchedule,
      Routes.analytics,
      Routes.technicianPerformance,
      Routes.uploadEquipments,
      Routes.uploadTechnicians,
      Routes.uploadAmc,
    ],
    // Senior Technician: a field lead — their own tasks plus the ability to
    // assign/reassign to junior technicians and see technician performance.
    UserRole.seniorTechnician: [
      Routes.tasks,
      Routes.technicianTasks,
      Routes.techniciansList,
      Routes.assignTasks,
      Routes.ticketQueue,
      Routes.technicianPerformance,
    ],
    UserRole.technician: [
      Routes.tasks,
      Routes.technicianTasks,
    ],
    // Client Admin: a client-side administrator — same read scope as a client
    // plus renewals and managing their own company's POCs/users.
    UserRole.clientAdmin: [
      Routes.amcs,
      Routes.tasks,
      Routes.amcRenewals,
      Routes.usersList,
      Routes.addUser,
      Routes.addTask,
    ],
    UserRole.client: [
      Routes.amcs,
      Routes.tasks,
      Routes.addTask,
    ],
  };

  static bool _isAdmin(UserRole role) =>
      role == UserRole.superAdmin || role == UserRole.manager;

  /// Whether [role] is allowed to open [path]. Super Admin always can.
  static bool canAccessRoute(UserRole role, String path) {
    if (role == UserRole.superAdmin) return true;
    if (_common.any((r) => path.startsWith(r))) return true;
    final allowed = _roleRoutes[role] ?? const [];
    return allowed.any((r) => path.startsWith(r));
  }

  // ---- Capability helpers (used to show/hide actions & menu items) ----

  /// Super Admin manages all users. Client Admin manages only their own
  /// company's POCs/users.
  static bool canManageUsers(UserRole role) =>
      role == UserRole.superAdmin || role == UserRole.clientAdmin;

  static bool canManageAmcs(UserRole role) =>
      role == UserRole.superAdmin || role == UserRole.manager;

  static bool canManageTasks(UserRole role) =>
      role == UserRole.superAdmin || role == UserRole.manager;

  /// Raising a ticket: admins, plus clients and Client Admins for their own
  /// company's equipment.
  static bool canRaiseTasks(UserRole role) =>
      canManageTasks(role) ||
      role == UserRole.clientAdmin ||
      role == UserRole.client;

  static bool canCreateIndividualTask(UserRole role) =>
      role == UserRole.superAdmin || role == UserRole.manager;

  /// Super Admin and Manager assign freely; a Senior Technician can assign or
  /// reassign work to junior technicians.
  static bool canAssignTasks(UserRole role) =>
      role == UserRole.superAdmin ||
      role == UserRole.manager ||
      role == UserRole.seniorTechnician;

  static bool canBulkUpload(UserRole role) =>
      role == UserRole.superAdmin || role == UserRole.manager;

  /// Every role has an Activity History; the backend decides whose entries
  /// it contains.
  static bool canViewAuditLog(UserRole role) => true;

  /// Whether the Activity History may filter by entity type. Only admins see
  /// other people's users/AMCs/equipment; everyone else gets just their own
  /// entries with search and date filters.
  static bool canFilterAuditByEntity(UserRole role) => _isAdmin(role);

  static bool canViewRenewals(UserRole role) =>
      role == UserRole.superAdmin ||
      role == UserRole.manager ||
      role == UserRole.clientAdmin;

  // ---- Bottom navigation / home layout ----

  /// Super Admin and Manager keep the Profile tab; other roles reach their
  /// account actions (e.g. Change Password) from the drawer.
  static bool hasProfileTab(UserRole role) => _isAdmin(role);

  /// Change Password lives in the drawer for roles without a Profile tab.
  static bool showChangePasswordInDrawer(UserRole role) => !hasProfileTab(role);

  /// The center "+" quick-action button. Hidden for service engineers.
  static bool hasCenterAction(UserRole role) => !role.isTechnicianLevel;

  /// Org-wide overview cards, Reports KPIs and the users-by-access-level
  /// chart on Home. Other roles only see their own tasks and alerts.
  static bool canViewOrgOverview(UserRole role) => _isAdmin(role);

  static bool canManagePmSchedule(UserRole role) =>
      role == UserRole.superAdmin || role == UserRole.manager;

  static bool canViewAnalytics(UserRole role) =>
      role == UserRole.superAdmin || role == UserRole.manager;

  static bool canViewTechnicianPerformance(UserRole role) =>
      role == UserRole.superAdmin ||
      role == UserRole.manager ||
      role == UserRole.seniorTechnician;

  /// Client-side roles get a read-only experience on service operations: they
  /// can view and confirm/rate, but not run the maintenance workflow.
  static bool isReadOnly(UserRole role) => role.isClientSide;
}
