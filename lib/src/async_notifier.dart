import 'dart:async';

import 'package:flutter/widgets.dart';

import 'async_listenable.dart';

/// A [ChangeNotifier] that holds a current state of asynchronous computation.
///
/// When [set], [setFuture] or [setStream] is called, the [AsyncNotifier] will
/// notify its listeners with the latest [AsyncSnapshot] of it.
class AsyncNotifier<T> with ChangeNotifier implements AsyncListenable<T> {
  final _emptySnapshot = AsyncSnapshot<T>.nothing();

  /// The current state of the [AsyncNotifier].
  @override
  AsyncSnapshot<T> get snapshot => _snapshot;
  late AsyncSnapshot<T> _snapshot = _emptySnapshot;

  @override
  AsyncSnapshot<T> get value => _snapshot;

  Future<T>? _future;
  Stream<T>? _stream;
  StreamSubscription<T>? _streamSubscription;

  /// Track a [FutureOr] and notify listeners with the latest [AsyncSnapshot]
  /// of it. If [futureOrValue] is not a [Future], the [snapshot] will be
  /// transitioned to [ConnectionState.done] with the provided value synchronously.
  ///
  /// If [initialData] or [initialError] is provided, the [snapshot] will be
  /// in the [ConnectionState.waiting] state with the provided data/error until
  /// the [future] completes, unless the [future] completes synchronously
  /// (e.g. [SynchronousFuture]).
  ///
  /// By default, the data/error of a previous [snapshot] will be preserved
  /// until the [future] completes. This can be changed by setting
  /// [resetSnapshot] to true.
  FutureOr<T> set(
    FutureOr<T> futureOrValue, {
    T Function()? initialData,
    (Object, StackTrace?) Function()? initialError,
    bool resetSnapshot = false,
  }) {
    if (futureOrValue is T) {
      _future = null;
      _updateSnapshot(
        AsyncSnapshot<T>.withData(ConnectionState.done, futureOrValue),
      );
      return futureOrValue;
    }
    return setFuture(
      futureOrValue,
      initialData: initialData,
      initialError: initialError,
      resetSnapshot: resetSnapshot,
    );
  }

  /// Track a [Future] and notify listeners with the latest [AsyncSnapshot]
  /// of it.
  ///
  /// If [initialData] or [initialError] is provided, the [snapshot] will be
  /// in the [ConnectionState.waiting] state with the provided data/error until
  /// the [future] completes, unless the [future] completes synchronously
  /// (e.g. [SynchronousFuture]).
  ///
  /// By default, the data/error of a previous [snapshot] will be preserved
  /// until the [future] completes. This can be changed by setting
  /// [resetSnapshot] to true.
  Future<T> setFuture(
    Future<T> future, {
    T Function()? initialData,
    (Object, StackTrace?) Function()? initialError,
    bool resetSnapshot = false,
  }) {
    assert(
      initialData == null && initialError == null ||
          initialData != null && initialError == null ||
          initialData == null && initialError != null,
      'Provide either initialData or initialError, but not both.',
    );

    _future = future;

    AsyncSnapshot<T>? newSnapshot;
    final resultFuture = future.then((data) {
      if (_future != future) return future;

      newSnapshot = AsyncSnapshot<T>.withData(ConnectionState.done, data);
      _updateSnapshot(newSnapshot!);
      return future;
    }, onError: (Object error, StackTrace stackTrace) {
      if (_future != future) return future;

      newSnapshot =
          AsyncSnapshot<T>.withError(ConnectionState.done, error, stackTrace);
      _updateSnapshot(newSnapshot!);
      return future;
    });

    // An implementation like `SynchronousFuture` may have already called the
    // .then closure. Do not overwrite it in that case.
    if (newSnapshot != null) return resultFuture;

    _initializeSnapshot(
      initialData: initialData,
      initialError: initialError,
      resetSnapshot: resetSnapshot,
    );
    return resultFuture;
  }

  /// Track a [Stream] and notify listeners with the latest [AsyncSnapshot]
  /// of it.
  ///
  /// If [initialData] or [initialError] is provided, the [snapshot] will be
  /// in the [ConnectionState.waiting] state with the provided data/error until
  /// the [stream] emits anything, unless the [stream] emits the initial
  /// value/error synchronously.
  ///
  /// By default, the data/error of a previous [snapshot] will be preserved
  /// until the [stream] emits something. This can be changed by setting
  /// [resetSnapshot] to true.
  void setStream(
    Stream<T> stream, {
    T Function()? initialData,
    (Object, StackTrace?) Function()? initialError,
    bool resetSnapshot = false,
  }) {
    assert(
      initialData == null && initialError == null ||
          initialData != null && initialError == null ||
          initialData == null && initialError != null,
      'Provide either initialData or initialError, but not both.',
    );

    _stream = stream;

    AsyncSnapshot<T>? newSnapshot;
    _streamSubscription?.cancel();
    _streamSubscription = stream.listen((data) {
      if (_stream != stream) return;

      newSnapshot = AsyncSnapshot<T>.withData(ConnectionState.active, data);
      _updateSnapshot(newSnapshot!);
    }, onError: (Object error, StackTrace stackTrace) {
      if (_stream != stream) return;

      newSnapshot =
          AsyncSnapshot<T>.withError(ConnectionState.active, error, stackTrace);
      _updateSnapshot(newSnapshot!);
    }, onDone: () {
      if (_stream != stream) return;

      newSnapshot =
          (newSnapshot ?? _emptySnapshot).inState(ConnectionState.done);
      _updateSnapshot(newSnapshot!);
    });

    // A `Stream` implementation may have already called the
    // .onData/.onError/.onDone closure. Do not overwrite it in that case.
    if (newSnapshot != null) return;

    _initializeSnapshot(
      initialData: initialData,
      initialError: initialError,
      resetSnapshot: resetSnapshot,
    );
  }

  @override
  void dispose() {
    _future = null;
    _stream = null;
    _streamSubscription?.cancel();
    _updateSnapshot(_snapshot.inState(ConnectionState.none));
    super.dispose();
  }

  void _initializeSnapshot({
    required T Function()? initialData,
    required (Object, StackTrace?) Function()? initialError,
    required bool resetSnapshot,
  }) {
    if (initialData != null) {
      return _updateSnapshot(
        AsyncSnapshot<T>.withData(
          ConnectionState.waiting,
          initialData(),
        ),
      );
    }
    if (initialError != null) {
      final (error, trace) = initialError();
      return _updateSnapshot(
        AsyncSnapshot<T>.withError(
          ConnectionState.waiting,
          error,
          trace ?? StackTrace.empty,
        ),
      );
    }
    _updateSnapshot(
      (resetSnapshot ? _emptySnapshot : _snapshot)
          .inState(ConnectionState.waiting),
    );
  }

  void _updateSnapshot(AsyncSnapshot<T> newSnapshot) {
    final didChange = _snapshot != newSnapshot;
    _snapshot = newSnapshot;
    if (didChange) {
      notifyListeners();
    }
  }
}
