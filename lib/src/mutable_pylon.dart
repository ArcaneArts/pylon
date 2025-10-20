import 'package:flutter/widgets.dart';
import 'package:pylon/pylon.dart';
import 'package:rxdart/rxdart.dart';

/// A stateful widget that provides mutable state management functionality.
///
/// [MutablePylon] extends the functionality of [Pylon] by allowing the provided value
/// to be modified after the widget has been built. It maintains an internal state
/// that can be updated, and optionally rebuilds its children when the value changes.
///
/// The value can be accessed through context extensions just like a regular [Pylon],
/// but the state can be modified by obtaining the [MutablePylonState] using static methods.
///
/// Key features:
/// - Provides mutable state to descendant widgets
/// - Can optionally rebuild children when the value changes
/// - Exposes a stream of value changes for reactive programming
/// - Can be accessed across navigation routes like a regular [Pylon]
///
/// Example:
/// ```dart
/// MutablePylon<int>(
///   value: 0,
///   builder: (context) => Column(
///     children: [
///       Text("Count: ${context.pylon<int>()}"),
///       ElevatedButton(
///         onPressed: () => MutablePylon.of<int>(context).value += 1,
///         child: Text("Increment"),
///       ),
///     ],
///   ),
/// )
/// ```
class MutablePylon<T> extends StatefulWidget {
  /// The initial value of type [T] that will be provided to descendant widgets.
  final T value;

  /// Builder function to create a child widget with access to the pylon value.
  final PylonBuilder builder;

  /// Whether to rebuild the children when the value changes.
  ///
  /// When true, changing the value will trigger a rebuild of the widget and its descendants.
  /// When false (the default), only widgets that explicitly listen to the stream will rebuild.
  final bool rebuildChildren;

  /// If true, this pylon won't be transferred across navigation routes.
  ///
  /// When false (the default), the value will be available in new routes
  /// created using [Pylon.push] and similar navigation methods.
  final bool local;

  /// Creates a [MutablePylon] widget with the specified initial value and builder.
  ///
  /// The [value] sets the initial state provided to descendants via [Pylon] mechanisms.
  /// The [builder] defines how to construct the child widget using the pylon value.
  /// If [local] is true, the pylon state is not preserved across navigation routes.
  /// If [rebuildChildren] is true, the widget rebuilds descendants on value changes.
  const MutablePylon({
    super.key,
    required this.value,
    required this.builder,
    this.local = false,
    this.rebuildChildren = false,
  });

  /// Returns the [MutablePylonState] of the nearest ancestor [MutablePylon<T>] or null if none found.
  ///
  /// This static method traverses the widget tree upward to locate a matching [MutablePylon]
  /// and returns its state for direct value manipulation, or null if no ancestor matches.
  static MutablePylonState<T>? ofOr<T>(BuildContext context) =>
      context.findAncestorStateOfType<MutablePylonState<T>>();

  /// Returns the [MutablePylonState] of the nearest ancestor [MutablePylon<T>], throwing if none found.
  ///
  /// This static method locates the closest [MutablePylon<T>] ancestor and returns its state
  /// for value updates; it throws an error if no matching ancestor exists in the tree.
  static MutablePylonState<T> of<T>(BuildContext context) => ofOr<T>(context)!;

  @override
  State<MutablePylon> createState() => MutablePylonState<T>();
}

/// The [State] class for [MutablePylon], managing mutable value updates and rebuilds.
///
/// This state handles the lifecycle of the mutable value, including initialization,
/// updates that may trigger rebuilds based on [MutablePylon.rebuildChildren], and
/// exposure of a reactive [stream] for listening to changes. It integrates with [Pylon]
/// for providing the value to descendants.
class MutablePylonState<T> extends State<MutablePylon> {
  /// The subject used to expose a stream of value changes.
  ///
  /// This is lazily initialized when [stream] is first accessed.
  BehaviorSubject<T>? _subject;

  /// The current mutable value managed by this [MutablePylonState].
  ///
  /// Reading this getter returns the latest value. Setting it updates the internal state,
  /// emits to the [stream], and conditionally triggers a rebuild if [rebuildChildren] is true.
  late T _value;

  /// The current value of the pylon.
  T get value => _value;

  /// Updates the pylon value, optionally rebuilding the widget tree.
  ///
  /// If [MutablePylon.rebuildChildren] is enabled, this setter invokes [setState] to rebuild
  /// the widget and descendants with the new value. In case of rebuild errors (e.g., widget
  /// disposed), it still updates the value and logs the error. The new value is always
  /// emitted to the [stream] for reactive subscribers, ensuring consistency across listeners.
  set value(T value) {
    if (widget.rebuildChildren) {
      try {
        setState(() {
          _value = value;
        });
      } catch (e, es) {
        _value = value;
        debugPrintStack(label: e.toString(), stackTrace: es);
      }
    } else {
      _value = value;
    }
    _subject?.add(value);
  }

  /// A [Stream] emitting the current and future values of this [MutablePylonState].
  ///
  /// This getter lazily creates a [BehaviorSubject] seeded with the initial value,
  /// allowing new subscribers to immediately receive the latest value and subsequent
  /// updates whenever [value] is set. Useful for reactive UIs that rebuild on changes
  /// without relying on full widget rebuilds.
  Stream<T> get stream => _subject ??= BehaviorSubject.seeded(_value);

  @override
  void initState() {
    // Initialize the value with the initial value provided to the widget
    _value = widget.value;
    super.initState();
  }

  @override
  void dispose() {
    // Close the subject to prevent memory leaks
    _subject?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Pylon<T>(
        value: value,
        builder: widget.builder,
        local: widget.local,
      );
}
