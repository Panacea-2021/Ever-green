// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'EverGreen';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get logout => 'Logout';

  @override
  String get search => 'Search';

  @override
  String get users => 'Users';

  @override
  String get tasks => 'Tasks';

  @override
  String get amcs => 'AMCs';

  @override
  String get reports => 'Reports & Export';

  @override
  String get profile => 'Profile';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get preferences => 'Preferences';

  @override
  String get account => 'Account';

  @override
  String get changePassword => 'Change Password';

  @override
  String get manageRoles => 'Manage Roles & Permissions';

  @override
  String languageSelected(Object language) {
    return 'Language set to $language';
  }

  @override
  String get notificationsEnabled => 'Notifications enabled';

  @override
  String get notificationsDisabled => 'Notifications turned off';

  @override
  String get darkModeOn => 'Dark mode on';

  @override
  String get darkModeOff => 'Dark mode off';

  @override
  String get businessSummary => 'Business Summary';

  @override
  String get currentTotals => 'Current totals';

  @override
  String get totalUsers => 'Users';

  @override
  String get totalTasks => 'Tasks';

  @override
  String get totalAmcs => 'AMCs';

  @override
  String get overview => 'Overview';

  @override
  String get thisMonth => 'This month';

  @override
  String get openTasks => 'Open Tasks';

  @override
  String get closedTasks => 'Closed Tasks';

  @override
  String get open => 'Open';

  @override
  String get hold => 'Hold';

  @override
  String get inProgress => 'In Progress';

  @override
  String get closed => 'Closed';

  @override
  String get poc => 'POC';

  @override
  String get companyManagers => 'Company Managers';

  @override
  String get egManagers => 'EG Managers';

  @override
  String get serviceEngineers => 'Service Engineers';

  @override
  String get allUsers => 'All Users';
}
