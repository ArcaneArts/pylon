import 'package:flutter/widgets.dart';
import 'package:pylon/pylon.dart';

/// A widget that combines a [FutureBuilder] with a [Pylon] widget to handle asynchronous data loading.
///
/// [PylonFuture] manages the loading, error, and data states of a [Future], and when the future
/// completes successfully, it automatically wraps the result in a [Pylon] widget, making the value
/// available to descendant widgets.
///
/// This is particularly useful for:
/// - Loading data from an API and making it available in the widget tree
/// - Handling asynchronous initialization before providing state to your app
/// - Simplifying the pattern of "load data → provide data → build UI with data"
///
/// Example usage:
/// ```dart
/// PylonFuture<User>(
///   future: userRepository.fetchUser(userId),
///   loading: CircularProgressIndicator(),
///   error: Text("Failed to load user"),
///   builder: (context) => UserProfileScreen(),
/// )
/// ```
class PylonFuture<T> extends StatelessWidget {
  /// The [Future] that will provide the value for the [Pylon].
  ///
  /// This future is passed to a [FutureBuilder] internally. When it completes successfully,
  /// its result becomes the value of the created [Pylon].
  final Future<T> future;

  /// Optional initial data for the future.
  ///
  /// If provided, this value will be used as the pylon value until the [future] completes.
  /// If not provided, the [loading] widget will be shown until the future completes.
  final T? initialData;

  /// A builder function that creates a widget with access to the [Pylon] value.
  ///
  /// This builder is passed to the [Pylon] widget created once the [future] completes
  /// successfully. The builder will have access to the future's result through
  /// `context.pylon<T>()`.
  final PylonBuilder builder;

  /// The widget to display while the future is loading.
  ///
  /// This widget is shown when the future has not yet completed and [initialData] is null.
  /// Defaults to an empty [SizedBox] if not specified.
  final Widget loading;

  /// The widget to display if the future completes with an error.
  ///
  /// This widget is shown if the [future] encounters an error during execution.
  /// Defaults to a simple "Something went wrong" text widget if not specified.
  final Widget error;

  /// Creates a [PylonFuture] widget.
  ///
  /// The [future] and [builder] parameters are required:
  /// - [future] is the asynchronous operation that will provide the pylon value
  /// - [builder] is the function that creates a widget with access to that value
  ///
  /// Optional parameters:
  /// - [initialData]: Initial value to use before the future completes
  /// - [loading]: Widget to show while the future is in progress (defaults to empty SizedBox)
  /// - [error]: Widget to show if the future fails (defaults to error message text)
  /// - [key]: Widget key
  const PylonFuture({
    super.key,
    required this.future,
    required this.builder,
    this.initialData,
    this.loading = const SizedBox.shrink(),
    this.error = const Text("Something went wrong"),
  });

  @override
  /// Builds a [FutureBuilder] that handles the async state of [future] and creates
  /// a [Pylon] with the result when available.
  ///
  /// The build method returns:
  /// - The [error] widget if the future completes with an error
  /// - A [Pylon] containing the future's result if available
  /// - The [loading] widget while waiting for the future to complete
  Widget build(BuildContext context) => FutureBuilder<T>(
      future: future,
      initialData: initialData,
      builder: (context, snap) => snap.hasError
          ? error
          : snap.hasData
              ? Pylon<T>(
                  value: snap.data as T,
                  builder: builder,
                )
              : loading);
}
