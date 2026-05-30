import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/adventure_model.dart';

class AdventureRemoteDataSource {
  final Dio _dio = ApiClient.dio;

  Future<List<StageModel>> getStages() async {
    final res = await _dio.get('/adventures/stages');
    return (res.data as List).map((e) => StageModel.fromJson(e)).toList();
  }

  // 내 모든 캐릭터
  Future<List<CharacterStatModel>> getMyCharacters() async {
    final res = await _dio.get('/adventures/characters');
    return (res.data as List)
        .map((e) => CharacterStatModel.fromJson(e))
        .toList();
  }

  // 현재 활성 캐릭터
  Future<CharacterStatModel> getActiveCharacter() async {
    final res = await _dio.get('/adventures/character');
    return CharacterStatModel.fromJson(res.data);
  }

  // 캐릭터 변경
  Future<CharacterStatModel> selectCharacter(int statId) async {
    final res = await _dio.post('/adventures/character/select',
        queryParameters: {'statId': statId});
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
