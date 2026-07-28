import 'dart:ui';
import 'package:flutter/material.dart';

/// 캐릭터 화면 전용 배경
/// AppBackground와 동일한 색감이지만 캐릭터 영역(중앙 상단)을 밝게
class CharacterBackground extends StatelessWidget {
  final Widget child;

  const CharacterBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 기본 그라데이션 배경
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

        // 캐릭터 영역 밝게 (중앙 상단 방사형 빛)
        Positioned(
          top: -40,
          left: 0,
          right: 0,
          child: Center(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6B3FA0).withOpacity(0.55),
                ),
              ),
            ),
          ),
        ),

        // 추가 빛 레이어 (더 밝은 포인트)
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Center(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF9B6FD0).withOpacity(0.35),
                ),
              ),
            ),
          ),
        ),

        // 블롭 1 (상단 좌측 — 주황)
        Positioned(
          top: -70,
          left: -60,
          child: _Blob(
            size: 220,
            color: const Color(0xFFF4A259),
            opacity: 0.2,
            blur: 55,
          ),
        ),

        // 블롭 2 (하단 우측 — 파랑)
        Positioned(
          bottom: 80,
          right: -60,
          child: _Blob(
            size: 200,
            color: const Color(0xFF00B7FE),
            opacity: 0.2,
            blur: 55,
          ),
        ),

        // 블롭 3 (하단 좌측 — 파랑)
        Positioned(
          bottom: 40,
          left: -30,
          child: _Blob(
            size: 160,
            color: const Color(0xFF00B7FE),
            opacity: 0.12,
            blur: 50,
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