import 'dart:async';

import 'package:async_listenable/async_listenable.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Future', () {
    test('setFuture(Future.value()) flow: waiting -> done (with value)',
        () async {
      final notifier = AsyncNotifier<int>();
      final future = Future.value(42);
      notifier.setFuture(future);
      expect(notifier.snapshot.connectionState, ConnectionState.waiting);
      expect(notifier.snapshot.data, null);

      await future;
      expect(notifier.snapshot.connectionState, ConnectionState.done);
      expect(notifier.snapshot.data, 42);
    });
    test('setFuture(Future.error()) flow: waiting -> done (with error)',
        () async {
      final notifier = AsyncNotifier<int>();
      final future = Future<int>.error('error');
      notifier.setFuture(future);
      expect(notifier.snapshot.connectionState, ConnectionState.waiting);
      expect(notifier.snapshot.error, null);

      try {
        await future;
      } catch (_) {}
      expect(notifier.snapshot.connectionState, ConnectionState.done);
      expect(notifier.snapshot.error, 'error');
    });
    test(
      'setFuture(SynchronousFuture) initializes the snapshot synchronously',
      () {
        final notifier = AsyncNotifier<int>();
        final future = SynchronousFuture(42);
        notifier.setFuture(future);
        expect(notifier.snapshot.connectionState, ConnectionState.done);
        expect(notifier.snapshot.data, 42);
      },
    );
    test(
      'setFuture(SynchronousFuture) updates the snapshot synchronously',
      () async {
        final notifier = AsyncNotifier<int>();
        final future = Future.value(42);
        notifier.setFuture(future);
        await future;
        expect(notifier.snapshot.connectionState, ConnectionState.done);
        expect(notifier.snapshot.data, 42);

        notifier.setFuture(SynchronousFuture(43));
        expect(notifier.snapshot.connectionState, ConnectionState.done);
        expect(notifier.snapshot.data, 43);

        notifier.setFuture(SynchronousFuture(44));
        expect(notifier.snapshot.connectionState, ConnectionState.done);
        expect(notifier.snapshot.data, 44);
      },
    );
    test(
      'set(T) initializes the snapshot synchronously',
      () {
        final notifier = AsyncNotifier<int>();
        notifier.set(42);
        expect(notifier.snapshot.connectionState, ConnectionState.done);
        expect(notifier.snapshot.data, 42);
      },
    );
    test(
      'set(Future<T>) initializes the snapshot asynchronously',
      () async {
        final notifier = AsyncNotifier<int>();
        final future = Future.value(42);
        notifier.set(future);
        expect(notifier.snapshot.connectionState, ConnectionState.waiting);
        expect(notifier.snapshot.data, null);

        await future;
        expect(notifier.snapshot.connectionState, ConnectionState.done);
        expect(notifier.snapshot.data, 42);
      },
    );
    test(
      'set(T) can be replaced with set(Future<T>) or set(SynchronousFuture<T>)',
      () async {
        final notifier = AsyncNotifier<int>();
        notifier.set(42);
        expect(notifier.snapshot.connectionState, ConnectionState.done);
        expect(notifier.snapshot.data, 42);

        final future = Future.value(43);
        notifier.set(future);
        expect(notifier.snapshot.connectionState, ConnectionState.waiting);
        expect(notifier.snapshot.data, 42); // prev data is preserved by default
        await future;
        expect(notifier.snapshot.connectionState, ConnectionState.done);
        expect(notifier.snapshot.data, 43);

        final synchronousFuture = SynchronousFuture(44);
        notifier.set(synchronousFuture);
        expect(notifier.snapshot.connectionState, ConnectionState.done);
        expect(notifier.snapshot.data, 44);
      },
    );
    test(
        'setFuture(initialData:) flow: waiting (with data) -> done (with data)',
        () async {
      final notifier = AsyncNotifier<int>();
      final future = Future<int>.value(43);
      notifier.setFuture(future, initialData: () => 42);
      expect(notifier.snapshot.connectionState, ConnectionState.waiting);
      expect(notifier.snapshot.data, 42);

      await Future.value();
      expect(notifier.snapshot.connectionState, ConnectionState.done);
      expect(notifier.snapshot.data, 43);
    });
    test(
        'setFuture(initialError:) flow: waiting (with error) -> done (with error)',
        () async {
      final notifier = AsyncNotifier<int>();
      final future = Future<int>.error('error');
      notifier.setFuture(future, initialError: () => ('initialError', null));
      expect(notifier.snapshot.connectionState, ConnectionState.waiting);
      expect(notifier.snapshot.error, 'initialError');

      await Future.value();
      expect(notifier.snapshot.connectionState, ConnectionState.done);
      expect(notifier.snapshot.error, 'error');
    });
    test(
      'when uncompleted Future is replaced with setFuture(), only the new Future\'s snapshots are notified',
      () => fakeAsync((async) {
        final notifier = AsyncNotifier<int>();

        final future1 = Future.delayed(const Duration(seconds: 1), () => 42);
        notifier.setFuture(future1);
        async.elapse(const Duration(milliseconds: 500));
        expect(notifier.snapshot.connectionState, ConnectionState.waiting);
        expect(notifier.snapshot.data, isNull);

        final future2 = Future.delayed(const Duration(seconds: 2), () => 43);
        notifier.setFuture(future2);
        async.elapse(const Duration(seconds: 1));
        expect(notifier.snapshot.connectionState, ConnectionState.waiting);
        expect(notifier.snapshot.data, isNull);

        async.elapse(const Duration(seconds: 1));
        expect(notifier.snapshot.connectionState, ConnectionState.done);
        expect(notifier.snapshot.data, 43);
      }),
    );
    test(
      'when completed Future is replaced via setFuture(), the previous data is kept',
      () => fakeAsync((async) {
        final notifier = AsyncNotifier<int>();

        final future1 = Future.delayed(const Duration(seconds: 1), () => 42);
        notifier.setFuture(future1);
        expect(notifier.snapshot.connectionState, ConnectionState.waiting);
        expect(notifier.snapshot.data, null);

        async.elapse(const Duration(seconds: 1));
        expect(notifier.snapshot.connectionState, ConnectionState.done);
        expect(notifier.snapshot.data, 42);

        final future2 = Future.delayed(const Duration(seconds: 1), () => 43);
        notifier.setFuture(future2);
        expect(notifier.snapshot.connectionState, ConnectionState.waiting);
        expect(notifier.snapshot.data, 42);

        async.elapse(const Duration(milliseconds: 500));
        expect(notifier.snapshot.connectionState, ConnectionState.waiting);
        expect(notifier.snapshot.data, 42);

        async.elapse(const Duration(milliseconds: 500));
        expect(notifier.snapshot.connectionState, ConnectionState.done);
        expect(notifier.snapshot.data, 43);
      }),
    );
    test(
      'when completed Future is replaced via setFuture(resetSnapshot: true), the previous data is cleared',
      () => fakeAsync((async) {
        final notifier = AsyncNotifier<int>();

        final future1 = Future.delayed(const Duration(seconds: 1), () => 42);
        notifier.setFuture(future1);
        expect(notifier.snapshot.connectionState, ConnectionState.waiting);
        expect(notifier.snapshot.data, null);

        async.elapse(const Duration(seconds: 1));
        expect(notifier.snapshot.connectionState, ConnectionState.done);
        expect(notifier.snapshot.data, 42);

        final future2 = Future.delayed(const Duration(seconds: 1), () => 43);
        notifier.setFuture(future2, resetSnapshot: true);
        expect(notifier.snapshot.connectionState, ConnectionState.waiting);
        expect(notifier.snapshot.data, null);

        async.elapse(const Duration(milliseconds: 500));
        expect(notifier.snapshot.connectionState, ConnectionState.waiting);
        expect(notifier.snapshot.data, null);

        async.elapse(const Duration(milliseconds: 500));
        expect(notifier.snapshot.connectionState, ConnectionState.done);
        expect(notifier.snapshot.data, 43);
      }),
    );
  });
  group('Stream', () {
    test(
        'setStream(Stream.value()) flow: waiting -> active (with data) -> done (with data)',
        () async {
      final notifier = AsyncNotifier<int>();
      final stream = Stream.value(42);
      notifier.setStream(stream);
      expect(notifier.snapshot.connectionState, ConnectionState.waiting);

      await Future.value();
      expect(notifier.snapshot.connectionState, ConnectionState.active);
      expect(notifier.snapshot.data, 42);

      await Future.value();
      expect(notifier.snapshot.connectionState, ConnectionState.done);
      expect(notifier.snapshot.data, 42);
    });
    test(
        'setStream(Stream.error()) flow: waiting -> active (with error) -> done (with error)',
        () async {
      final notifier = AsyncNotifier<int>();
      final stream = Stream<int>.error('error');
      notifier.setStream(stream);
      expect(notifier.snapshot.connectionState, ConnectionState.waiting);

      await Future.value();
      expect(notifier.snapshot.connectionState, ConnectionState.active);
      expect(notifier.snapshot.error, 'error');

      await Future.value();
      expect(notifier.snapshot.connectionState, ConnectionState.done);
      expect(notifier.snapshot.error, 'error');
    });
    test('setStream(<synchronous future>) updates the snapshot synchronously',
        () async {
      final notifier = AsyncNotifier<int>();
      final stream = _SynchronousStreamView<int>.value(Stream.value(42), 42);
      notifier.setStream(stream);
      expect(notifier.snapshot.connectionState, ConnectionState.active);
      expect(notifier.snapshot.data, 42);

      await Future.value();
      await Future.value();
      expect(notifier.snapshot.connectionState, ConnectionState.done);
      expect(notifier.snapshot.data, 42);
    });
    test(
        'setStream(initialData:) flow: waiting (with data) -> active (with data) -> done (with data)',
        () async {
      final notifier = AsyncNotifier<int>();
      final stream = Stream.value(43);
      notifier.setStream(stream, initialData: () => 42);
      expect(notifier.snapshot.connectionState, ConnectionState.waiting);
      expect(notifier.snapshot.data, 42);

      await Future.value();
      expect(notifier.snapshot.connectionState, ConnectionState.active);
      expect(notifier.snapshot.data, 43);

      await Future.value();
      expect(notifier.snapshot.connectionState, ConnectionState.done);
      expect(notifier.snapshot.data, 43);
    });
    test(
        'setStream(initialError:) flow: waiting (with error) -> active (with error) -> done (with error)',
        () async {
      final notifier = AsyncNotifier<int>();
      final stream = Stream<int>.error('error');
      notifier.setStream(stream, initialError: () => ('initialError', null));
      expect(notifier.snapshot.connectionState, ConnectionState.waiting);
      expect(notifier.snapshot.error, 'initialError');

      await Future.value();
      expect(notifier.snapshot.connectionState, ConnectionState.active);
      expect(notifier.snapshot.error, 'error');

      await Future.value();
      expect(notifier.snapshot.connectionState, ConnectionState.done);
      expect(notifier.snapshot.error, 'error');
    });
    test(
      'when in-progress Stream is replaced via setStream(), the previous data is kept',
      () => fakeAsync((async) {
        final notifier = AsyncNotifier<int>();

        final stream1 = Stream.periodic(const Duration(seconds: 1), (_) => 42);
        notifier.setStream(stream1);
        expect(notifier.snapshot.connectionState, ConnectionState.waiting);
        expect(notifier.snapshot.data, null);

        async.elapse(const Duration(seconds: 1));
        expect(notifier.snapshot.connectionState, ConnectionState.active);
        expect(notifier.snapshot.data, 42);

        final stream2 = Stream.periodic(const Duration(seconds: 1), (_) => 43);
        notifier.setStream(stream2);
        expect(notifier.snapshot.connectionState, ConnectionState.waiting);
        expect(notifier.snapshot.data, 42);

        async.elapse(const Duration(milliseconds: 500));
        expect(notifier.snapshot.connectionState, ConnectionState.waiting);
        expect(notifier.snapshot.data, 42);

        async.elapse(const Duration(milliseconds: 500));
        expect(notifier.snapshot.connectionState, ConnectionState.active);
        expect(notifier.snapshot.data, 43);
      }),
    );
    test(
      'when in-progress Stream is replaced via setStream(resetSnapshot: true), the previous data is cleared',
      () => fakeAsync((async) {
        final notifier = AsyncNotifier<int>();

        final stream1 = Stream.periodic(const Duration(seconds: 1), (_) => 42);
        notifier.setStream(stream1);
        expect(notifier.snapshot.connectionState, ConnectionState.waiting);
        expect(notifier.snapshot.data, null);

        async.elapse(const Duration(seconds: 1));
        expect(notifier.snapshot.connectionState, ConnectionState.active);
        expect(notifier.snapshot.data, 42);

        final stream2 = Stream.periodic(const Duration(seconds: 1), (_) => 43);
        notifier.setStream(stream2, resetSnapshot: true);
        expect(notifier.snapshot.connectionState, ConnectionState.waiting);
        expect(notifier.snapshot.data, null);

        async.elapse(const Duration(milliseconds: 500));
        expect(notifier.snapshot.connectionState, ConnectionState.waiting);
        expect(notifier.snapshot.data, null);

        async.elapse(const Duration(milliseconds: 500));
        expect(notifier.snapshot.connectionState, ConnectionState.active);
        expect(notifier.snapshot.data, 43);
      }),
    );
  });
  test('value changes are not reported after AsyncNotifier.dispose()',
      () async {
    final notifier = AsyncNotifier<int>();
    final streamCtrl = StreamController<int>();
    notifier.setStream(streamCtrl.stream);
    streamCtrl.add(42);
    await Future.value();
    expect(notifier.snapshot.connectionState, ConnectionState.active);
    expect(notifier.snapshot.data, 42);

    notifier.dispose();
    streamCtrl.add(43);
    expect(notifier.snapshot.connectionState, ConnectionState.none);
    expect(notifier.snapshot.data, 42);
  });
}

class _SynchronousStreamView<T> extends StreamView<T> {
  _SynchronousStreamView(super.stream);
  _SynchronousStreamView.value(super.stream, T data)
      : _dataWrapper = _DataWrapper<T>()..data = data;

  _DataWrapper<T>? _dataWrapper;
  Object? _error;
  StackTrace? _stackTrace;
  bool _isDone = false;

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    if (_dataWrapper != null) {
      onData?.call(_dataWrapper!.data);
    }
    if (_error != null) {
      onError?.call(_error, _stackTrace);
    }
    if (_isDone) {
      onDone?.call();
    }
    return super.listen(
      (data) {
        (_dataWrapper ??= _DataWrapper<T>()).data = data;
        onData?.call(data);
      },
      onError: (error, trace) {
        _error = error;
        _stackTrace = trace;
        onError?.call(error, trace);
      },
      onDone: () {
        _isDone = true;
        onDone?.call();
      },
      cancelOnError: cancelOnError,
    );
  }
}

class _DataWrapper<T> {
  late T data;
}
