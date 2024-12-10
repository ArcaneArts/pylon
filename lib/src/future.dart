import 'package:flutter/widgets.dart';
import 'package:pylon/pylon.dart';

/// Combines a [FutureBuilder] with a [Pylon] widget. When the future completes,
/// the value is passed to the [Pylon] widget with the builder function provided
class PylonFuture<T> extends StatelessWidget {
  final Future<T> future;
  final T? initialData;
  final PylonBuilder builder;
  final Widget loading;

  const PylonFuture(
      {super.key,
      required this.future,
      this.initialData,
      required this.builder,
      this.loading = const SizedBox.shrink()});

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
      future: future,
      initialData: initialData,
      builder: (context, snap) => snap.hasData
          ? Pylon<T>(
              value: snap.data as T,
              builder: builder,
            )
          : loading);
}
