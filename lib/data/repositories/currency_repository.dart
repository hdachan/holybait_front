import '../datasources/currency_remote_ds.dart';
import '../models/currency_model.dart';

class CurrencyRepository {
  final _remote = CurrencyRemoteDataSource();

  Future<CurrencyModel> getCurrency() => _remote.getCurrency();
}
