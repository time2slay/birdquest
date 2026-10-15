/// Build-wide settings.
abstract final class AppConfig {
  /// Contact required by Wikimedia's User-Agent policy
  /// (https://meta.wikimedia.org/wiki/User-Agent_policy). Requests without a
  /// URL or email are rejected with HTTP 403.
  ///
  /// Set it here, or at build time:
  ///   flutter build apk --dart-define=WIKIMEDIA_CONTACT=support@example.com
  static const wikimediaContact = String.fromEnvironment(
    'WIKIMEDIA_CONTACT',
    defaultValue: 'scarjkeepari@gmail.com',
  );

  static bool get hasWikimediaContact =>
      wikimediaContact.contains('@') || wikimediaContact.startsWith('https://');

  static String get userAgent =>
      'BirdQuest/1.0 ($wikimediaContact; offline bird field guide for Android)';
}
