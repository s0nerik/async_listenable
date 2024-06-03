import 'async_listenable.dart';
import 'package:flutter/widgets.dart';

typedef AsyncListenableWidgetBuilder<T> = Widget Function(
  BuildContext context,
  AsyncSnapshot<T> snapshot,
);

/// Subscribe to an [AsyncListenable] and build a widget in response to the
/// latest snapshot.
///
/// The [builder] is called at the discretion of the [AsyncListenable], and will
/// thus receive a value every time the [AsyncListenable] publishes an update.
///
/// The [builder] will be called immediately with the current snapshot of the
/// [AsyncListenable].
///
/// Replacing the [asyncListenable] will unsubscribe from the old [AsyncListenable]
/// and resubscribe to the new [AsyncListenable], building the widget with the
/// latest snapshot of the new [AsyncListenable].
class AsyncListenableBuilder<T>
    extends _AsyncListenableBuilderBase<T, AsyncSnapshot<T>> {
  const AsyncListenableBuilder({
    super.key,
    required super.asyncListenable,
    required super.builder,
  });
}

abstract class _AsyncListenableBuilderBase<T, S> extends StatefulWidget {
  const _AsyncListenableBuilderBase({
    super.key,
    required this.asyncListenable,
    required this.builder,
  });

  final AsyncListenable<T> asyncListenable;
  final AsyncListenableWidgetBuilder<T> builder;

  @override
  State<_AsyncListenableBuilderBase<T, S>> createState() =>
      _AsyncListenableBuilderBaseState<T, S>();
}

class _AsyncListenableBuilderBaseState<T, S>
    extends State<_AsyncListenableBuilderBase<T, S>> {
  @override
  void initState() {
    super.initState();
    widget.asyncListenable.addListener(_onAsyncListenableUpdate);
  }

  @override
  void didUpdateWidget(covariant _AsyncListenableBuilderBase<T, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.asyncListenable != oldWidget.asyncListenable) {
      oldWidget.asyncListenable.removeListener(_onAsyncListenableUpdate);
      widget.asyncListenable.addListener(_onAsyncListenableUpdate);
    }
  }

  @override
  void dispose() {
    widget.asyncListenable.removeListener(_onAsyncListenableUpdate);
    super.dispose();
  }

  void _onAsyncListenableUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, widget.asyncListenable.snapshot);
}
