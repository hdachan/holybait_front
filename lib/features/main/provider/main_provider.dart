import 'package:flutter/material.dart';

class MainProvider extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  // ─── 여기에 화면 간 공유 상태 추가 ───
  // 예: 홈에서 획득한 아이템이 캐릭터/모험에 바로 반영되어야 할 때
  //
  // int _gold = 0;
  // int get gold => _gold;
  // void addGold(int amount) {
  //   _gold += amount;
  //   notifyListeners();
  // }
}
