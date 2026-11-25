import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/item_model.dart';

// 가방 API
class ItemRemoteDataSource {
  final Dio _dio = ApiClient.dio;

  Future<List<ItemModel>> getMyItems({String type = 'EFFECT'}) async {
    final res = await _dio.get('/items', queryParameters: {'type': type});
    return (res.data as List).map((e) => ItemModel.fromJson(e)).toList();
  }

  /// 착용 → 바뀐 이펙트 목록
  Future<List<ItemModel>> equip(int itemId) async {
    final res = await _dio.post('/items/$itemId/equip');
    return (res.data as List).map((e) => ItemModel.fromJson(e)).toList();
  }
}
