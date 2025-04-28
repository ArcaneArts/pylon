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

  /// Creates a [MutablePylon] widget.
  /// 
  /// The [value] parameter is the initial value to be provided to descendant widgets.
  /// The [builder] parameter is a function that creates a child widget with access to the pylon value.
  /// If [local] is true, the pylon won't be transferred across navigation routes.
  /// If [rebuildChildren] is true, descendants will rebuild when the value changes.
  const MutablePylon(
      {super.key,
      required this.value,
      required this.builder,
      this.local = false,
      this.rebuildChildren = false});

  /// Returns the state object of the nearest ancestor [MutablePylon] widget of type [T] or null if not found.
  /// 
  /// This method searches up the widget tree for a [MutablePylon<T>] widget and returns its state.
  /// If no matching [MutablePylon] is found, returns null.
  /// 
  /// The returned state object allows direct modification of the pylon value.
  /// 
  /// Example:
  /// ```dart
  /// // Get the state of the nearest MutablePylon<int> or null if not found
  /// MutablePylonState<int>? state = MutablePylon.ofOr<int>(context);
  /// if (state != null) {
  ///   state.value += 1;
  /// }
  /// ```
  static MutablePylonState<T>? ofOr<T>(BuildContext context) =>
      context.findAncestorStateOfType<MutablePylonState<T>>();

  /// Returns the state object of the nearest ancestor [MutablePylon] widget of type [T] or throws an error if not found.
  /// 
  /// This method searches up the widget tree for a [MutablePylon<T>] widget and returns its state.
  /// If no matching [MutablePylon] is found, it throws an error.
  /// 
  /// The returned state object allows direct modification of the pylon value.
  /// 
  /// Example:
  /// ```dart
  /// // Get the state of the nearest MutablePylon<int> and increment its value
  /// MutablePylon.of<int>(context).value += 1;
  /// ```
  static MutablePylonState<T> of<T>(BuildContext context) => ofOr<T>(context)!;

  @override
  State<MutablePylon> createState() => MutablePylonState<T>();
}

/// The state for a [MutablePylon] widget.
/// 
/// This class manages the mutable state of a [MutablePylon] widget, providing
/// access to the current value and methods to update it. It also exposes a stream
/// of value changes that can be used for reactive programming.
/// 
/// The state can be accessed using the static methods of [MutablePylon]:
/// - [MutablePylon.of] - Gets the state or throws if not found
/// - [MutablePylon.ofOr] - Gets the state or returns null if not found
class MutablePylonState<T> extends State<MutablePylon> {
  /// The subject used to expose a stream of value changes.
  /// 
  /// This is lazily initialized when [stream] is first accessed.
  BehaviorSubject<T>? _subject;

  /// The current value of the pylon.
  late T _value;

  /// Gets the current value of the pylon.
  /// 
  /// This is the value that is provided to descendant widgets.
  T get value => _value;

  /// Sets the current value of the pylon.
  /// 
  /// When [MutablePylon.rebuildChildren] is true, this will trigger a rebuild of the widget.
  /// In all cases, the new value will be added to the [stream] for reactive listeners.
  /// 
  /// If a rebuild fails (e.g., if the widget is no longer in the tree), the value
  /// will still be updated but the stack trace will be printed to the debug console.
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

  /// Returns a stream of value changes.
  /// 
  /// This stream emits the current value when subscribed to and then emits
  /// subsequent values whenever the value is changed.
  /// 
  /// The stream uses a [BehaviorSubject] internally, which means it remembers the
  /// last value that was emitted and sends it to new subscribers immediately.
  /// 
  /// Example:
  /// ```dart
  /// // Get the state and subscribe to value changes
  /// final state = MutablePylon.of<int>(context);
  /// state.stream.listen((value) {
  ///   print("Value changed to $value");
  /// });
  /// ```
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
