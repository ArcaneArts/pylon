import 'package:flutter/widgets.dart';
import 'package:pylon/pylon.dart';

/// A [StatelessWidget] that combines multiple [Pylon] widgets into a single, efficient widget.
///
/// [PylonCluster] groups [Pylon] instances to reduce widget tree nesting while preserving
/// full [Pylon] functionality. Benefits include:
///
/// * Shallower widget tree for better readability and performance
/// * Direct access to all pylon values in the [builder] via [BuildContext.pylon<T>()]
/// * Efficient chaining of pylons as direct children
///
/// The structure forms a chain: each [Pylon] wraps the next, with the final [Pylon]
/// containing the [builder]. If no pylons are provided, the [builder] executes directly.
///
/// Example:
/// ```dart
/// PylonCluster(
///   pylons: [
///     Pylon<int>.data(0),
///     Pylon<String>.data("hello"),
///   ],
///   builder: (context) => Text(context.pylon<String>()),
/// )
/// ```
class PylonCluster extends StatelessWidget {
  /// The ordered list of [Pylon] widgets forming the cluster.
  ///
  /// Provide [Pylon<T>.data()] instances without builders, as [PylonCluster]
  /// supplies the shared [builder]. The sequence determines the wrapping order:
  /// earlier pylons wrap later ones, making all values available in the [builder].
  ///
  /// Empty lists result in direct [builder] execution without pylons.
  final List<Pylon> pylons;

  /// Builder function receiving a [BuildContext] with access to all cluster [Pylon] values
  /// via the [BuildContext.pylon<T>()] extension.
  ///
  /// Returns the widget tree child of the innermost [Pylon], or directly from
  /// [PylonCluster] if [pylons] is empty.
  final PylonBuilder builder;

  /// Constructs a [PylonCluster] combining the provided [pylons] under a shared [builder].
  ///
  /// Requires non-empty [pylons] of [Pylon.data] form and a [builder] function.
  /// The [key] supports widget identity for Flutter's reconciliation.
  const PylonCluster({super.key, required this.pylons, required this.builder});

  /// Constructs the chained [Pylon] structure for the widget tree.
  ///
  /// Handles cases efficiently:
  /// * Empty [pylons]: Returns [builder](context) directly.
  /// * Single pylon: Applies [Pylon.copyWithBuilder] to attach [builder].
  /// * Multiple pylons: Chains via [Pylon.copyWithChild] from last to first,
  ///   attaching [builder] to the innermost using [Pylon.copyWithBuilder].
  ///
  /// This ensures minimal widget overhead while exposing all values to [builder]
  /// through [BuildContext].
  @override
  Widget build(BuildContext context) {
    // If no pylons are provided, just call the builder directly
    if (pylons.isEmpty) {
      return builder(context);
    }

    // For a single pylon, just attach our builder to it
    if (pylons.length == 1) {
      return pylons.first.copyWithBuilder(builder);
    }

    // For multiple pylons, start from the last one and work backwards
    // The last pylon gets our builder function
    Widget result = pylons.last.copyWithBuilder(builder);

    // Each previous pylon gets the next pylon (or the chained result) as its child
    for (int i = pylons.length - 2; i >= 0; i--) {
      result = pylons[i].copyWithChild(result);
    }

    return result;
  }
}
