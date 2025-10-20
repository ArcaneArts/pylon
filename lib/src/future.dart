import 'package:flutter/widgets.dart';
import 'package:pylon/pylon.dart';

/// A [StatelessWidget] that integrates a [FutureBuilder] with a [Pylon] to manage asynchronous data loading
/// and provide the resolved value to descendant widgets via the [Pylon] context extension.
///
/// This widget simplifies handling futures by automatically creating a [Pylon] with the future's result
/// upon successful completion, allowing easy access to the data through `context.pylon<T>()` in the builder.
///
/// Key behaviors:
/// - Displays [loading] widget while the future is pending (unless [initialData] is provided).
/// - Shows [error] widget if the future fails.
/// - Wraps the resolved data in a [Pylon] for the [builder] to consume, enabling reactive UI updates.
///
/// Use this for scenarios like API data fetching, async initialization, or any future-based state provision
/// in Flutter apps, reducing boilerplate compared to manual [FutureBuilder] + [Pylon] composition.
///
/// Example:
/// ```dart
/// PylonFuture<User>(
///   future: repository.fetchUser(id),
///   builder: (context) => UserWidget(user: context.pylon<User>()),
/// )
/// ```
class PylonFuture<T> extends StatelessWidget {
  /// The [Future<T>] whose result will populate the [Pylon] value upon completion.
  ///
  /// This drives the internal [FutureBuilder], determining loading, error, and data states.
  /// The future's resolved value becomes accessible via `context.pylon<T>()` in the [builder].
  final Future<T> future;

  /// Optional initial value for the [Pylon] before the [future] resolves.
  ///
  /// If set, the [Pylon] is immediately created with this value, and the [builder] can render
  /// using it while awaiting the actual future result. Without this, [loading] is shown initially.
  final T? initialData;

  /// Widget builder function that receives a [Pylon] context with the resolved future value.
  ///
  /// Called once the [future] completes successfully, providing access to the data via
  /// `context.pylon<T>()`. This enables building UI that depends on the async-loaded value.
  final PylonBuilder builder;

  /// Widget displayed during [future] execution if no [initialData] is provided.
  ///
  /// Shown in the pending state of the internal [FutureBuilder]. Defaults to an empty [SizedBox]
  /// to avoid layout shifts, but can be customized (e.g., [CircularProgressIndicator]).
  final Widget loading;

  /// Widget shown if the [future] encounters an exception or error.
  ///
  /// Rendered when the [FutureBuilder] detects an error state. Defaults to a basic error message
  /// text, but typically customized with retry logic or user-friendly error UI.
  final Widget error;

  /// Constructs a [PylonFuture] for async data provision via [Pylon].
  ///
  /// Requires [future] for the async operation and [builder] to render with the resolved value.
  /// Optional [initialData] allows immediate rendering; [loading] and [error] customize states.
  /// All fields are final for immutability, supporting const construction where possible.
  const PylonFuture({
    super.key,
    required this.future,
    required this.builder,
    this.initialData,
    this.loading = const SizedBox.shrink(),
    this.error = const Text("Something went wrong"),
  });

  @override

  /// Builds the widget tree by delegating to a [FutureBuilder] that orchestrates states.
  ///
  /// Handles three cases based on the [future]'s snapshot:
  /// - Error: Returns the [error] widget directly.
  /// - Data available: Wraps the result in a [Pylon<T>] and invokes [builder] for rendering.
  /// - Pending: Returns the [loading] widget (or uses [initialData] if provided).
  ///
  /// This method ensures seamless transition from loading to data provision without manual
  /// state management, leveraging [Pylon]'s context-based value access for descendants.
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
