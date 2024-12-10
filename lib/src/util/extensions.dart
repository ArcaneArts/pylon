import 'package:flutter/widgets.dart';
import 'package:pylon/pylon.dart';
import 'package:toxic/toxic.dart';

extension XPylonStream<T> on Stream<T> {
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

extension XPylonIterable<T> on Iterable<T> {
  List<Widget> withPylons(PylonBuilder builder) =>
      map((e) => Pylon<T>(value: e, builder: builder)).toList();
}

extension XContextPylon on BuildContext {
  /// Returns true if a pylon is available for the given type
  bool hasPylon<T>({Type? runtime}) => pylonOr<T>(runtime: runtime) != null;

  /// Returns the value of the nearest ancestor [Pylon] widget of type T or null
  T? pylonOr<T>({Type? runtime}) => runtime != null
      ? Pylon.visiblePylons(this)
          .select((i) => i.value.runtimeType == runtime)
          ?.value
      : Pylon.widgetOfOr<T>(this)?.value ?? Pylon.widgetOfOr<T?>(this)?.value;

  /// Returns the value of the nearest ancestor [Pylon] widget of type T or throws an error
  T pylon<T>({Type? runtime}) => pylonOr<T>(runtime: runtime)!;

  /// Sets the value of the nearest ancestor [MutablePylon] widget of type T
  /// This will throw an error if the pylon is not mutable or if there is
  /// no [MutablePylon] of type T
  void setPylon<T>(T value) => MutablePylon.of<T>(this).value = value;

  /// Modifies the value of the nearest ancestor [MutablePylon] widget of type T
  void modPylon<T>(T Function(T) modifier) {
    MutablePylonState<T> v = MutablePylon.of<T>(this);
    v.value = modifier(v.value);
  }

  /// Returns the stream of the nearest ancestor [MutablePylon] widget of type T
  Stream<T> streamPylon<T>() => MutablePylon.of<T>(this).stream;

  /// Watch (stream) a pylon value of a [MutablePylon] widget of type T
  /// This does not provide a build context, this is just for small widgets
  Widget watchPylon<T>(Widget Function(T data) builder) => StreamBuilder<T>(
        stream: streamPylon<T>(),
        initialData: pylonOr<T>(),
        builder: (context, snap) =>
            snap.hasData ? builder(snap.data as T) : const SizedBox.shrink(),
      );
}
