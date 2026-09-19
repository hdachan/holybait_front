import 'package:flutter/material.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/repositories/QuestRepository.dart';

class QuestProvider extends ChangeNotifier {
  final _repository = QuestRepository();

  // type별로 따로 보관 (tutorial / daily / weekly)
  final Map<String, List<QuestModel>> _questsByType = {
    'tutorial': [],
    'daily': [],
    'weekly': [],
  };
  final Map<String, bool> _loadingByType = {
    'tutorial': false,
    'daily': false,
    'weekly': false,
  };

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
    isLoading = true;
    _loadingByType[type] = true;
    notifyListeners();
    try {
      final result = await _repository.getMyQuests(type: type);
      _questsByType[type] = result;
      quests = result;
      _error = null;
    } catch (e) {
      _error = '퀘스트를 불러오지 못했습니다.';
    } finally {
      isLoading = false;
      _loadingByType[type] = false;
      notifyListeners();
    }
  }

  // 배지 갱신용 — 3개 타입 전부 조용히 불러오기 (로딩 표시 없이)
  Future<void> refreshAllBadges() async {
    for (final type in ['tutorial', 'daily', 'weekly']) {
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