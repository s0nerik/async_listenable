# async_listenable

[![async_listenable](https://img.shields.io/codecov/c/github/s0nerik/async_listenable)](https://app.codecov.io/github/s0nerik/async_listenable)
[![async_listenable](https://img.shields.io/pub/v/async_listenable)](https://pub.dev/packages/async_listenable)
[![async_listenable](https://img.shields.io/pub/likes/async_listenable)](https://pub.dev/packages/async_listenable)
[![async_listenable](https://img.shields.io/pub/points/async_listenable)](https://pub.dev/packages/async_listenable)
[![async_listenable](https://img.shields.io/pub/popularity/async_listenable)](https://pub.dev/packages/async_listenable)

Same as `ValueListenable`/`ValueNotifier`, but for `Stream` and `Future`.
Allows for observing the `AsyncSnapshot` of an async operation outside the widget/element tree.

## Features

- `AsyncListenable`
  - An interface for observing async operation state.
  - Same as `ValueListenable`, but provides the `AsyncSnapshot`.
- `AsyncListenableBuilder`
  - Same as `ValueListenableBuilder`/`StreamBuilder`/`FutureBuilder`, but for `AsyncListenable`.
  - Provides `AsyncSnapshot` as a value.
- `AsyncNotifier`
  - A mutable implementation of `AsyncListenable`.
  - Tracks `Future` or `Stream` state and notifies listeners when it changes by providing an `AsyncSnapshot`.

## Usage

```dart
/// Create a notifier. [snapshot] will return the `AsyncSnapshot.nothing()`
/// until the future/stream is set.
final notifier = AsyncNotifier<int>()
  /// initialize it right away with a future
  ..setFuture(Future.value(42));
  /// ...or with a [SynchronousFuture] (for synchronous initialization)
  ..set(SynchronousFuture(42));
  /// ...or with a value (for synchronous initialization)
  ..set(42);
  /// ...or with a stream
  ..setStream(Stream.value(42));
  /// ...or with a future/stream and an initial value
  ..setFuture(Future.value(42), initialData: () => 0);
  /// ...or with a future/stream and an initial error
  ..setStream(Stream.error('error'), initialError: () => SomeException());

/// Replace the future/stream with a new Future.
notifier.set(Future.value(42));
/// ...or with a synchronous future (for synchronous snapshot update)
notifier.set(SynchronousFuture(42));
/// ...or with a value (for synchronous snapshot update)
notifier.set(42);
/// ...or with a stream
///
/// By default, [set], [setFuture] and [setStream] will will_not reset the
/// data/error state of a [snapshot] until the new future/stream emits something.
/// If you want to fully reset the snapshot state, pass [resetSnapshot: true].
/// 
/// If stream emits the initial value/error synchronously, the [snapshot] will
/// be updated synchronously.
notifier.setStream(Stream.value(42), resetSnapshot: true);

/// Get the current snapshot.
notifier.snapshot;

/// Listen to the snapshot changes.
notifier.addListener((snapshot) {
  print(snapshot.data);
});

/// Rebuild the widget when the snapshot changes.
AsyncListenableBuilder(
  notifier: notifier,
  builder: (context, snapshot) {
    return Text(snapshot.data.toString());
  },
);
```
