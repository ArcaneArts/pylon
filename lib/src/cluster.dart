import 'package:flutter/widgets.dart';
import 'package:pylon/pylon.dart';

/// A widget that combines multiple [Pylon] widgets into a single widget.
///
/// [PylonCluster] allows you to group multiple [Pylon] widgets together without deeply
/// nesting them in the widget tree. This provides several benefits:
///
/// 1. Reduces widget tree nesting depth, improving readability and maintainability
/// 2. Maintains all the functionality of individual [Pylon] widgets
/// 3. Ensures all pylons are immediately available to the builder method
/// 4. Improves performance by reducing the number of builder widgets in the tree
///
/// Internally, [PylonCluster] constructs an efficient chain of [Pylon] widgets where
/// each pylon is an immediate child of the previous one, with the last pylon containing
/// your builder method.
///
/// Example usage:
/// ```dart
/// PylonCluster(
///   pylons: [
///     Pylon<int>.data(0),
///     Pylon<String>.data("hello"),
///     Pylon<List<String>>.data(["item1", "item2"]),
///   ],
///   builder: (context) {
///     // All pylon values are accessible here
///     int count = context.pylon<int>();
///     String text = context.pylon<String>();
///     List<String> items = context.pylon<List<String>>();
///     
///     return YourWidget(count: count, text: text, items: items);
///   },
/// )
/// ```
class PylonCluster extends StatelessWidget {
  /// The list of [Pylon] widgets to be combined into this cluster.
  ///
  /// These should be created using [Pylon<T>.data()] constructor without providing a builder,
  /// as the builder will be provided by the [PylonCluster] itself.
  ///
  /// The order of pylons matters:
  /// - Each pylon becomes a child of the previous one in the list
  /// - The last pylon in the list will directly contain the builder function
  /// - All pylons will be accessible to the builder function through [BuildContext]
  ///
  /// If this list is empty, the [builder] will be called directly without any pylons.
  final List<Pylon> pylons;
  
  /// The builder function that constructs the widget tree using values from all pylons.
  ///
  /// This function receives a [BuildContext] that can access all pylon values in the cluster
  /// using the [BuildContext.pylon<T>()] extension method.
  ///
  /// The widget returned by this builder will be the child of the innermost [Pylon] widget
  /// in the cluster, or the direct result of the [PylonCluster] if [pylons] is empty.
  final PylonBuilder builder;

  /// Creates a [PylonCluster] that combines multiple [Pylon] widgets.
  ///
  /// Both [pylons] and [builder] parameters are required.
  ///
  /// The [pylons] parameter should contain [Pylon] widgets created with [Pylon<T>.data()]
  /// without providing their own builders.
  ///
  /// The [builder] function will have access to all pylon values in the context.
  const PylonCluster({super.key, required this.pylons, required this.builder});

  /// Builds the combined pylon structure from the list of pylons.
  ///
  /// This method:
  /// 1. Handles empty or single pylon cases efficiently
  /// 2. For multiple pylons, constructs a chain where each pylon is a direct child of the previous one
  /// 3. Ensures the innermost pylon contains the provided [builder] function
  ///
  /// The resulting widget structure makes all pylon values accessible to the [builder]
  /// through the [BuildContext].
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
