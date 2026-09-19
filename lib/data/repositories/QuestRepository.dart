import '../datasources/quest_remote_ds.dart';
import '../models/quest_model.dart';

class QuestRepository {
  final _remote = QuestRemoteDataSource();

  Future<List<QuestModel>> getMyQuests({String type = 'tutorial'}) =>
      _remote.getMyQuests(type: type);

  Future<QuestClaimResult> claimReward(int questId) =>
      _remote.claimReward(questId);
}