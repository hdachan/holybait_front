class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final bool needsConsent; // true면 동의 화면 표시

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.needsConsent,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken:  json['accessToken'] ?? '',
    refreshToken: json['refreshToken'] ?? '',
    needsConsent: json['needsConsent'] ?? false,
  );
}