import 'dart:ui';
import 'package:flutter/material.dart';

/// 앱 전체에서 재사용하는 배경 위젯
/// Scaffold의 body를 감싸서 사용
///
/// 사용법:
/// body: AppBackground(
///   child: YourContent(),
/// )
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 그라데이션 배경
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.5, 1.0],
              colors: [
                Color(0xFF160d1f),
                Color(0xFF2a1840),
                Color(0xFF0e0a1a),
              ],
            ),
          ),
        ),

        // 블롭 1 (상단 좌측 — 주황)
        Positioned(
          top: -70,
          left: -60,
          child: _Blob(
            size: 260,
            color: const Color(0xFFF4A259),
            opacity: 0.3,
            blur: 60,
          ),
        ),

        // 블롭 2 (중단 우측 — 파랑)
        Positioned(
          top: 320,
          right: -70,
          child: _Blob(
            size: 220,
            color: const Color(0xFF00B7FE),
            opacity: 0.25,
            blur: 55,
          ),
        ),

        // 블롭 3 (하단 좌측 — 파랑)
        Positioned(
          bottom: 60,
          left: -40,
          child: _Blob(
            size: 200,
            color: const Color(0xFF00B7FE),
            opacity: 0.15,
            blur: 55,
          ),
        ),

        // 콘텐츠
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  final double blur;

  const _Blob({
    required this.size,
    required this.color,
    required this.opacity,
    required this.blur,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(opacity),
        ),
      ),
    );
  }
}