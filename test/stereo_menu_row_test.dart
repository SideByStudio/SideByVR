import 'package:sidebyvr/widgets/stereo_menu_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('双眼行共享唯一滚动视口且左右触摸都只触发一次', (tester) async {
    final controller = ScrollController();
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            controller: controller,
            itemCount: 12,
            itemBuilder: (context, index) => SizedBox(
              height: 100,
              child: StereoMenuRow(
                builder: (_, eye) => InkWell(
                  key: ValueKey('row-$index-${eye.name}'),
                  onTap: () => taps += 1,
                  child: Text('Item $index'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Scrollable), findsOneWidget);
    expect(find.text('Item 0'), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('row-0-left')));
    await tester.tap(find.byKey(const ValueKey('row-0-right')));
    expect(taps, 2);

    await tester.dragFrom(const Offset(100, 500), const Offset(0, -300));
    await tester.pumpAndSettle();
    final afterLeftDrag = controller.offset;
    expect(afterLeftDrag, greaterThan(0));

    await tester.dragFrom(const Offset(700, 500), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(afterLeftDrag));

    controller.dispose();
  });

  testWidgets('右眼副本默认不重复无障碍语义', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StereoMenuRow(builder: _semanticLabel)),
      ),
    );

    expect(find.text('Menu entry'), findsNWidgets(2));
    expect(find.bySemanticsLabel('Menu entry'), findsOneWidget);
    semantics.dispose();
  });
}

Widget _semanticLabel(BuildContext context, StereoMenuEye eye) =>
    const Text('Menu entry');
