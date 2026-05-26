import 'package:flutter/material.dart';
import '../../../data/models/currency_model.dart';
import '../../../data/repositories/currency_repository.dart';


class CurrencyProvider extends ChangeNotifier {
  final _repository = CurrencyRepository();

  CurrencyModel _currency = CurrencyModel(
    gold: 0,
    shoeCoin: 0,
    todayShoeCoin: 0,
    dailyCap: 20,
  );
  bool _isLoading = false;

  CurrencyModel get currency => _currency;
  int get gold => _currency.gold;
  int get shoeCoin => _currency.shoeCoin;
  int get todayShoeCoin => _currency.todayShoeCoin;
  int get dailyCap => _currency.dailyCap;
  int get remainingToday => _currency.remainingToday;
  bool get isCapped => _currency.isCapped;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currency = await _repository.getCurrency();
    } catch (_) {}
    finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
