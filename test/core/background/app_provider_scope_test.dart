import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/core/background/app_provider_scope.dart';

void main() {
  for (final independent in [false, true]) {
    testWidgets(
        'async state progresses without UI frames: independent=$independent',
        (tester) async {
      final auth = StateProvider((ref) => false);
      var connections = 0;
      final stream = Provider((ref) {
        if (!ref.watch(auth)) return 'signed-out';
        connections++;
        return 'connected';
      });
      late StateController<bool> controller;
      final observed = <String>[];
      final child = Consumer(builder: (context, ref, _) {
        controller = ref.read(auth.notifier);
        ref.listen(stream, (_, next) => observed.add(next));
        return const SizedBox();
      });
      await tester.pumpWidget(independent
          ? AppProviderScope(child: child)
          : ProviderScope(child: child));
      // Emulate auth restoration while a boot-started engine has no surface.
      // runAsync advances timers/microtasks, but deliberately paints no frame.
      await tester.runAsync(() async {
        controller.state = true;
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      expect(observed, independent ? ['connected'] : isEmpty);
      expect(connections, independent ? 1 : 0);
      await tester.pump();
      expect(observed, ['connected']);
      expect(
          connections, 1); // Attaching/rendering the UI must not log in twice.
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('disposing a scope closes its application state once',
      (tester) async {
    var disposed = 0;
    final resource = Provider((ref) {
      ref.onDispose(() => disposed++);
      return Object();
    });
    await tester
        .pumpWidget(AppProviderScope(child: Consumer(builder: (_, ref, __) {
      ref.watch(resource);
      return const SizedBox();
    })));
    await tester.pumpWidget(const SizedBox());
    expect(disposed, 1);
  });
}
