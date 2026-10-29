import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../datasources/auth_remote_ds.dart';
import '../datasources/auth_local_ds.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _remote = AuthRemoteDataSource();
  final _local  = AuthLocalDataSource();
  static const _googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

  final _googleSignIn = GoogleSignIn(
    clientId: _googleClientId,
    // Android: 서버(웹 클라이언트 ID)용 idToken 을 받아 서버의 idToken 검증 경로로 로그인
    // (웹은 serverClientId 를 지원하지 않음)
    serverClientId: kIsWeb || _googleClientId.isEmpty ? null : _googleClientId,
    scopes: ['email', 'profile'],
  );

  Future<bool> hasToken() async {
    final token = await _local.getAccessToken();
    return token != null;
  }

  // 로그인 → needsConsent 반환
  Future<bool> loginWithGoogle() async {
    GoogleSignInAccount? googleUser;

    if (kIsWeb) {
      googleUser = await _googleSignIn.signInSilently();
      googleUser ??= await _googleSignIn.signIn();
    } else {
      googleUser = await _googleSignIn.signIn();
    }

    if (googleUser == null) throw Exception('Google 로그인 취소');

    final googleAuth = await googleUser.authentication;
    final token = googleAuth.idToken ?? googleAuth.accessToken;
    if (token == null) throw Exception('토큰 없음');

    final authResponse = await _remote.loginWithGoogle(token);

    await _local.saveTokens(
      accessToken:  authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
    );

    return authResponse.needsConsent;
  }

  Future<UserModel> getMe() => _remote.getMe();

  Future<UserModel> updateNickname(String nickname) =>
      _remote.updateNickname(nickname);

  Future<void> completeConsent({required bool marketingAgreed}) =>
      _remote.completeConsent(marketingAgreed: marketingAgreed);

  Future<void> updateMarketingConsent(bool value) =>
      _remote.updateMarketingConsent(value);

  Future<void> logout() async {
    final refreshToken = await _local.getRefreshToken();
    if (refreshToken != null) await _remote.logout(refreshToken);
    await _local.clearAll();
    await _googleSignIn.signOut();
  }

  Future<void> withdraw() async {
    await _remote.withdraw();
    await _local.clearAll();
    await _googleSignIn.signOut();
  }
}