import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/quest_model.dart';

class QuestRemoteDataSource {
  final Dio _dio = ApiClient.dio;

  Future<List<QuestModel>> getMyQuests({String type = 'tutorial'}) async {
    final res = await _dio.get('/quests', queryParameters: {'type': type});
    return (res.data as List).map((e) => QuestModel.fromJson(e)).toList();
  }

  Future<QuestClaimResult> claimReward(int questId) async {
    final res = await _dio.post('/quests/$questId/claim');
    return QuestClaimResult.fromJson(res.data);
  }
}