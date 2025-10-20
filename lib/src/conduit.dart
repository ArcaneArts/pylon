import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';
import 'package:toxic_flutter/extensions/stream.dart';

/// Private global list of all active conduit streams managed by [Conduit] subjects.
List<BehaviorSubject> $conduitStreams = [];

/// A [StatelessWidget] that rebuilds its content based on the latest value from a global
/// [BehaviorSubject] stream for type `T`.
///
/// This widget provides a reactive way to observe and display data changes across the app,
/// using the [builder] function to construct the UI from the current stream value or
/// [defaultData] if the value is null.
class Conduit<T> extends StatelessWidget {
  final Widget Function(BuildContext context, T? value) builder;
  final T? defaultData;

  /// Creates a [Conduit] widget for reactive UI updates.
  ///
  /// The [builder] defines how to render the widget based on the stream's current value.
  const Conduit({super.key, required this.builder, this.defaultData});

  @override
  Widget build(BuildContext context) => stream<T>()
      .buildNullable((value) => builder(context, value ?? defaultData));

  /// Pushes a new value to the global conduit stream for type `T`, triggering rebuilds
  /// in all listening [Conduit] widgets that observe this type.
  static void push<T>(T t) => subject<T>().add(t);

  /// Modifies the current value in the conduit stream for type `T` by applying the given
  /// function `f` to the existing value, then pushing the result to trigger updates.
  static void mod<T>(T Function(T) f) => push<T>(f(pull<T>()));

  /// Modifies the current value (or null) in the conduit stream for type `T` by applying
  /// the given function `f`, then pushing the result; useful for handling nullable states.
  static void modOr<T>(T Function(T?) f) =>
      push<T>(f(subject<T>().valueOrNull));

  /// Destroys all global conduit streams, clearing all managed state across types.
  ///
  /// Call this to reset or clean up all [Conduit]-observed data when needed.
  static void destroyAllConduits() => $conduitStreams.clear();

  /// Destroys the global conduit stream for the specific type `T`, removing its
  /// [BehaviorSubject] from management.
  static void destroy<T>() =>
      $conduitStreams.removeWhere((e) => e is BehaviorSubject<T>);

  /// Retrieves the current value from the global conduit stream for type `T`.
  ///
  /// Throws if no stream exists for `T`.
  static T pull<T>() => subject<T>().value;

  /// Retrieves the current value from the global conduit stream for type `T`, or returns
  /// the provided default `t` if null or no stream exists.
  static T pullOr<T>(T t) => subject<T>().valueOrNull ?? t;

  /// Returns the [Stream] for the global conduit subject of type `T`, for listening
  /// to value changes outside of [Conduit] widgets.
  static Stream<T> stream<T>() => subject<T>().stream;

  /// Retrieves or creates a singleton [BehaviorSubject] for type `T` to manage global
  /// reactive state.
  ///
  /// This subject powers [Conduit] widgets and static methods like [push], ensuring
  /// a single shared stream per type for app-wide data propagation.
  static BehaviorSubject<T> subject<T>() {
    BehaviorSubject<T>? s =
        $conduitStreams.whereType<BehaviorSubject<T>>().firstOrNull;

    if (s == null) {
      s = BehaviorSubject<T>();
      $conduitStreams.add(s);
    }

    return s;
  }
}
