import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/adventure_model.dart';

class AdventureRemoteDataSource {
  final Dio _dio = ApiClient.dio;

  Future<List<StageModel>> getStages() async {
    final res = await _dio.get('/adventures/stages');
    return (res.data as List).map((e) => StageModel.fromJson(e)).toList();
  }

  Future<List<CharacterStatModel>> getMyCharacters() async {
    final res = await _dio.get('/adventures/characters');
    return (res.data as List)
        .map((e) => CharacterStatModel.fromJson(e))
        .toList();
  }

  Future<CharacterStatModel> getActiveCharacter() async {
    final res = await _dio.get('/adventures/character');
    return CharacterStatModel.fromJson(res.data);
  }

  Future<CharacterStatModel> selectCharacter(int statId) async {
    final res = await _dio.post('/adventures/character/select',
        queryParameters: {'statId': statId});
    return CharacterStatModel.fromJson(res.data);
  }

  // 미수령 배틀 조회 — 없으면 null 반환 (204 No Content)
  Future<BattleStartResult?> getPendingBattle() async {
    try {
      final res = await _dio.get('/adventures/pending');
      if (res.statusCode == 204 || res.data == null) return null;
      return BattleStartResult.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // 배틀 포기
  Future<void> abandonBattle(int battleId) async {
    await _dio.delete('/adventures/$battleId/abandon');
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
