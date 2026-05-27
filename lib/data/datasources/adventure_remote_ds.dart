import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/adventure_model.dart';

class AdventureRemoteDataSource {
  final Dio _dio = ApiClient.dio;

  Future<List<StageModel>> getStages() async {
    final res = await _dio.get('/adventures/stages');
    return (res.data as List).map((e) => StageModel.fromJson(e)).toList();
  }

  Future<CharacterStatModel> getCharacterStat() async {
    final res = await _dio.get('/adventures/character');
    return CharacterStatModel.fromJson(res.data);
  }

  Future<BattleStartResult> startBattle(int stageId) async {
    final res = await _dio.post('/adventures/start',
        queryParameters: {'stageId': stageId});
    return BattleStartResult.fromJson(res.data);
  }

  Future<BattleConfirmResult> confirmRewards(int battleId) async {
    final res = await _dio.post('/adventures/$battleId/confirm');
    return BattleConfirmResult.fromJson(res.data);
  }
}
