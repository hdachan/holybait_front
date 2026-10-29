import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../features/adventure/provider/adventure_provider.dart';
import '../../features/currency/provider/currency_provider.dart';
import '../../features/main/provider/main_provider.dart';
import '../../features/planet/provider/planet_provider.dart';
import '../../features/quest/provider/quest_provider.dart';
import '../../features/routine/provider/routine_provider.dart';
import '../../features/step/step_provider.dart';
import '../push/push_service.dart';

// 로그아웃·탈퇴·세션 종료 시 이전 계정의 화면 정보를 비움
// (다음 계정이 로그인했을 때 이전 계정의 골드·캐릭터·탭 위치 등이 보이지 않게)
void resetUserData(BuildContext context) {
  context.read<MainProvider>().reset();
  context.read<RoutineProvider>().reset();
  context.read<CurrencyProvider>().reset();
  context.read<AdventureProvider>().reset();
  context.read<StepProvider>().reset();
  context.read<PlanetProvider>().reset();
  context.read<QuestProvider>().reset();
  PushService.clear();
}
