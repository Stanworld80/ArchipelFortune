import 'package:flutter/foundation.dart';

class AppEnvironment {
  static const String version = '0.1.3';
  static const String buildNumber = '11';
  static const String lastUpdate = '12/04/2026 16:56';

  // Récupère la valeur de APP_ENV passée à la compilation (--dart-define=APP_ENV="dev")
  static const String envName = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  // Adresse email du Super Admin passée à la compilation (ou valeur par défaut vide)
  static const String superAdminEmail = String.fromEnvironment('SUPER_ADMIN_EMAIL', defaultValue: 'stanworld@gmail.com');

  static bool get isDev => envName == 'dev';
  static bool get isStaging => envName == 'staging';
  static bool get isProd => envName == 'prod';

  static String get googleSignInServerClientId {
    switch (envName) {
      case 'prod':
        return '417958901427-c88hjkvao549h2fpl5jn5bum21b735hl.apps.googleusercontent.com';
      case 'staging':
        return '344541548510-k1vncr9ufjii7r3k4425p8sqgq5p47r6.apps.googleusercontent.com';
      case 'dev':
      default:
        return '1025390075112-935ujpbqg9tr6tg2cnumqtljucpqpo4i.apps.googleusercontent.com';
    }
  }

  static void printEnv() {
    debugPrint('Current Environment: $envName');
    if (superAdminEmail.isNotEmpty) {
      debugPrint('Super Admin configured.');
    }
  }
}
