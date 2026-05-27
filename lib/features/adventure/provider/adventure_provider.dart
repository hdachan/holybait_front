import 'package:flutter/material.dart';
import '../../../data/models/adventure_model.dart';
import '../../../data/repositories/adventure_repository.dart';

class AdventureProvider extends ChangeNotifier {
  final _repository = AdventureRepository();

  List<StageModel> stages = [];
  CharacterStatModel? characterStat;
  BattleStartResult? currentBattle;
  BattleConfirmResult? confirmResult;

  bool isLoading = false;
  String? error;

  Future<void> loadStages() async {
    isLoading = true;
    notifyListeners();
    try {
      stages = await _repository.getStages();
      characterStat = await _repository.getCharacterStat();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
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
      // 캐릭터 스탯 업데이트
      characterStat = await _repository.getCharacterStat();
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
