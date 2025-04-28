import 'package:flutter/widgets.dart';
import 'package:pylon/pylon.dart';

/// A widget that combines a [StreamBuilder] with a [Pylon] widget to provide reactive state management.
/// 
/// [PylonStream] listens to a [Stream] of values and automatically updates a [Pylon] with the latest
/// emitted value. This allows descendant widgets to reactively access stream data through the pylon
/// context extensions without directly managing stream subscriptions or explicitly rebuilding.
///
/// When the stream emits a new value, the [Pylon] is updated with that value, causing dependent
/// widgets to rebuild. If the stream hasn't emitted any data yet, the [loading] widget is shown instead.
///
/// This is particularly useful for:
/// - Connecting asynchronous data sources (like Firebase, web sockets, or other event sources) to Pylon state
/// - Building reactive UIs that respond to changing data streams
/// - Simplifying stream subscription management in Flutter applications
///
/// Example usage:
/// ```dart
/// PylonStream<int>(
///   stream: counterStream,
///   initialData: 0,
///   builder: (context) => Text('Count: ${context.pylon<int>()}'),
///   loading: CircularProgressIndicator(),
/// )
/// ```
class PylonStream<T> extends StatelessWidget {
  /// The source [Stream] that will emit values of type [T].
  /// 
  /// This stream is listened to by the internal [StreamBuilder], and each emitted
  /// value is passed to a [Pylon] widget.
  final Stream<T> stream;
  
  /// Optional initial data to use before the stream emits its first value.
  /// 
  /// If provided, this value will be used to initialize the [Pylon] before
  /// any data is received from the [stream]. This prevents showing the [loading]
  /// widget if you have a sensible default value.
  final T? initialData;
  
  /// A function that builds a widget with access to the latest stream value through the [Pylon].
  /// 
  /// This builder function receives a [BuildContext] that can access the stream's latest
  /// value using the pylon context extensions (e.g., `context.pylon<T>()`).
  final PylonBuilder builder;
  
  /// The widget to display when the stream has not yet emitted any data.
  /// 
  /// By default, this is an empty [SizedBox.shrink()] widget. You might want to
  /// provide a loading indicator like [CircularProgressIndicator] for a better UX.
  final Widget loading;

  /// Creates a [PylonStream] widget.
  /// 
  /// The [stream] and [builder] parameters are required.
  /// The [initialData] parameter is optional and provides a value to use before the stream emits.
  /// The [loading] parameter defines what to show while waiting for the first stream value,
  /// defaulting to an empty widget.
  const PylonStream({
    super.key,
    required this.stream,
    this.initialData,
    required this.builder,
    this.loading = const SizedBox.shrink()
  });

  @override
  Widget build(BuildContext context) => StreamBuilder<T>(
      stream: stream,
      initialData: initialData,
      builder: (context, snap) => snap.hasData
          ? Pylon<T>(
              value: snap.data as T,
              builder: builder,
            )
          : loading);
}
