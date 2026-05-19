import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final Dio _dio = ApiClient.dio;

  Future<AuthResponse> loginWithGoogle(String idToken) async {
    final res = await _dio.post(ApiConstants.login, data: {
      'provider':   'GOOGLE',
      'idToken':    idToken,
      'deviceInfo': 'flutter_web',
    });
    return AuthResponse.fromJson(res.data);
  }

  Future<UserModel> getMe() async {
    final res = await _dio.get(ApiConstants.me);
    return UserModel.fromJson(res.data);
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post(ApiConstants.logout, data: {
      'refreshToken': refreshToken,
      'deviceInfo':   'flutter_web',
    });
  }

  Future<void> logoutAll() async {
    await _dio.post(ApiConstants.logoutAll);
  }

  Future<void> withdraw() async {
    await _dio.delete(ApiConstants.withdraw);
  }
}
