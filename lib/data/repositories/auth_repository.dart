import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../datasources/auth_remote_ds.dart';
import '../datasources/auth_local_ds.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _remote = AuthRemoteDataSource();
  final _local  = AuthLocalDataSource();
  final _googleSignIn = GoogleSignIn(
    clientId: const String.fromEnvironment('GOOGLE_CLIENT_ID'),
    scopes: ['email', 'profile'],
  );

  Future<bool> hasToken() async {
    final token = await _local.getAccessToken();
    return token != null;
  }

  Future<void> loginWithGoogle() async {
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
  }

  Future<UserModel> getMe() => _remote.getMe();

  Future<void> logout() async {
    final refreshToken = await _local.getRefreshToken();
    if (refreshToken != null) await _remote.logout(refreshToken);
    await _local.clearAll();
    await _googleSignIn.signOut();
  }

  Future<void> logoutAll() async {
    await _remote.logoutAll();
    await _local.clearAll();
    await _googleSignIn.signOut();
  }

  Future<void> withdraw() async {
    await _remote.withdraw();
    await _local.clearAll();
    await _googleSignIn.signOut();
  }
}