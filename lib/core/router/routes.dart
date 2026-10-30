abstract class Routes {
  // Onboarding routes
  static const String splash = '/';
  static const String getStarted = '/get-started';

  // Auth routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String changePassword = '/change-password';

  // Main app routes
  static const String home = '/home';
  static const String dashboard = '/dashboard'; // Legacy, use home instead
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String amcs = '/amcs';
  static const String companyDetails = '/company-details';
  static const String companyTasks = '/company-tasks';
  static const String companyEquipments = '/company-equipments';
  static const String equipmentDetails = '/equipment-details';
  static const String equipmentQr = '/equipment-qr';
  static const String addEquipment = '/add-equipment';
  static const String addTask = '/add-task';
  static const String taskDetails = '/task-details';
  static const String tasks = '/tasks';
  static const String createIndividualTask = '/create-individual-task';

  // Feature routes
  static const String notifications = '/notifications';
  static const String scanner = '/scanner';
  static const String assignTasks = '/assign-tasks';
  static const String createAmc = '/create-amc';

  // Upload routes
  static const String uploadEquipments = '/upload-equipments';
  static const String uploadTechnicians = '/upload-technicians';
  static const String uploadAmc = '/upload-amc';

  // QR routes
  static const String downloadQr = '/download-qr';

  // Users routes
  static const String usersList = '/users-list';
  static const String addUser = '/add-user';

  // Technicians routes
  static const String techniciansList = '/technicians-list';
  static const String technicianTasks = '/technician-tasks';

  // Verified Equipments route
  static const String verifiedEquipments = '/verified-equipments';

  // Audit / Activity history (scoped per role by the backend)
  static const String auditLog = '/audit-log';

  // AMC renewals + expiry reminders
  static const String amcRenewals = '/amc-renewals';

  // Edit profile (full-screen, outside bottom-nav shell)
  static const String editProfile = '/edit-profile';

  // Dashboard analytics + export
  static const String analytics = '/analytics';

  // Role-aware task board (SLA, approvals, ratings)
  static const String taskBoard = '/task-board';

  // Unassigned / reassign ticket queue
  static const String ticketQueue = '/ticket-queue';

  // Technician performance & assignment intelligence
  static const String technicianPerformance = '/technician-performance';

  // Global search across companies/equipment/tasks/users
  static const String globalSearch = '/global-search';

  // Preventive-maintenance auto-scheduling
  static const String pmSchedule = '/pm-schedule';

  // Unauthorized / access-denied fallback
  static const String unauthorized = '/unauthorized';

  // Web-only: authenticated desktop dashboard (separate web UI).
  static const String webDashboard = '/web-dashboard';

  // Public marketing legal pages (website).
  static const String terms = '/terms';
  static const String privacy = '/privacy';
  static const String contact = '/contact';
  static const String services = '/services';
  static const String industries = '/industries';
  static const String technicians = '/technicians';
  static const String about = '/about';
  static const String howItWorks = '/how-it-works';
}
