import 'package:flutter/material.dart';
import '../../../data/models/adventure_model.dart';
import '../../../data/repositories/adventure_repository.dart';

class AdventureProvider extends ChangeNotifier {
  final _repository = AdventureRepository();

  List<StageModel> stages = [];
  List<CharacterStatModel> myCharacters = [];  // 내 모든 캐릭터
  CharacterStatModel? activeCharacter;          // 현재 활성 캐릭터
  BattleStartResult? currentBattle;
  BattleConfirmResult? confirmResult;

  bool isLoading = false;
  String? error;

  // 스테이지 + 캐릭터 모두 로드
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

  // 캐릭터 변경
  Future<void> selectCharacter(int statId) async {
    try {
      final updated = await _repository.selectCharacter(statId);
      // 로컬 상태 업데이트
      myCharacters = myCharacters.map((c) {
        if (c.statId == statId) {
          return CharacterStatModel(
            statId: c.statId, characterId: c.characterId,
            characterName: c.characterName, imageKey: c.imageKey,
            isActive: true, level: c.level, exp: c.exp,
            requiredExp: c.requiredExp, atk: c.atk, def: c.def,
            hp: c.hp, maxHp: c.maxHp,
          );
        } else {
          return CharacterStatModel(
            statId: c.statId, characterId: c.characterId,
            characterName: c.characterName, imageKey: c.imageKey,
            isActive: false, level: c.level, exp: c.exp,
            requiredExp: c.requiredExp, atk: c.atk, def: c.def,
            hp: c.hp, maxHp: c.maxHp,
          );
        }
      }).toList();
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
      confirmResult = await _repository.confirmRewards(currentBattle!.battleId);
      // 캐릭터 스탯 갱신
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
    notifyListeners();
  }
}
