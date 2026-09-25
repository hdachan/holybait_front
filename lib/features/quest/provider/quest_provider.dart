import 'package:flutter/material.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/repositories/QuestRepository.dart';

class QuestProvider extends ChangeNotifier {
  final _repository = QuestRepository();

  // type별로 따로 보관 (tutorial / daily / weekly)
  static const List<String> _allTypes = [
    'tutorial',
    'daily',
    'weekly',
    'achievement',
  ];

  final Map<String, List<QuestModel>> _questsByType = {
    for (final t in _allTypes) t: <QuestModel>[],
  };
  final Map<String, bool> _loadingByType = {
    for (final t in _allTypes) t: false,
  };

  // 현재 화면에 보여주는 탭 (늦게 도착한 다른 탭 응답이 덮어쓰지 않도록)
  String _currentType = 'tutorial';
  String get currentType => _currentType;

  String? _error;
  String? get error => _error;

  // ── 현재 선택된 타입 기준 (바텀시트에서 사용) ──
  List<QuestModel> quests = [];
  bool isLoading = false;

  int get completedCount => quests.where((q) => q.isCompleted).length;
  int get claimedCount => quests.where((q) => q.isClaimed).length;
  int get totalCount => quests.length;
  bool get hasClaimableInCurrent => quests.any((q) => q.isCompleted);
  bool get allClaimed =>
      quests.isNotEmpty && quests.every((q) => q.isClaimed);

  // ── 전체 타입 통틀어 완료된 퀘스트가 하나라도 있는지 (배지용) ──
  bool get hasClaimable => _questsByType.values
      .expand((list) => list)
      .any((q) => q.isCompleted);

  // 특정 타입만 완료 여부 확인하고 싶을 때
  bool hasClaimableFor(String type) =>
      (_questsByType[type] ?? []).any((q) => q.isCompleted);

  Future<void> loadQuests({String type = 'tutorial'}) async {
    _currentType = type;
    isLoading = true;
    _loadingByType[type] = true;
    // 탭 전환 즉시 이전 탭 목록을 비움 (다른 탭 내용이 남아 보이지 않게)
    quests = _questsByType[type] ?? [];
    _error = null;
    notifyListeners();
    try {
      final result = await _repository.getMyQuests(type: type);
      _questsByType[type] = result;
      if (_currentType == type) {
        quests = result;
        _error = null;
      }
    } catch (e) {
      _questsByType[type] = [];
      if (_currentType == type) {
        quests = [];
        _error = '퀘스트를 불러오지 못했습니다.';
      }
    } finally {
      _loadingByType[type] = false;
      if (_currentType == type) isLoading = false;
      notifyListeners();
    }
  }

  // 배지 갱신용 — 3개 타입 전부 조용히 불러오기 (로딩 표시 없이)
  Future<void> refreshAllBadges() async {
    for (final type in _allTypes) {
      try {
        final result = await _repository.getMyQuests(type: type);
        _questsByType[type] = result;
      } catch (_) {
        // 조용히 무시 (배지 갱신용이라 에러 표시 안 함)
      }
    }
    notifyListeners();
  }

  Future<QuestClaimResult?> claimReward(int questId, {String type = 'tutorial'}) async {
    try {
      final result = await _repository.claimReward(questId);
      await loadQuests(type: type); // 현재 목록 갱신
      return result;
    } catch (e) {
      _error = '보상 수령에 실패했습니다.';
      notifyListeners();
      return null;
    }
  }
}