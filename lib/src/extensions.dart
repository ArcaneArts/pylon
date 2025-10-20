import 'package:flutter/widgets.dart';
import 'package:pylon/pylon.dart';
import 'package:toxic/toxic.dart';

/// Extension on [Stream] providing a convenient method to create a [PylonStream] widget
/// for reactive UI updates based on stream emissions in conjunction with [Pylon].
extension XPylonStream<T> on Stream<T> {
  /// Creates a [PylonStream] widget from this stream, using the provided [builder]
  /// to render content based on stream values, with optional [initialData] and [loading] widget.
  Widget asPylon(PylonBuilder builder,
          {Key? key,
          T? initialData,
          Widget loading = const SizedBox.shrink()}) =>
      PylonStream<T>(
        key: key,
        stream: this,
        initialData: initialData,
        builder: builder,
        loading: loading,
      );
}

/// Extension on [Iterable] to transform collections into lists of [Pylon] widgets
/// for building dynamic UIs with multiple [Pylon] instances.
extension XPylonIterable<T> on Iterable<T> {
  /// Maps each item in this iterable to a [Pylon] widget using the provided [builder],
  /// returning a list suitable for use in widget trees.
  List<Widget> withPylons(PylonBuilder builder) =>
      map((e) => Pylon<T>(value: e, builder: builder)).toList();
}

/// Extension on [BuildContext] offering utility methods to access, query, modify,
/// and observe [Pylon] and [MutablePylon] widgets in the widget tree.
extension XContextPylon on BuildContext {
  /// Checks if a [Pylon] widget of type [T] (or matching [runtime] type) is available
  /// in the ancestor chain of this context.
  bool hasPylon<T>({Type? runtime}) => pylonOr<T>(runtime: runtime) != null;

  /// Retrieves the value from the nearest ancestor [Pylon] widget of type [T]
  /// in this context, or null if none found; optionally filters by [runtime] type.
  T? pylonOr<T>({Type? runtime}) => runtime != null
      ? Pylon.visiblePylons(this)
          .select((i) => i.value.runtimeType == runtime)
          ?.value
      : Pylon.widgetOfOr<T>(this)?.value ?? Pylon.widgetOfOr<T?>(this)?.value;

  /// Retrieves the value from the nearest ancestor [Pylon] widget of type [T]
  /// in this context, throwing an error if none found; optionally filters by [runtime] type.
  T pylon<T>({Type? runtime}) => pylonOr<T>(runtime: runtime)!;

  /// Updates the value of the nearest ancestor [MutablePylon] of type [T] in this context
  /// with the provided [value], throwing an error if no mutable [Pylon] of type [T] exists.
  void setPylon<T>(T value) => MutablePylon.of<T>(this).value = value;

  /// Applies a [modifier] function to the current value of the nearest ancestor
  /// [MutablePylon] of type [T] in this context, updating it with the result.
  void modPylon<T>(T Function(T) modifier) {
    MutablePylonState<T> v = MutablePylon.of<T>(this);
    v.value = modifier(v.value);
  }

  /// Returns the reactive [Stream] from the nearest ancestor [MutablePylon] of type [T]
  /// in this context for observing value changes.
  Stream<T> streamPylon<T>() => MutablePylon.of<T>(this).stream;

  /// Builds a widget that watches the [Stream] from the nearest [MutablePylon] of type [T]
  /// using a [StreamBuilder], rendering via the provided [builder] function with initial data
  /// from the current [Pylon] value or a shrunk widget if no data available.
  Widget watchPylon<T>(Widget Function(T data) builder) => StreamBuilder<T>(
        stream: streamPylon<T>(),
        initialData: pylonOr<T>(),
        builder: (context, snap) =>
            snap.hasData ? builder(snap.data as T) : const SizedBox.shrink(),
      );
}
