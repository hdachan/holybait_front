import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/api_constants.dart';
import '../error/app_exception.dart';
import '../storage/secure_storage.dart';

// main.dart에서 선언한 전역 키
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
import '../../../main.dart' show navigatorKey;

class AuthInterceptor extends Interceptor {
  final Dio dio;
  bool _isRefreshing = false;
  bool _isShowingDialog = false;

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

      case AuthErrorCode.refreshTokenExpired:
      case AuthErrorCode.refreshTokenReused:
        await SecureStorage.clearAll();
        _showSessionExpiredDialog('세션이 만료됐습니다.\n다시 로그인해주세요.');
        handler.reject(DioException(
          requestOptions: err.requestOptions,
          error: AppException('세션이 만료됐습니다.', errorCode: errorCode),
        ));

      case AuthErrorCode.accessTokenInvalid:
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

  void _showSessionExpiredDialog(String message) {
    final context = navigatorKey.currentContext;
    if (context == null || _isShowingDialog) return;
    _isShowingDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1C0E04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Color(0xFFEF7910), size: 22),
            SizedBox(width: 8),
            Text('세션 만료',
                style: TextStyle(color: Colors.white, fontSize: 17,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _isShowingDialog = false;
                // 다이얼로그 닫기
                Navigator.of(dialogContext, rootNavigator: true).pop();
                // GoRouter로 로그인 화면 이동 (기존 스택 전부 제거)
                final rootContext = navigatorKey.currentContext;
                if (rootContext != null) {
                  GoRouter.of(rootContext).go('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF7910),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('다시 로그인',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    ).then((_) => _isShowingDialog = false);
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
      _showSessionExpiredDialog('세션이 만료됐습니다.\n다시 로그인해주세요.');
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}