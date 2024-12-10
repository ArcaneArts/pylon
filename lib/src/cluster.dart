import 'package:flutter/widgets.dart';
import 'package:pylon/pylon.dart';

/// A widget that combines multiple [Pylon] widgets into a single widget. This is essentially the same as
/// nesting multiple pylon widgets, but with the advantage of not spamming builder widgets in the widget tree
/// All pylons are built with just an immediate child of the next, with the last pylon provided containing your builder method
/// this ensures all pylons are immediately available to the builder method without spamming builder widgets
class PylonCluster extends StatelessWidget {
  /// Use Pylon<T>.data()
  final List<Pylon> pylons;
  final PylonBuilder builder;

  const PylonCluster({super.key, required this.pylons, required this.builder});

  @override
  Widget build(BuildContext context) {
    if (pylons.isEmpty) {
      return builder(context);
    }

    if (pylons.length == 1) {
      return pylons.first.copyWithBuilder(builder);
    }

    Widget result = pylons.last.copyWithBuilder(builder);

    for (int i = pylons.length - 2; i >= 0; i--) {
      result = pylons[i].copyWithChild(result);
    }

    return result;
  }
}
