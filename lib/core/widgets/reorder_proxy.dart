import 'package:flutter/material.dart';

/// 순서 바꾸기(ReorderableListView)에서 끌고 있는 카드의 모양.
/// 기본값은 카드 뒤에 흰 바탕(Material 기본색)을 깔아서, 카드의 둥근 모서리·아래 여백 부분이 하얗게 보임
/// → 바탕을 투명하게 하고 살짝 커지는 효과만 줌
Widget reorderProxyDecorator(Widget child, int index, Animation<double> animation) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final t = Curves.easeOut.transform(animation.value);
      return Transform.scale(
        scale: 1 + 0.03 * t,
        child: Material(
          type: MaterialType.transparency,
          child: child,
        ),
      );
    },
    child: child,
  );
}
