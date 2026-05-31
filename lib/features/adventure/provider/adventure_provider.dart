import 'package:flutter/material.dart';
import '../../../data/models/adventure_model.dart';
import '../../../data/repositories/adventure_repository.dart';

class AdventureProvider extends ChangeNotifier {
  final _repository = AdventureRepository();

  List<StageModel> stages = [];
  List<CharacterStatModel> myCharacters = [];
  CharacterStatModel? activeCharacter;
  BattleStartResult? currentBattle;
  BattleStartResult? pendingBattle;  // 미수령 배틀
  BattleConfirmResult? confirmResult;

  bool isLoading = false;
  bool isCheckingPending = false;
  String? error;

  Future<void> loadStages() async {
    isLoading = true;
    notifyListeners();
    try {
      stages = await _repository.getStages();
      myCharacters = await _repository.getMyCharacters();
      activeCharacter = myCharacters.where((c) => c.isActive).firstOrNull
          ?? (myCharacters.isNotEmpty ? myCharacters.first : null);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 미수령 배틀 체크 — 맵 화면 진입 시 호출
  Future<BattleStartResult?> checkPendingBattle() async {
    isCheckingPending = true;
    notifyListeners();
    try {
      pendingBattle = await _repository.getPendingBattle();
      return pendingBattle;
    } catch (_) {
      return null;
    } finally {
      isCheckingPending = false;
      notifyListeners();
    }
  }

  // 배틀 포기
  Future<void> abandonBattle(int battleId) async {
    try {
      await _repository.abandonBattle(battleId);
      pendingBattle = null;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> selectCharacter(int statId) async {
    try {
      final updated = await _repository.selectCharacter(statId);
      myCharacters = myCharacters.map((c) => CharacterStatModel(
        statId: c.statId, characterId: c.characterId,
        characterName: c.characterName, imageKey: c.imageKey,
        isActive: c.statId == statId,
        level: c.level, exp: c.exp, requiredExp: c.requiredExp,
        atk: c.atk, def: c.def, hp: c.hp, maxHp: c.maxHp,
      )).toList();
      activeCharacter = updated;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<BattleStartResult?> startBattle(int stageId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      currentBattle = await _repository.startBattle(stageId);
      return currentBattle;
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<BattleConfirmResult?> confirmRewards() async {
    if (currentBattle == null) return null;
    isLoading = true;
    notifyListeners();
    try {
      confirmResult =
      await _repository.confirmRewards(currentBattle!.battleId);
      await loadStages();
      return confirmResult;
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearBattle() {
    currentBattle = null;
    confirmResult = null;
    pendingBattle = null;
    notifyListeners();
  }
}
