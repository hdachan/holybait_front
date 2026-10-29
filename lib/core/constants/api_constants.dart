class ApiConstants {
  // 릴리즈 빌드: --dart-define=API_BASE_URL=https://api.holyhabit.co.kr
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String login     = '/auth/login';
  static const String refresh   = '/auth/refresh';
  static const String logout    = '/auth/logout';
  static const String withdraw  = '/auth/withdraw';
  static const String me        = '/auth/me';
}
