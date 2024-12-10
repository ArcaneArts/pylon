import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pylon/pylon.dart';

class PylonBroadcaster extends StatefulWidget {
  final PylonBuilder builder;

  const PylonBroadcaster({super.key, required this.builder});

  @override
  State<PylonBroadcaster> createState() => _PylonBroadcasterState();
}

class _PylonBroadcasterState extends State<PylonBroadcaster> {
  @override
  void initState() {
    if (kIsWeb) {
      UriPylonCodecUtils.setUri(
          Pylon.visibleBroadcastToUri(context, UriPylonCodecUtils.getUri()));
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) => Builder(builder: widget.builder);
}
