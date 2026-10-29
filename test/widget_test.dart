import 'package:flutter_test/flutter_test.dart';

import 'package:holyhabit/data/models/adventure_model.dart';

// 서버 응답(JSON)을 모델로 바꾸는 부분 확인
void main() {
  test('가격 정보 응답을 읽음', () {
    final prices = ShopPricesModel.fromJson({
      'gachaCost': 1400,
      'slotCosts': [0, 0, 0, 0, 500, 1000, 1500, 2500, 3500, 5000],
    });
    expect(prices.gachaCost, 1400);
    expect(prices.slotCosts[4], 500);
  });

  test('캐릭터 더블어택 확률 — 새 서버는 값, 예전 서버는 null', () {
    final base = {
      'statId': 1, 'characterId': 16, 'characterName': '홀리',
      'imageKey': 'char_holy', 'isActive': true, 'level': 1, 'exp': 0,
      'requiredExp': 100, 'atk': 10, 'def': 5, 'hp': 100, 'maxHp': 100,
    };
    expect(
      CharacterStatModel.fromJson({...base, 'doubleAttackChance': 0.15})
          .doubleAttackChance,
      0.15,
    );
    expect(CharacterStatModel.fromJson(base).doubleAttackChance, isNull);
  });
}
