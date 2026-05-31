import '../datasources/adventure_remote_ds.dart';
import '../models/adventure_model.dart';

class AdventureRepository {
  final _remote = AdventureRemoteDataSource();

  Future<List<StageModel>> getStages() => _remote.getStages();
  Future<List<CharacterStatModel>> getMyCharacters() =>
      _remote.getMyCharacters();
  Future<CharacterStatModel> getActiveCharacter() =>
      _remote.getActiveCharacter();
  Future<CharacterStatModel> selectCharacter(int statId) =>
      _remote.selectCharacter(statId);
  Future<BattleStartResult?> getPendingBattle() =>
      _remote.getPendingBattle();
  Future<void> abandonBattle(int battleId) =>
      _remote.abandonBattle(battleId);
  Future<BattleStartResult> startBattle(int stageId) =>
      _remote.startBattle(stageId);
  Future<BattleConfirmResult> confirmRewards(int battleId) =>
      _remote.confirmRewards(battleId);
}
