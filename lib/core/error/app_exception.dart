enum AuthErrorCode {
  accessTokenExpired('401_001'),
  accessTokenInvalid('401_002'),
  refreshTokenExpired('401_003'),
  refreshTokenReused('401_004'),
  userBanned('403_001'),
  userDeleted('403_002'),
  unknown('UNKNOWN');

  final String code;
  const AuthErrorCode(this.code);

  static AuthErrorCode fromCode(String? code) {
    return AuthErrorCode.values.firstWhere(
          (e) => e.code == code,
      orElse: () => AuthErrorCode.unknown,
    );
  }
}

class AppException implements Exception {
  final String message;
  final AuthErrorCode? errorCode;

  AppException(this.message, {this.errorCode});

  @override
  String toString() => 'AppException: $message (${errorCode?.code})';
}