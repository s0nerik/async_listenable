import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// An interface for subclasses of [Listenable] that expose a [snapshot].
///
/// This interface is implemented by [AsyncNotifier<T>], and allows other APIs
/// to have a read-only view of the current state of the object, as well as
/// subscribe to changes to that state.
///
/// See also:
///
///  * [AsyncListenableBuilder], a widget that uses a builder callback to
///    rebuild whenever a [AsyncListenable] object triggers its notifications,
///    providing the builder with the current snapshot of the [AsyncListenable].
abstract interface class AsyncListenable<T>
    implements ValueListenable<AsyncSnapshot<T>> {
  /// The current state of the [AsyncListenable].
  AsyncSnapshot<T> get snapshot;
}
