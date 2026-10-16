import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidebyvr/widgets/debug_overlay.dart';

void main() {
  testWidgets('ViewerInfoPanel 三行：查看状态 / i·n / 操作提示，无文件名', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ViewerInfoPanel(
            zoom: 1.0,
            ipdOffset: 0.0,
            index: 3,
            total: 48,
          ),
        ),
      ),
    );

    expect(find.textContaining('File:'), findsNothing);
    expect(find.textContaining('Zoom: 1.0x'), findsOneWidget);
    expect(find.textContaining('IPD: 0px'), findsOneWidget);
    expect(find.text('3 / 48'), findsOneWidget);
    expect(find.textContaining('LStick'), findsOneWidget);
    // lastKey 已移除
    expect(find.textContaining('Key:'), findsNothing);
  });

  testWidgets('GIF 与视频显示各自的手柄提示', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            ViewerInfoPanel(
              zoom: 1,
              ipdOffset: 5,
              index: 1,
              total: 2,
              mode: ViewerInfoMode.gif,
            ),
            ViewerInfoPanel(
              zoom: 1,
              ipdOffset: 5,
              index: 2,
              total: 2,
              mode: ViewerInfoMode.video,
            ),
          ],
        ),
      ),
    );

    expect(find.textContaining('Y: Play/Pause'), findsNWidgets(2));
    expect(find.textContaining('DPad←/→: Seek ±5s'), findsOneWidget);
    expect(find.textContaining('Zoom: 1.0x'), findsNWidgets(2));
  });
}
