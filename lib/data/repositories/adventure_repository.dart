import '../datasources/adventure_remote_ds.dart';
import '../models/adventure_model.dart';

class AdventureRepository {
  final _remote = AdventureRemoteDataSource();

  Future<List<StageModel>> getStages() => _remote.getStages();
  Future<CharacterStatModel> getCharacterStat() => _remote.getCharacterStat();
  Future<BattleStartResult> startBattle(int stageId) => _remote.startBattle(stageId);
  Future<BattleConfirmResult> confirmRewards(int battleId) =>
      _remote.confirmRewards(battleId);
}
