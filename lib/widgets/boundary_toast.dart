import 'package:flutter/material.dart';

/// 切图动作判定结果。
enum SwipeAction {
  navigatePrevious,
  navigateNext,
  showFirstBoundary,
  showLastBoundary,
  none,
}

/// 根据当前页索引、总数、左摇杆 X 轴值，决定切图动作。
/// 纯函数，便于单元测试。
SwipeAction swipeActionFor({
  required int currentIndex,
  required int total,
  required double stickX,
}) {
  if (stickX < -0.3) {
    return currentIndex > 0
        ? SwipeAction.navigatePrevious
        : SwipeAction.showFirstBoundary;
  }
  if (stickX > 0.3) {
    return currentIndex < total - 1
        ? SwipeAction.navigateNext
        : SwipeAction.showLastBoundary;
  }
  return SwipeAction.none;
}

/// 居中边界提示 Toast（半透明药丸）。左右半屏各渲染一份。
class BoundaryToast extends StatelessWidget {
  final String text;
  const BoundaryToast({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
