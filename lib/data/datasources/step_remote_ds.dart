import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/step_reward_model.dart';

class StepRemoteDataSource {
  final Dio _dio = ApiClient.dio;

  // 걸음 수 보상 받기
  Future<StepRewardModel> claimReward(int totalSteps) async {
    final res = await _dio.post('/steps/reward', data: {
      'totalSteps': totalSteps,
    });
    return StepRewardModel.fromJson(res.data);
  }

  // 걸음 수 저장 (어제 날짜 걸음 수 전송)
  Future<void> saveStepLog(int stepCount, String date) async {
    await _dio.post('/steps/save', data: {
      'stepCount': stepCount,
      'date': date,
    });
  }
}