// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'EverGreen';

  @override
  String get dashboard => 'डैशबोर्ड';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get language => 'भाषा';

  @override
  String get pushNotifications => 'पुश नोटिफिकेशन';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get search => 'खोज';

  @override
  String get users => 'उपयोगकर्ता';

  @override
  String get tasks => 'कार्य';

  @override
  String get amcs => 'एएमसी';

  @override
  String get reports => 'रिपोर्ट और निर्यात';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get accountSettings => 'अकाउंट सेटिंग्स';

  @override
  String get preferences => 'प्राथमिकताएँ';

  @override
  String get account => 'अकाउंट';

  @override
  String get changePassword => 'पासवर्ड बदलें';

  @override
  String get manageRoles => 'भूमिकाएँ और अनुमतियाँ प्रबंधित करें';

  @override
  String languageSelected(Object language) {
    return 'भाषा $language पर सेट';
  }

  @override
  String get notificationsEnabled => 'नोटिफिकेशन सक्षम';

  @override
  String get notificationsDisabled => 'नोटिफिकेशन बंद';

  @override
  String get darkModeOn => 'डार्क मोड चालू';

  @override
  String get darkModeOff => 'डार्क मोड बंद';

  @override
  String get businessSummary => 'व्यापार सारांश';

  @override
  String get currentTotals => 'वर्तमान कुल';

  @override
  String get totalUsers => 'उपयोगकर्ता';

  @override
  String get totalTasks => 'कार्य';

  @override
  String get totalAmcs => 'एएमसी';

  @override
  String get overview => 'अवलोकन';

  @override
  String get thisMonth => 'इस महीने';

  @override
  String get openTasks => 'खुले कार्य';

  @override
  String get closedTasks => 'बंद कार्य';

  @override
  String get open => 'खुला';

  @override
  String get hold => 'होल्ड';

  @override
  String get inProgress => 'प्रगति में';

  @override
  String get closed => 'बंद';

  @override
  String get poc => 'पीओसी';

  @override
  String get companyManagers => 'कंपनी मैनेजर';

  @override
  String get egManagers => 'ईजी मैनेजर';

  @override
  String get serviceEngineers => 'सेवा इंजीनियर';

  @override
  String get allUsers => 'सभी उपयोगकर्ता';
}
