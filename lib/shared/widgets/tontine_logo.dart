import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class TontineLogo extends StatelessWidget {
  const TontineLogo({
    super.key,
    this.size = 88,
    this.activeIndex,
    this.backgroundColor = AppColors.ink,
    this.pointColor = AppColors.surface,
    this.highlightColor = AppColors.accent,
  });

  final double size;
  final int? activeIndex;
  final Color backgroundColor;
  final Color pointColor;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final center = size / 2;
    final radius = size * 0.32;
    final innerRadius = size * 0.06;

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(size * 0.18),
        ),
        child: Stack(
          children: List.generate(12, (index) {
            final angle = (index / 12) * (math.pi * 2) - math.pi / 2;
            final dx = center + math.cos(angle) * radius;
            final dy = center + math.sin(angle) * radius;
            final isActive = activeIndex == null ? index == 0 : index == activeIndex;

            return Positioned(
              left: dx - innerRadius,
              top: dy - innerRadius,
              child: Container(
                width: innerRadius * 2,
                height: innerRadius * 2,
                decoration: BoxDecoration(
                  color: isActive ? highlightColor : pointColor,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
