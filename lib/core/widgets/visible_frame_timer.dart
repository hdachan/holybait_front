import 'dart:async';

import 'package:flutter/widgets.dart';

// 그림 여러 장을 일정 간격으로 바꾸는 애니메이션용 타이머
// - 화면에 안 보이면 멈춤: 숨은 탭(MainScreen의 TickerMode), 위에 다른 화면이 덮였을 때
// - 앱이 백그라운드로 가거나 화면이 꺼지면 멈춤
// - 다시 보이면 멈췄던 장면부터 이어서 움직임
mixin VisibleFrameTimer<T extends StatefulWidget> on State<T> {
  Timer? _frameTimer;
  bool _tickerEnabled = true;
  late final AppLifecycleListener _lifecycle =
      AppLifecycleListener(onStateChange: (_) => updateFrameTimer());

  // 그림을 바꾸는 간격
  Duration get frameDuration;

  // 움직여야 하는 상태인지 (예: 가운데 행성만 움직임)
  bool get wantsFrames => true;

  // 다음 그림으로 넘기기 (setState 안에서 호출됨)
  void onFrame();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerEnabled = TickerMode.of(context);
    _lifecycle; // 앱 상태 감시 시작
    updateFrameTimer();
  }

  // 조건이 바뀌었을 때 호출 — 켜야 하면 켜고, 아니면 멈춤
  void updateFrameTimer() {
    final appState = WidgetsBinding.instance.lifecycleState;
    final appVisible = appState == null || appState == AppLifecycleState.resumed;
    final shouldRun = wantsFrames && _tickerEnabled && appVisible;

    if (shouldRun && _frameTimer == null) {
      _frameTimer = Timer.periodic(frameDuration, (_) {
        if (mounted) setState(onFrame);
      });
    } else if (!shouldRun) {
      _frameTimer?.cancel();
      _frameTimer = null;
    }
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }
}
