import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../error/app_exception.dart';
import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  bool _isRefreshing = false;

  AuthInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    if (statusCode == null) {
      handler.next(err);
      return;
    }
    if (statusCode != 401 && statusCode != 403) {
      handler.next(err);
      return;
    }

    String? code;
    try {
      final data = err.response?.data;
      if (data is Map) {
        code = data['code']?.toString();
      }
    } catch (_) {}

    final errorCode = AuthErrorCode.fromCode(code);

    switch (errorCode) {
      case AuthErrorCode.accessTokenExpired:
        await _handleRefresh(err, handler);

      case AuthErrorCode.accessTokenInvalid:
      case AuthErrorCode.refreshTokenExpired:
      case AuthErrorCode.refreshTokenReused:
      case AuthErrorCode.userBanned:
      case AuthErrorCode.userDeleted:
        await SecureStorage.clearAll();
        handler.reject(DioException(
          requestOptions: err.requestOptions,
          error: AppException('다시 로그인해주세요.', errorCode: errorCode),
        ));

      default:
        handler.next(err);
    }
  }

  Future<void> _handleRefresh(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    if (_isRefreshing) {
      handler.next(err);
      return;
    }
    _isRefreshing = true;

    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) throw Exception('refresh token 없음');

      final response = await dio.post(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken, 'deviceInfo': 'flutter_web'},
        options: Options(headers: {'Authorization': null}),
      );

      final newAccessToken  = response.data['accessToken']  as String;
      final newRefreshToken = response.data['refreshToken'] as String;

      await SecureStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      final retryResponse = await dio.fetch(
        err.requestOptions
          ..headers['Authorization'] = 'Bearer $newAccessToken',
      );
      handler.resolve(retryResponse);
    } catch (_) {
      await SecureStorage.clearAll();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}