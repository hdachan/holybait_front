import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/routine_model.dart';
import '../models/exercise_model.dart';
import '../models/workout_model.dart';
import '../../features/routine/screens/workout_history_screen.dart';
import '../../features/routine/screens/workout_history_detail_screen.dart';
class RoutineRemoteDataSource {
  final Dio _dio = ApiClient.dio;

  Future<List<RoutineModel>> getRoutines() async {
    final res = await _dio.get('/routines');
    return (res.data as List).map((e) => RoutineModel.fromJson(e)).toList();
  }

  Future<RoutineModel> getRoutine(int routineId) async {
    final res = await _dio.get('/routines/$routineId');
    return RoutineModel.fromJson(res.data);
  }

  Future<RoutineModel> createRoutine(String name, List<int> exerciseIds) async {
    final res = await _dio.post('/routines', data: {
      'name': name,
      'exerciseIds': exerciseIds,
    });
    return RoutineModel.fromJson(res.data);
  }

  Future<RoutineModel> updateRoutine(
      int routineId, String name, List<int> exerciseIds) async {
    final res = await _dio.put('/routines/$routineId', data: {
      'name': name,
      'exerciseIds': exerciseIds,
    });
    return RoutineModel.fromJson(res.data);
  }

  Future<RoutineModel> saveRoutineDetail(
      int routineId, List<Map<String, dynamic>> exercises) async {
    final res = await _dio.patch('/routines/$routineId/detail', data: {
      'exercises': exercises,
    });
    return RoutineModel.fromJson(res.data);
  }

  Future<void> deleteRoutine(int routineId) async {
    await _dio.delete('/routines/$routineId');
  }

  Future<List<ExerciseModel>> getExercises(
      {String? target, String? keyword}) async {
    final res = await _dio.get('/exercises', queryParameters: {
      if (target != null) 'target': target,
      if (keyword != null) 'keyword': keyword,
    });
    return (res.data as List).map((e) => ExerciseModel.fromJson(e)).toList();
  }

  Future<ExerciseModel> createCustomExercise(
      String name, String target) async {
    final res = await _dio.post('/exercises/custom', data: {
      'name': name,
      'target': target,
    });
    return ExerciseModel.fromJson(res.data);
  }

  Future<WorkoutSaveResult> saveWorkout(
      int routineExerciseId,
      List<Map<String, dynamic>> sets,
      ) async {
    final res = await _dio.post('/workouts', data: {
      'routineExerciseId': routineExerciseId,
      'sets': sets,
    });
    return WorkoutSaveResult.fromJson(res.data);
  }

  Future<RecentSetsResponse?> getRecentSets(int routineExerciseId) async {
    final res = await _dio.get('/workouts/recent/$routineExerciseId');
    if (res.data == null) return null;
    return RecentSetsResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // 운동 통계
  Future<WorkoutSummaryModel> getWorkoutSummary() async {
    final res = await _dio.get('/workouts/summary');
    return WorkoutSummaryModel.fromJson(res.data);
  }

  // 내가 운동한 종목 목록
  Future<List<WorkoutHistoryModel>> getExerciseHistory() async {
    final res = await _dio.get('/workouts/exercises');
    return (res.data as List)
        .map((e) => WorkoutHistoryModel.fromJson(e))
        .toList();
  }

  // 특정 종목 날짜별 기록
  Future<List<WorkoutHistoryDetailModel>> getExerciseDetail(
      int exerciseId) async {
    final res =
    await _dio.get('/workouts/exercises/$exerciseId/history');
    return (res.data as List)
        .map((e) => WorkoutHistoryDetailModel.fromJson(e))
        .toList();
  }
}