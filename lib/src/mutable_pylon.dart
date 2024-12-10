import 'package:flutter/widgets.dart';
import 'package:pylon/pylon.dart';
import 'package:rxdart/rxdart.dart';

class MutablePylon<T> extends StatefulWidget {
  final T value;
  final PylonBuilder builder;
  final bool rebuildChildren;
  final bool local;

  const MutablePylon(
      {super.key,
      required this.value,
      required this.builder,
      this.local = false,
      this.rebuildChildren = false});

  static MutablePylonState<T>? ofOr<T>(BuildContext context) =>
      context.findAncestorStateOfType<MutablePylonState<T>>();

  static MutablePylonState<T> of<T>(BuildContext context) => ofOr<T>(context)!;

  @override
  State<MutablePylon> createState() => MutablePylonState<T>();
}

class MutablePylonState<T> extends State<MutablePylon> {
  BehaviorSubject<T>? _subject;

  late T _value;

  T get value => _value;

  set value(T value) {
    if (widget.rebuildChildren) {
      try {
        setState(() {
          _value = value;
        });
      } catch (e, es) {
        _value = value;
        debugPrintStack(label: e.toString(), stackTrace: es);
      }
    } else {
      _value = value;
    }
    _subject?.add(value);
  }

  Stream<T> get stream => _subject ??= BehaviorSubject.seeded(_value);

  @override
  void initState() {
    _value = widget.value;
    super.initState();
  }

  @override
  void dispose() {
    _subject?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Pylon<T>(
        value: value,
        builder: widget.builder,
        local: widget.local,
      );
}
