import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/currency_model.dart';

class CurrencyRemoteDataSource {
  final Dio _dio = ApiClient.dio;

  Future<CurrencyModel> getCurrency() async {
    final res = await _dio.get('/currencies');
    return CurrencyModel.fromJson(res.data);
  }
}
