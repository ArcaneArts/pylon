import 'package:flutter/widgets.dart';
import 'package:pylon/pylon.dart';

/// Combines a [StreamBuilder] with a [Pylon] widget. When the stream emits a value,
/// the value is passed to the [Pylon] widget with the builder function provided
class PylonStream<T> extends StatelessWidget {
  final Stream<T> stream;
  final T? initialData;
  final PylonBuilder builder;
  final Widget loading;

  const PylonStream(
      {super.key,
      required this.stream,
      this.initialData,
      required this.builder,
      this.loading = const SizedBox.shrink()});

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
