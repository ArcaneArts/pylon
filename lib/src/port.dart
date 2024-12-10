import 'package:flutter/widgets.dart';
import 'package:pylon/pylon.dart';
import 'package:toxic/toxic.dart';

class PylonPort<T> extends StatefulWidget {
  final String pull;
  final PylonBuilder builder;
  final bool local;
  final String? rebroadcast;

  const PylonPort(
      {super.key,
      required this.pull,
      required this.builder,
      this.local = true,
      this.rebroadcast});

  @override
  State<PylonPort<T>> createState() => _PylonPortState<T>();
}

class _PylonPortState<T> extends State<PylonPort<T>> {
  Future<T>? future;

  @override
  Widget build(BuildContext context) {
    T? value = Pylon.visiblePylons(context)
        .whereType<Pylon<T>>()
        .select((i) => i.broadcast != null)
        ?.value;

    if (value == null) {
      if (future == null) {
        Map<String, String> q = UriPylonCodecUtils.getUri().queryParameters;

        if (q.containsKey(widget.pull)) {
          future = context.pylonDecode<T>(q[widget.pull]!);
        } else {
          throw "PylonPort: No port found for ${widget.pull} broadcasting on Uri ${UriPylonCodecUtils.getUri()}. No context value was available either. Avalable: ${q}";
        }
      }

      return FutureBuilder<T>(
          future: future,
          builder: (context, snap) => Pylon<T?>(
                value: snap.data,
                builder: widget.builder,
                local: widget.local,
                broadcast: widget.rebroadcast,
              ));
    }

    return Pylon<T>(
      value: value,
      local: widget.local,
      broadcast: widget.rebroadcast,
      builder: widget.builder,
    );
  }
}
