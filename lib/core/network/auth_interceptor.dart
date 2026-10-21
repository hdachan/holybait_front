import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../constants/api_constants.dart';
import '../device/device_info.dart';
import '../session/reset_user_data.dart';
import '../error/app_exception.dart';
import '../storage/secure_storage.dart';

// main.dart에서 선언한 전역 키
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
import '../../../main.dart' show navigatorKey, scaffoldMessengerKey;

class AuthInterceptor extends Interceptor {
  final Dio dio;

  bool _isShowingDialog = false;

  AuthInterceptor(this.dio);

  // 토큰 없이 호출해야 하는 인증 관련 경로
  bool _isAuthPath(String path) =>
      path.contains('/auth/login') || path.contains('/auth/refresh');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 로그인/토큰갱신 요청에는 (만료됐을 수 있는) 기존 토큰을 붙이지 않음
    if (_isAuthPath(options.path)) {
      options.headers.remove('Authorization');
      handler.next(options);
      return;
    }

    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 로그인/토큰갱신 요청 실패는 세션만료 처리하지 않고 그대로 전달
    if (_isAuthPath(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    final statusCode = err.response?.statusCode;
    if (_isConnectionProblem(err)) {
      _showConnectionNotice();
      handler.next(err);
      return;
    }
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
        // 사용 중 정지·탈퇴되거나 토큰이 잘못된 경우 — 안내 후 로그인 화면으로
        await SecureStorage.clearAll();
        switch (errorCode) {
          case AuthErrorCode.userBanned:
            _showSessionExpiredDialog('정지된 계정입니다.\n고객센터에 문의해주세요.', title: '로그인 불가');
          case AuthErrorCode.userDeleted:
            _showSessionExpiredDialog('탈퇴한 계정입니다.', title: '로그인 불가');
          default:
            _showSessionExpiredDialog('로그인 정보가 올바르지 않습니다.\n다시 로그인해주세요.');
        }
        handler.reject(DioException(
          requestOptions: err.requestOptions,
          error: AppException('다시 로그인해주세요.', errorCode: errorCode),
        ));

      default:
        handler.next(err);
    }
  }

  void _showSessionExpiredDialog(String message, {String title = '세션 만료'}) {
    final context = navigatorKey.currentContext;
    if (context == null || _isShowingDialog) return;
    _isShowingDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1C0E04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: Color(0xFFEF7910), size: 22),
            const SizedBox(width: 8),
            Text(title,
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
                  // 이전 계정 정보 비우기 (다음 로그인 계정에 남지 않게)
                  rootContext.read<AuthProvider>().clearSession();
                  resetUserData(rootContext);
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

  // access 토큰 만료(401_001) — 새 토큰을 받아 원래 요청을 다시 보냄
  // 여러 요청이 동시에 만료되면 재발급은 한 번만 하고, 나머지는 그 결과를 기다렸다가 재시도
  Future<void> _handleRefresh(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    final sentToken = err.requestOptions.headers['Authorization'];
    final currentToken = await SecureStorage.getAccessToken();

    String? newAccessToken;
    if (currentToken != null && sentToken != 'Bearer $currentToken') {
      // 이 요청이 나간 뒤 다른 요청이 이미 재발급을 끝냄 → 새 토큰으로 재시도만
      newAccessToken = currentToken;
    } else {
      newAccessToken = await _refreshOnce();
    }

    if (newAccessToken == null) {
      handler.next(err);
      return;
    }

    // 재시도 실패는 그 요청의 일반 에러로 전달 (세션 만료로 처리하지 않음)
    try {
      final retryResponse = await dio.fetch(
        err.requestOptions
          ..headers['Authorization'] = 'Bearer $newAccessToken',
      );
      handler.resolve(retryResponse);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  // 진행 중인 재발급이 있으면 그 결과를 함께 기다림. 실패하면 null (세션 만료 처리)
  Completer<String?>? _refreshing;

  Future<String?> _refreshOnce() {
    final inProgress = _refreshing;
    if (inProgress != null) return inProgress.future;

    final completer = _refreshing = Completer<String?>();
    () async {
      try {
        final refreshToken = await SecureStorage.getRefreshToken();
        if (refreshToken == null) throw Exception('refresh token 없음');

        final response = await dio.post(
          ApiConstants.refresh,
          data: {'refreshToken': refreshToken, 'deviceInfo': deviceInfoLabel},
          options: Options(headers: {'Authorization': null}),
        );

        final newAccessToken  = response.data['accessToken']  as String;
        final newRefreshToken = response.data['refreshToken'] as String;

        await SecureStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );
        completer.complete(newAccessToken);
      } on DioException catch (e) {
        // 서버가 재발급을 거절(401_003 만료 / 401_004 재사용 의심 등)했을 때만 로그아웃
        // 인터넷 끊김·서버 재시작·서버 오류는 로그인을 유지 → 이번 요청만 실패, 다음에 다시 시도
        final status = e.response?.statusCode;
        if (status == 401 || status == 403) {
          await _endSession();
        } else if (_isConnectionProblem(e)) {
          _showConnectionNotice();
        }
        completer.complete(null);
      } catch (_) {
        // 저장된 재발급권이 없음 등
        await _endSession();
        completer.complete(null);
      } finally {
        _refreshing = null;
      }
    }();
    return completer.future;
  }

  // 응답을 못 받음(인터넷 끊김·시간 초과·서버 꺼짐) 또는 서버 앞단(Nginx)이 서버 없음을 알림(502/503/504)
  bool _isConnectionProblem(DioException e) {
    final status = e.response?.statusCode;
    if (status == 502 || status == 503 || status == 504) return true;
    if (e.response != null) return false;
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.unknown;
  }

  // 화면 아래 안내 — 동시에 여러 요청이 실패해도 몇 초에 한 번만
  DateTime? _lastConnectionNotice;

  void _showConnectionNotice() {
    final now = DateTime.now();
    final last = _lastConnectionNotice;
    if (last != null && now.difference(last) < const Duration(seconds: 4)) return;
    _lastConnectionNotice = now;

    scaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(
      content: Text('연결이 원활하지 않아요. 인터넷 연결을 확인하고 다시 시도해주세요.'),
      backgroundColor: Color(0xFF616161),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 3),
    ));
  }

  Future<void> _endSession() async {
    await SecureStorage.clearAll();
    _showSessionExpiredDialog('세션이 만료됐습니다.\n다시 로그인해주세요.');
  }
}