import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/planet_model.dart';

class PlanetRemoteDataSource {
  final Dio _dio = ApiClient.dio;

  // 행성 목록
  Future<List<PlanetModel>> getPlanets() async {
    final res = await _dio.get('/planets');
    return (res.data as List)
        .map((e) => PlanetModel.fromJson(e))
        .toList();
  }
}