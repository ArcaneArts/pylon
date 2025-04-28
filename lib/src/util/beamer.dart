import 'package:beamer/beamer.dart';
import 'package:flutter/widgets.dart';
import 'package:pylon/pylon.dart';

class _BeamedPylons {
  final List<Pylon> pylons;

  const _BeamedPylons({required this.pylons});
}

Widget pylonBeamerBuilder(BuildContext context, Widget widget) =>
    Conduit<_BeamedPylons>(
        defaultData: const _BeamedPylons(pylons: []),
        builder: (context, v) => PylonCluster(
            pylons: v?.pylons ?? [], builder: (context) => widget));

extension XContextBeamPylon on BuildContext {
  void pylonBeamToNamed(String name) {
    Conduit.push<_BeamedPylons>(
        _BeamedPylons(pylons: Pylon.visiblePylons(this, ignoreLocals: true)));
    beamToNamed(name);
  }
}
