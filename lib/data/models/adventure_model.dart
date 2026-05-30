// 스테이지 모델
class StageModel {
  final int id;
  final String name;
  final String description;
  final int minLevel;
  final int maxLevel;
  final int shoeCoinCost;
  final String? imageKey;

  StageModel({
    required this.id, required this.name, required this.description,
    required this.minLevel, required this.maxLevel,
    required this.shoeCoinCost, this.imageKey,
  });

  factory StageModel.fromJson(Map<String, dynamic> json) => StageModel(
    id: json['id'], name: json['name'], description: json['description'] ?? '',
    minLevel: json['minLevel'], maxLevel: json['maxLevel'],
    shoeCoinCost: json['shoeCoinCost'], imageKey: json['imageKey'],
  );
}

// 캐릭터 스탯 (유저별 인스턴스)
class CharacterStatModel {
  final int statId;          // character_stats.id (선택 시 사용)
  final int characterId;
  final String characterName;
  final String? imageKey;
  final bool isActive;
  final int level;
  final int exp;
  final int requiredExp;
  final int atk;
  final int def;
  final int hp;
  final int maxHp;

  CharacterStatModel({
    required this.statId, required this.characterId,
    required this.characterName, this.imageKey,
    required this.isActive, required this.level,
    required this.exp, required this.requiredExp,
    required this.atk, required this.def,
    required this.hp, required this.maxHp,
  });

  double get expProgress => (exp / requiredExp).clamp(0.0, 1.0);

  factory CharacterStatModel.fromJson(Map<String, dynamic> json) =>
      CharacterStatModel(
        statId: json['statId'],
        characterId: json['characterId'],
        characterName: json['characterName'],
        imageKey: json['imageKey'],
        isActive: json['isActive'] ?? false,
        level: json['level'],
        exp: json['exp'],
        requiredExp: json['requiredExp'],
        atk: json['atk'],
        def: json['def'],
        hp: json['hp'],
        maxHp: json['maxHp'],
      );
}

// 배틀 턴 로그
class TurnLog {
  final int turn;
  final String actor;
  final int damage;
  final bool isDoubleAttack;
  final int playerHpAfter;
  final int monsterHpAfter;

  TurnLog({
    required this.turn, required this.actor, required this.damage,
    required this.isDoubleAttack, required this.playerHpAfter,
    required this.monsterHpAfter,
  });

  bool get isPlayer => actor == 'PLAYER';

  factory TurnLog.fromJson(Map<String, dynamic> json) => TurnLog(
    turn: json['turn'], actor: json['actor'], damage: json['damage'],
    isDoubleAttack: json['isDoubleAttack'] ?? false,
    playerHpAfter: json['playerHpAfter'],
    monsterHpAfter: json['monsterHpAfter'],
  );
}

// 배틀 시작 응답
class BattleStartResult {
  final int battleId;
  final String result;
  final String monsterName;
  final int monsterLevel;
  final int monsterHp;
  final int monsterAtk;
  final int monsterDef;
  final String? monsterImageKey;
  final int playerMaxHp;
  final int playerAtk;
  final int playerDef;
  final List<TurnLog> logs;

  BattleStartResult({
    required this.battleId, required this.result,
    required this.monsterName, required this.monsterLevel,
    required this.monsterHp, required this.monsterAtk,
    required this.monsterDef, this.monsterImageKey,
    required this.playerMaxHp, required this.playerAtk,
    required this.playerDef, required this.logs,
  });

  bool get isWin => result == 'WIN';

  factory BattleStartResult.fromJson(Map<String, dynamic> json) =>
      BattleStartResult(
        battleId: json['battleId'], result: json['result'],
        monsterName: json['monsterName'], monsterLevel: json['monsterLevel'],
        monsterHp: json['monsterHp'], monsterAtk: json['monsterAtk'],
        monsterDef: json['monsterDef'], monsterImageKey: json['monsterImageKey'],
        playerMaxHp: json['playerMaxHp'], playerAtk: json['playerAtk'],
        playerDef: json['playerDef'],
        logs: (json['logs'] as List).map((e) => TurnLog.fromJson(e)).toList(),
      );
}

// 보상 확인 응답
class BattleConfirmResult {
  final String result;
  final int expGained;
  final int goldGained;
  final int levelsGained;
  final int newLevel;
  final int newExp;
  final int requiredExp;
  final int newAtk;
  final int newDef;
  final int newMaxHp;

  BattleConfirmResult({
    required this.result, required this.expGained, required this.goldGained,
    required this.levelsGained, required this.newLevel, required this.newExp,
    required this.requiredExp, required this.newAtk, required this.newDef,
    required this.newMaxHp,
  });

  bool get isWin => result == 'WIN';

  factory BattleConfirmResult.fromJson(Map<String, dynamic> json) =>
      BattleConfirmResult(
        result: json['result'], expGained: json['expGained'] ?? 0,
        goldGained: json['goldGained'] ?? 0, levelsGained: json['levelsGained'] ?? 0,
        newLevel: json['newLevel'], newExp: json['newExp'],
        requiredExp: json['requiredExp'], newAtk: json['newAtk'],
        newDef: json['newDef'], newMaxHp: json['newMaxHp'],
      );
}
