import 'package:flutter/material.dart';

import '../../../data/models/currency_model.dart';
import '../../../data/repositories/currency_repository.dart';


class CurrencyProvider extends ChangeNotifier {
  final _repository = CurrencyRepository();

  CurrencyModel _currency = CurrencyModel(gold: 0, shoeCoin: 0);
  bool _isLoading = false;

  CurrencyModel get currency => _currency;
  int get gold => _currency.gold;
  int get shoeCoin => _currency.shoeCoin;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currency = await _repository.getCurrency();
    } catch (_) {
      // 실패해도 기존 값 유지
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
