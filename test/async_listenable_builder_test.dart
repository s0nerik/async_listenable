import 'package:async_listenable/async_listenable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AsyncListenableBuilder rebuilds on each AsyncListenable update',
      (tester) async {
    final asyncNotifier = AsyncNotifier<int>();
    final snapshots = <AsyncSnapshot<int>>[];
    await tester.pumpWidget(
      AsyncListenableBuilder(
        asyncListenable: asyncNotifier,
        builder: (context, snapshot) {
          snapshots.add(snapshot);
          return const SizedBox.shrink();
        },
      ),
    );
    expect(snapshots, hasLength(1));
    expect(snapshots.last.connectionState, ConnectionState.none);
    expect(snapshots.last.data, null);

    asyncNotifier.setFuture(Future.value(42));
    await tester.pump();
    expect(snapshots, hasLength(2));
    expect(snapshots.last.connectionState, ConnectionState.done);
    expect(snapshots.last.data, 42);
  });
  testWidgets(
      'AsyncListenableBuilder updates subscriptions upon replacing the asyncListenable',
      (tester) async {
    final asyncNotifier1 = AsyncNotifier<int>()..setFuture(Future.value(10));
    final asyncNotifier2 = AsyncNotifier<int>()..setFuture(Future.value(20));

    final snapshots = <AsyncSnapshot<int>>[];
    await tester.pumpWidget(
      AsyncListenableBuilder(
        asyncListenable: asyncNotifier1,
        builder: (context, snapshot) {
          snapshots.add(snapshot);
          return const SizedBox.shrink();
        },
      ),
    );
    expect(snapshots, hasLength(1));
    expect(snapshots.last.connectionState, ConnectionState.done);
    expect(snapshots.last.data, 10);

    await tester.pumpWidget(
      AsyncListenableBuilder(
        asyncListenable: asyncNotifier2,
        builder: (context, snapshot) {
          snapshots.add(snapshot);
          return const SizedBox.shrink();
        },
      ),
    );
    expect(snapshots, hasLength(2));
    expect(snapshots.last.connectionState, ConnectionState.done);
    expect(snapshots.last.data, 20);

    asyncNotifier1.setFuture(Future.value(11));
    asyncNotifier2.setFuture(Future.value(21));

    await tester.pump();
    expect(snapshots, hasLength(3));
    expect(snapshots.last.connectionState, ConnectionState.done);
    expect(snapshots.last.data, 21);
  });
}
