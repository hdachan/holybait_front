import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/error/server_error.dart';
import 'package:dio/dio.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, banned, deleted, error }

class AuthProvider extends ChangeNotifier {
  final _repository = AuthRepository();

  AuthStatus _status = AuthStatus.initial;
  UserModel?  _user;
  String?     _errorMessage;
  bool        _needsConsent = false;

  AuthStatus get status       => _status;
  UserModel? get user         => _user;
  String?    get errorMessage => _errorMessage;
  bool get isAuthenticated    => _status == AuthStatus.authenticated;
  bool get needsConsent       => _needsConsent;
  bool get marketingAgreed    => _user?.marketingAgreed ?? false;

  Future<void> checkAuth() async {
    _set(AuthStatus.loading);
    try {
      if (await _repository.hasToken()) {
        _user = await _repository.getMe();
        // 기존 유저도 동의 안 했으면 동의 화면으로
        _needsConsent = !(_user?.consentCompleted ?? false);
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
      _needsConsent = await _repository.loginWithGoogle();
      _user = await _repository.getMe();
      _set(AuthStatus.authenticated);
    } on DioException catch (e) {
      // 정지·탈퇴 계정 — 서버가 code 로 알려줌 → 로그인 화면이 안내 표시
      final code = serverErrorCode(e);
      if (code == AuthErrorCode.userBanned.code) {
        _set(AuthStatus.banned);
        return;
      }
      if (code == AuthErrorCode.userDeleted.code) {
        _set(AuthStatus.deleted);
        return;
      }

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

  // 동의 완료 — 서버 저장에 성공했을 때만 true
  Future<bool> completeConsent({required bool marketingAgreed}) async {
    try {
      await _repository.completeConsent(marketingAgreed: marketingAgreed);
      _needsConsent = false;
      _user = await _repository.getMe();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '동의 처리에 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  // 서버의 최신 내 정보로 갱신 (걸음 저장 후 누적 걸음 반영 등)
  Future<void> refreshUser() async {
    try {
      _user = await _repository.getMe();
      notifyListeners();
    } catch (_) {
      // 실패하면 기존 정보 유지
    }
  }

  // 마케팅 동의 업데이트
  Future<bool> updateMarketingConsent(bool value) async {
    try {
      await _repository.updateMarketingConsent(value);
      _user = await _repository.getMe();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateNickname(String nickname) async {
    try {
      final updated = await _repository.updateNickname(nickname);
      _user = updated;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final serverMsg = e.response?.data is Map
          ? e.response?.data['message']
          : null;
      _errorMessage = serverMsg ?? '닉네임 변경에 실패했습니다.';
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = '닉네임 변경에 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _set(AuthStatus.loading);
    try {
      await _repository.logout();
    } catch (_) {} finally {
      _user = null;
      _needsConsent = false;
      _set(AuthStatus.unauthenticated);
    }
  }

  // 세션 만료·정지 등으로 서버가 로그인을 끊었을 때 (토큰은 인터셉터가 이미 지움)
  void clearSession() {
    _user = null;
    _needsConsent = false;
    _set(AuthStatus.unauthenticated);
  }

  // 탈퇴 — 서버 처리에 성공했을 때만 true (실패하면 로그인 상태 유지)
  Future<bool> withdraw() async {
    _set(AuthStatus.loading);
    try {
      await _repository.withdraw();
      _user = null;
      _set(AuthStatus.unauthenticated);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _set(AuthStatus.authenticated);
      return false;
    }
  }

  void _set(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
}