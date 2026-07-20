abstract final class GoogleConfig {
  /// Web Client ID from Google Cloud Console (OAuth 2.0).
  /// Override at build: --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
  static const String webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '624980210355-2pajnkj49kl8pivjeusaaekuac1b3ei3.apps.googleusercontent.com',
  );
}
