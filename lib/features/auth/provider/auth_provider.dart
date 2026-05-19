import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../core/error/app_exception.dart';
import 'package:dio/dio.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, banned, deleted, error }

class AuthProvider extends ChangeNotifier {
  final _repository = AuthRepository();

  AuthStatus _status = AuthStatus.initial;
  UserModel?  _user;
  String?     _errorMessage;

  AuthStatus get status       => _status;
  UserModel? get user         => _user;
  String?    get errorMessage => _errorMessage;
  bool get isAuthenticated    => _status == AuthStatus.authenticated;

  Future<void> checkAuth() async {
    _set(AuthStatus.loading);
    try {
      if (await _repository.hasToken()) {
        _user = await _repository.getMe();
        _set(AuthStatus.authenticated);
      } else {
        _set(AuthStatus.unauthenticated);
      }
    } catch (_) {
      _set(AuthStatus.unauthenticated);
    }
  }

  Future<void> loginWithGoogle() async {
    _set(AuthStatus.loading);
    try {
      await _repository.loginWithGoogle();
      _user = await _repository.getMe();
      _set(AuthStatus.authenticated);
    } on DioException catch (e) {
      // 네트워크 / 서버 연결 오류
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        _errorMessage = '서버에 연결할 수 없습니다.\n잠시 후 다시 시도해주세요.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        _errorMessage = '연결 시간이 초과됐습니다.\n네트워크 상태를 확인해주세요.';
      } else {
        _errorMessage = '로그인 중 오류가 발생했습니다.';
      }
      _set(AuthStatus.error);
    } on AppException catch (e) {
      switch (e.errorCode) {
        case AuthErrorCode.userBanned:
          _set(AuthStatus.banned);
        case AuthErrorCode.userDeleted:
          _set(AuthStatus.deleted);
        case AuthErrorCode.refreshTokenReused:
          _errorMessage = '비정상적인 접근이 감지됐습니다.\n다시 로그인해주세요.';
          _set(AuthStatus.error);
        default:
          _errorMessage = '로그인에 실패했습니다.\n다시 시도해주세요.';
          _set(AuthStatus.error);
      }
    } catch (e) {
      if (e.toString().contains('Google 로그인 취소')) {
        _set(AuthStatus.unauthenticated);
        return;
      }
      _errorMessage = '알 수 없는 오류가 발생했습니다.';
      _set(AuthStatus.error);
    }
  }

  Future<void> logout() async {
    _set(AuthStatus.loading);
    try {
      await _repository.logout();
    } catch (_) {} finally {
      _user = null;
      _set(AuthStatus.unauthenticated);
    }
  }

  Future<void> withdraw() async {
    _set(AuthStatus.loading);
    try {
      await _repository.withdraw();
      _user = null;
      _set(AuthStatus.unauthenticated);
    } catch (e) {
      _errorMessage = e.toString();
      _set(AuthStatus.error);
    }
  }

  void _set(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
}
