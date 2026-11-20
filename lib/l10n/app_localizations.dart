import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ta'),
    Locale('te')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'EverGreen'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @amcs.
  ///
  /// In en, this message translates to:
  /// **'AMCs'**
  String get amcs;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports & Export'**
  String get reports;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @manageRoles.
  ///
  /// In en, this message translates to:
  /// **'Manage Roles & Permissions'**
  String get manageRoles;

  /// No description provided for @languageSelected.
  ///
  /// In en, this message translates to:
  /// **'Language set to {language}'**
  String languageSelected(Object language);

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications turned off'**
  String get notificationsDisabled;

  /// No description provided for @darkModeOn.
  ///
  /// In en, this message translates to:
  /// **'Dark mode on'**
  String get darkModeOn;

  /// No description provided for @darkModeOff.
  ///
  /// In en, this message translates to:
  /// **'Dark mode off'**
  String get darkModeOff;

  /// No description provided for @businessSummary.
  ///
  /// In en, this message translates to:
  /// **'Business Summary'**
  String get businessSummary;

  /// No description provided for @currentTotals.
  ///
  /// In en, this message translates to:
  /// **'Current totals'**
  String get currentTotals;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get totalUsers;

  /// No description provided for @totalTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get totalTasks;

  /// No description provided for @totalAmcs.
  ///
  /// In en, this message translates to:
  /// **'AMCs'**
  String get totalAmcs;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @openTasks.
  ///
  /// In en, this message translates to:
  /// **'Open Tasks'**
  String get openTasks;

  /// No description provided for @closedTasks.
  ///
  /// In en, this message translates to:
  /// **'Closed Tasks'**
  String get closedTasks;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @hold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get hold;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @poc.
  ///
  /// In en, this message translates to:
  /// **'POC'**
  String get poc;

  /// No description provided for @companyManagers.
  ///
  /// In en, this message translates to:
  /// **'Company Managers'**
  String get companyManagers;

  /// No description provided for @egManagers.
  ///
  /// In en, this message translates to:
  /// **'EG Managers'**
  String get egManagers;

  /// No description provided for @serviceEngineers.
  ///
  /// In en, this message translates to:
  /// **'Service Engineers'**
  String get serviceEngineers;

  /// No description provided for @allUsers.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get allUsers;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @taskBoard.
  ///
  /// In en, this message translates to:
  /// **'Task Board'**
  String get taskBoard;

  /// No description provided for @usersList.
  ///
  /// In en, this message translates to:
  /// **'Users List'**
  String get usersList;

  /// No description provided for @amcRenewals.
  ///
  /// In en, this message translates to:
  /// **'AMC Renewals'**
  String get amcRenewals;

  /// No description provided for @pmSchedule.
  ///
  /// In en, this message translates to:
  /// **'PM Schedule'**
  String get pmSchedule;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @scanner.
  ///
  /// In en, this message translates to:
  /// **'Scanner'**
  String get scanner;

  /// No description provided for @companyList.
  ///
  /// In en, this message translates to:
  /// **'Company\'s List'**
  String get companyList;

  /// No description provided for @myTasks.
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get myTasks;

  /// No description provided for @myServiceTasks.
  ///
  /// In en, this message translates to:
  /// **'My Service Tasks'**
  String get myServiceTasks;

  /// No description provided for @createTask.
  ///
  /// In en, this message translates to:
  /// **'Create Task'**
  String get createTask;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @technicians.
  ///
  /// In en, this message translates to:
  /// **'Service Engineers'**
  String get technicians;

  /// No description provided for @ticketQueue.
  ///
  /// In en, this message translates to:
  /// **'Ticket Queue'**
  String get ticketQueue;

  /// No description provided for @createCompany.
  ///
  /// In en, this message translates to:
  /// **'Create Company'**
  String get createCompany;

  /// No description provided for @activityHistory.
  ///
  /// In en, this message translates to:
  /// **'Activity History'**
  String get activityHistory;

  /// No description provided for @enquiries.
  ///
  /// In en, this message translates to:
  /// **'Enquiries'**
  String get enquiries;

  /// No description provided for @globalSearch.
  ///
  /// In en, this message translates to:
  /// **'Global Search'**
  String get globalSearch;

  /// No description provided for @addEquipment.
  ///
  /// In en, this message translates to:
  /// **'Add Equipment'**
  String get addEquipment;

  /// No description provided for @createAmc.
  ///
  /// In en, this message translates to:
  /// **'Create Company'**
  String get createAmc;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @downloadQr.
  ///
  /// In en, this message translates to:
  /// **'Download QR'**
  String get downloadQr;

  /// No description provided for @technicianPerformance.
  ///
  /// In en, this message translates to:
  /// **'Service Engineer Performance'**
  String get technicianPerformance;

  /// No description provided for @auditLog.
  ///
  /// In en, this message translates to:
  /// **'Activity History'**
  String get auditLog;

  /// No description provided for @pmScheduleShort.
  ///
  /// In en, this message translates to:
  /// **'PM Schedule'**
  String get pmScheduleShort;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @exportServiceReport.
  ///
  /// In en, this message translates to:
  /// **'Export Service Report (CSV)'**
  String get exportServiceReport;

  /// No description provided for @offlineData.
  ///
  /// In en, this message translates to:
  /// **'Offline Data'**
  String get offlineData;

  /// No description provided for @cached.
  ///
  /// In en, this message translates to:
  /// **'Cached'**
  String get cached;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @equipmentList.
  ///
  /// In en, this message translates to:
  /// **'Equipment List'**
  String get equipmentList;

  /// No description provided for @createIndividualTask.
  ///
  /// In en, this message translates to:
  /// **'Create Individual Task'**
  String get createIndividualTask;

  /// No description provided for @issueTypes.
  ///
  /// In en, this message translates to:
  /// **'Issue Types'**
  String get issueTypes;

  /// No description provided for @uploadEquipments.
  ///
  /// In en, this message translates to:
  /// **'Upload Equipments Excel Data'**
  String get uploadEquipments;

  /// No description provided for @uploadTechnicians.
  ///
  /// In en, this message translates to:
  /// **'Upload Service Engineers Excel Data'**
  String get uploadTechnicians;

  /// No description provided for @uploadCompanies.
  ///
  /// In en, this message translates to:
  /// **'Upload Company Excel Data'**
  String get uploadCompanies;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'MENU'**
  String get menu;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'ta', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
