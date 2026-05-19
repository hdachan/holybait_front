import '../../core/storage/secure_storage.dart';

class AuthLocalDataSource {
  Future<String?> getAccessToken()  => SecureStorage.getAccessToken();
  Future<String?> getRefreshToken() => SecureStorage.getRefreshToken();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) =>
      SecureStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

  Future<void> clearAll() => SecureStorage.clearAll();
}
