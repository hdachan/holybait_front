import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/step_remote_ds.dart';
import '../../data/models/step_reward_model.dart';


class StepProvider extends ChangeNotifier {
  final _remote = StepRemoteDataSource();

  int _todaySteps = 0;           // 오늘 총 걸음 수
  int _alreadyRewardedSteps = 0; // 이미 보상받은 걸음 수 (코인 * 1000)
  bool _isLoading = false;
  String? _error;

  int get todaySteps => _todaySteps;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 받을 수 있는 코인 수
  int get claimableCoins =>
      (_todaySteps ~/ 1000) - (_alreadyRewardedSteps ~/ 1000);

  // 보상 버튼 활성화 여부
  bool get canClaim => claimableCoins > 0;

  // 앱 시작 시 초기화
  Future<void> init() async {
    await _sendPendingSteps(); // 못 보낸 날짜 걸음 수 처리
    await _loadTodaySteps();   // 오늘 걸음 수 로드
    _startPedometer();         // 만보계 시작
  }

  // 만보계 시작
  void _startPedometer() {
    Pedometer.stepCountStream.listen(
          (StepCount event) async {
        final prefs = await SharedPreferences.getInstance();
        final baseSteps = prefs.getInt('base_steps') ?? event.steps;

        // 오늘 걸음 수 = 현재 누적 - 오늘 시작 기준값
        _todaySteps = event.steps - baseSteps;
        if (_todaySteps < 0) _todaySteps = 0;

        await prefs.setInt('today_steps', _todaySteps);
        notifyListeners();
      },
      onError: (error) {
        _error = '만보계를 사용할 수 없습니다.';
        notifyListeners();
      },
    );
  }

  // 로컬에 저장된 오늘 걸음 수 로드
  Future<void> _loadTodaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('step_date') ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (savedDate != today) {
      // 날짜가 바뀜 → 초기화
      await prefs.setString('step_date', today);
      await prefs.setInt('today_steps', 0);
      await prefs.setInt('already_rewarded_steps', 0);
      _todaySteps = 0;
      _alreadyRewardedSteps = 0;
    } else {
      _todaySteps = prefs.getInt('today_steps') ?? 0;
      _alreadyRewardedSteps = prefs.getInt('already_rewarded_steps') ?? 0;
    }
    notifyListeners();
  }

  // 못 보낸 날짜 걸음 수 서버 전송
  Future<void> _sendPendingSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSentDate = prefs.getString('last_sent_date') ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (lastSentDate.isNotEmpty && lastSentDate != today) {
      // 어제(또는 마지막 날) 걸음 수 전송
      final pendingSteps = prefs.getInt('today_steps') ?? 0;
      if (pendingSteps > 0) {
        try {
          await _remote.saveStepLog(pendingSteps, lastSentDate);
          await prefs.setString('last_sent_date', today);
        } catch (_) {
          // 전송 실패해도 앱 실행은 계속
        }
      }
    } else if (lastSentDate.isEmpty) {
      await prefs.setString('last_sent_date', today);
    }
  }

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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('already_rewarded_steps', _alreadyRewardedSteps);
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
}