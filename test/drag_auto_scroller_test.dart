import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy_board/src/widgets/reorder_flex/drag_auto_scroller.dart';

void main() {
  testWidgets(
    'maxTickDelta caps how far a single tick can advance the scroll offset',
    (tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: ListView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            children: List.generate(
              50,
              (i) => SizedBox(width: 400, child: Text('page $i')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final autoScroller = BoardDragAutoScroller(
        scrollController: scrollController,
        velocityScalar: 3000.0, // deliberately huge — would overshoot without a clamp
        axis: Axis.horizontal,
        maxTickDelta: 40.0,
      );
      addTearDown(autoScroller.dispose);

      // Drag rect pinned right at the trailing edge, well within the
      // 80px `_edgeSize` band, to force maximum velocity.
      autoScroller.startAutoScrollIfNecessary(
        const Rect.fromLTWH(395, 0, 1, 1),
        containerContext: tester.element(find.byType(ListView)),
      );

      final offsetsBetweenTicks = <double>[];
      for (var i = 0; i < 5; i++) {
        final before = scrollController.offset;
        await tester.pump(const Duration(milliseconds: 16));
        offsetsBetweenTicks.add(scrollController.offset - before);
      }

      for (final delta in offsetsBetweenTicks) {
        expect(
          delta.abs(),
          lessThanOrEqualTo(40.0 + 0.01),
          reason: 'a single tick advanced further than maxTickDelta allows',
        );
      }
      // With the huge velocityScalar and no clamp this would have jumped
      // far more than 40px in the very first tick — confirm real forward
      // progress still happened, just bounded.
      expect(offsetsBetweenTicks.reduce((a, b) => a + b), greaterThan(0));
    },
  );
}
