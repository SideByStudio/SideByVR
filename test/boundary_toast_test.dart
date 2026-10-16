import 'package:flutter_test/flutter_test.dart';
import 'package:sidebyvr/widgets/boundary_toast.dart';

void main() {
  group('swipeActionFor', () {
    test('左摇杆向左 + 非首页 → 上一张', () {
      expect(
        swipeActionFor(currentIndex: 5, total: 48, stickX: -0.5),
        SwipeAction.navigatePrevious,
      );
    });

    test('左摇杆向左 + 首页 → 第一页边界提示', () {
      expect(
        swipeActionFor(currentIndex: 0, total: 48, stickX: -0.5),
        SwipeAction.showFirstBoundary,
      );
    });

    test('左摇杆向右 + 非末页 → 下一张', () {
      expect(
        swipeActionFor(currentIndex: 5, total: 48, stickX: 0.5),
        SwipeAction.navigateNext,
      );
    });

    test('左摇杆向右 + 末页 → 最后页边界提示', () {
      expect(
        swipeActionFor(currentIndex: 47, total: 48, stickX: 0.5),
        SwipeAction.showLastBoundary,
      );
    });

    test('死区内 → none', () {
      expect(
        swipeActionFor(currentIndex: 0, total: 48, stickX: 0.1),
        SwipeAction.none,
      );
    });

    test('单张图：左右都是边界', () {
      expect(
        swipeActionFor(currentIndex: 0, total: 1, stickX: -0.5),
        SwipeAction.showFirstBoundary,
      );
      expect(
        swipeActionFor(currentIndex: 0, total: 1, stickX: 0.5),
        SwipeAction.showLastBoundary,
      );
    });
  });
}
