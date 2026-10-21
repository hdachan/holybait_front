import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/step_remote_ds.dart';
import '../../data/models/step_reward_model.dart';

// 걸음 측정 방식
// - 휴대폰 만보기 센서는 앱이 꺼져 있어도 "부팅 후 누적 걸음"을 계속 셈
// - 앱은 마지막으로 본 센서 값(last_counter)을 기억하고, 새 값과의 차이를 오늘 걸음에 더함
//   → 앱이 꺼져 있던 동안 걸은 걸음도 다음에 켤 때 반영됨
// - 날짜가 바뀌면 그날 걸음을 전송 대기 목록에 넣고, "걸은 날짜"로 서버에 저장 (누적 걸음은 다음 날 반영)
class StepProvider extends ChangeNotifier {
  final _remote = StepRemoteDataSource();

  static const _kStepDate = 'step_date';                 // 오늘 걸음의 날짜
  static const _kTodaySteps = 'today_steps';             // 오늘 걸음 수
  static const _kRewardedSteps = 'already_rewarded_steps'; // 이미 보상받은 걸음 수 (코인 * 1000)
  static const _kLastCounter = 'last_counter';           // 마지막으로 본 센서 값
  static const _kPendingLogs = 'pending_step_logs';      // 서버 전송 대기 {"2026-10-03": 8000}
  static const _kOwner = 'step_owner';                   // 위 걸음 정보의 주인 (유저 uuid)
  static const _maxPendingDays = 3; // 서버 StepService.MAX_STEP_LOG_DAYS_AGO 와 맞춤

  SharedPreferences? _prefs;
  StreamSubscription<StepCount>? _subscription;

  String _stepDate = '';
  int _todaySteps = 0;
  int _alreadyRewardedSteps = 0;
  int? _lastCounter;
  bool _isLoading = false;
  bool _permissionDenied = false;
  String? _error;

  // 걸음 기록이 서버에 저장됐을 때 호출 (누적 걸음 화면 갱신용)
  VoidCallback? onStepLogSaved;

  // 앱을 켜둔 채 날짜가 바뀌었을 때 (오늘 받은 신발코인 등 화면 정보 새로고침용)
  VoidCallback? onDayChanged;

  int get todaySteps => _todaySteps;
  bool get isLoading => _isLoading;
  bool get permissionDenied => _permissionDenied;
  String? get error => _error;

  // 받을 수 있는 코인 수
  int get claimableCoins =>
      (_todaySteps ~/ 1000) - (_alreadyRewardedSteps ~/ 1000);

  // 보상 버튼 활성화 여부
  bool get canClaim => claimableCoins > 0;

  // 앱 시작 시 초기화 — owner: 지금 로그인한 유저 uuid
  Future<void> init({required String owner}) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();

    // 이전 방식에서 쓰던 키 정리
    await prefs.remove('base_steps');
    await prefs.remove('last_sent_date');

    // 다른 계정이 남긴 걸음 정보면 비우고 0부터 시작
    // (센서 기준값도 지워서, 지금 계정은 로그인한 뒤 걸은 걸음부터 셈)
    // 주인 표시가 없는 기존 데이터는 지금 계정 것으로 이어받음
    final savedOwner = prefs.getString(_kOwner);
    if (savedOwner != null && savedOwner != owner) {
      await prefs.remove(_kLastCounter);
      await prefs.remove(_kStepDate);
      await prefs.remove(_kTodaySteps);
      await prefs.remove(_kRewardedSteps);
      await prefs.remove(_kPendingLogs);
    }
    await prefs.setString(_kOwner, owner);

    _stepDate = prefs.getString(_kStepDate) ?? _today();
    _todaySteps = prefs.getInt(_kTodaySteps) ?? 0;
    _alreadyRewardedSteps = prefs.getInt(_kRewardedSteps) ?? 0;
    _lastCounter = prefs.getInt(_kLastCounter);
    _rollOverIfNewDay();
    _saveToday();
    notifyListeners();

    await _sendPendingLogs();
    await _startPedometer();
  }

  // 로그아웃 직전 — 아직 보내지 못한 지난 걸음을 지금 계정으로 저장 (실패하면 버려짐)
  Future<void> sendPendingBeforeLogout() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _sendPendingLogs();
  }

  // 로그아웃 시 화면 값 비우기 — 저장된 걸음은 다음 init에서 주인 확인 후 처리
  void reset() {
    _subscription?.cancel();
    _subscription = null;
    onStepLogSaved = null;
    onDayChanged = null;
    _stepDate = '';
    _todaySteps = 0;
    _alreadyRewardedSteps = 0;
    _isLoading = false;
    _permissionDenied = false;
    _error = null;
    notifyListeners();
  }

  // 권한을 거절한 뒤 "권한 허용하기"를 눌렀을 때
  Future<void> requestPermissionAgain() async {
    if (await Permission.activityRecognition.isPermanentlyDenied) {
      // 다시 묻지 않음 상태 → 앱 설정 화면으로 이동
      await openAppSettings();
      return;
    }
    await _startPedometer();
  }

  // 만보계 시작
  Future<void> _startPedometer() async {
    if (kIsWeb) {
      _error = '걸음 수는 휴대폰 앱에서만 측정할 수 있어요.';
      notifyListeners();
      return;
    }

    // Android 10 이상은 신체 활동 권한을 실행 중에 받아야 센서 값이 들어옴
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) {
      _permissionDenied = true;
      _error = '걸음 수를 측정하려면 신체 활동 권한이 필요해요.';
      notifyListeners();
      return;
    }

    _permissionDenied = false;
    _error = null;
    notifyListeners();

    await _subscription?.cancel();
    _subscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: (error) {
        _error = '이 기기에서는 만보계를 사용할 수 없어요.';
        notifyListeners();
      },
    );
  }

  // 센서 값 수신 — 값은 "부팅 후 누적 걸음"
  void _onStepCount(StepCount event) {
    final counter = event.steps;
    final last = _lastCounter;

    int delta;
    if (last == null) {
      delta = 0; // 첫 측정 — 기준값만 저장
    } else if (counter >= last) {
      delta = counter - last;
    } else {
      delta = counter; // 재부팅으로 센서가 0부터 다시 셈
    }
    _lastCounter = counter;
    _prefs?.setInt(_kLastCounter, counter);

    // 앱을 켜둔 채 날짜가 바뀐 경우 어제 걸음을 전송 대기로 넘김
    final dayChanged = _rollOverIfNewDay();
    _todaySteps += delta;
    _saveToday();
    notifyListeners();

    if (dayChanged) {
      _sendPendingLogs();
      onDayChanged?.call();
    }
  }

  // 날짜가 바뀌었으면 지난 날 걸음을 전송 대기 목록에 넣고 오늘 값을 초기화
  bool _rollOverIfNewDay() {
    final today = _today();
    if (_stepDate == today) return false;

    if (_todaySteps > 0) {
      final pending = _readPending();
      pending[_stepDate] = _todaySteps;
      _writePending(pending);
    }
    _stepDate = today;
    _todaySteps = 0;
    _alreadyRewardedSteps = 0;
    _saveToday();
    return true;
  }

  // 전송 대기 중인 걸음을 걸은 날짜로 서버에 저장 — 실패한 날짜는 남겨두고 다음에 재전송
  Future<void> _sendPendingLogs() async {
    final pending = _readPending();
    if (pending.isEmpty) return;

    // 서버는 3일 전까지만 저장함 → 그보다 오래된 날짜는 보내지 않고 정리
    final oldest = DateTime.now().subtract(const Duration(days: _maxPendingDays));
    final oldestStr = oldest.toIso8601String().substring(0, 10);
    pending.removeWhere((date, _) => date.compareTo(oldestStr) < 0);

    var savedAny = false;
    for (final entry in pending.entries.toList()) {
      try {
        await _remote.saveStepLog(entry.value, entry.key);
        pending.remove(entry.key);
        savedAny = true;
      } catch (_) {
        // 네트워크 오류 등 — 다음 실행 때 다시 시도
      }
    }
    _writePending(pending);

    if (savedAny) onStepLogSaved?.call();
  }

  Map<String, int> _readPending() {
    final raw = _prefs?.getString(_kPendingLogs);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((date, steps) => MapEntry(date, (steps as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  void _writePending(Map<String, int> pending) {
    _prefs?.setString(_kPendingLogs, jsonEncode(pending));
  }

  void _saveToday() {
    _prefs?.setString(_kStepDate, _stepDate);
    _prefs?.setInt(_kTodaySteps, _todaySteps);
    _prefs?.setInt(_kRewardedSteps, _alreadyRewardedSteps);
  }

  String _today() => DateTime.now().toIso8601String().substring(0, 10);

  // 보상 받기 (버튼 누를 때)
  Future<StepRewardModel?> claimReward() async {
    if (!canClaim || _isLoading) return null;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _remote.claimReward(_todaySteps);

      if (result.success) {
        // 받은 코인만큼 already_rewarded_steps 업데이트
        _alreadyRewardedSteps += result.grantedCoins * 1000;
        _saveToday();
      }

      return result;
    } catch (e) {
      _error = '보상 받기에 실패했습니다.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
