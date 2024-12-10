library pylon;

import 'dart:html' as html;
import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:toxic/extensions/future.dart';
import 'package:toxic/extensions/iterable.dart';

typedef PylonBuilder = Widget Function(BuildContext context);
const List<PylonCodec> pylonStandardCodecs = [
  LiteralPylonCodec<String>(),
  LiteralPylonCodec<int>(),
  LiteralPylonCodec<double>(),
  LiteralPylonCodec<bool>(),
];

List<PylonCodec> _flatCodecs = [];

/// Represents common route types for [Pylon.push]
enum PylonRouteType {
  /// Represents a [MaterialPageRoute]
  material,

  /// Represents a [CupertinoPageRoute]
  cupertino,
}

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

/// Combines a [StreamBuilder] with a [Pylon] widget. When the stream emits a value,
/// the value is passed to the [Pylon] widget with the builder function provided
class PylonStream<T> extends StatelessWidget {
  final Stream<T> stream;
  final T? initialData;
  final PylonBuilder builder;
  final Widget loading;

  const PylonStream(
      {super.key,
      required this.stream,
      this.initialData,
      required this.builder,
      this.loading = const SizedBox.shrink()});

  @override
  Widget build(BuildContext context) => StreamBuilder<T>(
      stream: stream,
      initialData: initialData,
      builder: (context, snap) => snap.hasData
          ? Pylon<T>(
              value: snap.data as T,
              builder: builder,
            )
          : loading);
}

/// A widget that provides a value to its descendants. This is useful for passing values
/// to widgets that are not directly related to each other
class Pylon<T> extends StatelessWidget {
  final T value;
  final PylonBuilder? builder;
  final Widget? child;
  final String? broadcast;

  /// If local is set to true it wont persist across navigation routes
  final bool local;

  const Pylon(
      {super.key,
      required this.value,
      required this.builder,
      this.broadcast,
      this.local = false})
      : child = null;

  /// Use this constructor when you want to pass a value to a single child widget and dont need a builder function.
  /// You can use a child instead of a builder however if you need to use the value immediately in the child widget
  /// then it wont be available until either a builder function is used or the child widget build method uses it
  /// Use the regular constructor for lazy inlining
  const Pylon.withChild(
      {super.key,
      required this.value,
      required this.child,
      this.broadcast,
      this.local = false})
      : builder = null;

  dynamic encodeRaw(BuildContext context) =>
      context.pylonCodec<T>().pylonToValue(value);

  /// This is primarily used for [PylonCluster]. Using this constructor produces a widget which will
  /// throw an error if built as it doesnt have a child or builder function
  const Pylon.data(
      {super.key, required this.value, this.local = false, this.broadcast})
      : builder = null,
        child = null;

  /// Returns the value of the nearest ancestor [Pylon] widget of type T or null
  static Pylon<T>? widgetOfOr<T>(BuildContext context) =>
      context.findAncestorWidgetOfExactType<Pylon<T>>();

  Type get valueType => T;

  /// Returns the value of the nearest ancestor [Pylon] widget of type T or throws an error
  static Pylon<T> widgetOf<T>(BuildContext context) => widgetOfOr(context)!;

  /// Pushes all visible [Pylon] widgets into your builder function's parent widget. This is used for navigation
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget child, {
    PylonRouteType type = PylonRouteType.material,
    Route<T>? route,
  }) {
    UriPylonCodecUtils.updateUri(context);

    return Navigator.push<T?>(
            context,
            route ??
                switch (type) {
                  PylonRouteType.material =>
                    Pylon.materialPageRoute(context, (context) => child),
                  PylonRouteType.cupertino =>
                    Pylon.cupertinoPageRoute(context, (context) => child),
                })
        .thenRun((_) => UriPylonCodecUtils.updateUri(context));
  }

  /// Creates a [MaterialPageRoute] with the [Pylon] widgets mirrored into the builder function to transfer the values
  static MaterialPageRoute<T> materialPageRoute<T extends Object?>(
          BuildContext context, Widget Function(BuildContext) builder) =>
      MaterialPageRoute<T>(builder: mirror(context, builder));

  /// Creates a [CupertinoPageRoute] with the [Pylon] widgets mirrored into the builder function to transfer the values
  static CupertinoPageRoute<T> cupertinoPageRoute<T extends Object?>(
          BuildContext context, Widget Function(BuildContext) builder) =>
      CupertinoPageRoute<T>(builder: mirror(context, builder));

  static Iterable<Pylon> visibleBroadcastingPylons(BuildContext context,
          {bool ignoreLocals = false}) =>
      visiblePylons(context, ignoreLocals: ignoreLocals)
          .where((i) => i.broadcast != null);

  static Uri visibleBroadcastToUri(BuildContext context, Uri uri,
          {bool ignoreLocals = false}) =>
      uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...visibleBroadcastMap(context, ignoreLocals: ignoreLocals)
      });

  static Map<String, String> visibleBroadcastMap(BuildContext context,
          {bool ignoreLocals = false}) =>
      Map.fromEntries(
          visibleBroadcastingPylons(context, ignoreLocals: ignoreLocals).map(
              (p) => MapEntry(p.broadcast!,
                  UriPylonCodecUtils.toUrlValue(p.encodeRaw(context)))));

  static List<Pylon> visiblePylons(BuildContext context,
      {bool ignoreLocals = false}) {
    List<Pylon> providers = [];

    context.visitAncestorElements((element) {
      if (element.widget is Pylon) {
        Pylon p = element.widget as Pylon;

        if (ignoreLocals && p.local) {
          return true;
        }

        if (!providers.any((i) => i.runtimeType == p.runtimeType)) {
          providers.add(p);
        }
      }

      return true;
    });

    return providers;
  }

  static void registerCodec(PylonCodec codec) {
    _flatCodecs.add(codec);
  }

  /// Creates a builder function which produces a PylonCluster of all visible ancestor pylons
  /// from [context] and uses the provided [builder] function. Use this when building custom routes
  static Widget Function(BuildContext) mirror(
      BuildContext context, Widget Function(BuildContext) builder) {
    List<Pylon> providers = visiblePylons(context, ignoreLocals: true);

    return (context) => PylonBroadcaster(
        builder: (context) => PylonCluster(
              pylons: providers.reversed.toList(),
              builder: builder,
            ));
  }

  @override
  Widget build(BuildContext context) => child ?? Builder(builder: builder!);

  /// Returns a copy of this widget with the child widget set to [child]
  Pylon<T> copyWithChild(Widget child) =>
      Pylon.withChild(value: value, child: child);

  /// Returns a copy of this widget with the builder function set to [builder]
  Pylon<T> copyWithBuilder(PylonBuilder builder) =>
      Pylon(value: value, builder: builder);
}

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

extension XPylonStream<T> on Stream<T> {
  Widget asPylon(PylonBuilder builder,
          {Key? key,
          T? initialData,
          Widget loading = const SizedBox.shrink()}) =>
      PylonStream<T>(
        key: key,
        stream: this,
        initialData: initialData,
        builder: builder,
        loading: loading,
      );
}

extension XPylonIterable<T> on Iterable<T> {
  List<Widget> withPylons(PylonBuilder builder) =>
      map((e) => Pylon<T>(value: e, builder: builder)).toList();
}

extension XContextPylon on BuildContext {
  /// Returns true if a pylon is available for the given type
  bool hasPylon<T>({Type? runtime}) => pylonOr<T>(runtime: runtime) != null;

  /// Returns the value of the nearest ancestor [Pylon] widget of type T or null
  T? pylonOr<T>({Type? runtime}) => runtime != null
      ? Pylon.visiblePylons(this)
          .select((i) => i.value.runtimeType == runtime)
          ?.value
      : Pylon.widgetOfOr<T>(this)?.value ?? Pylon.widgetOfOr<T?>(this)?.value;

  /// Returns the value of the nearest ancestor [Pylon] widget of type T or throws an error
  T pylon<T>({Type? runtime}) => pylonOr<T>(runtime: runtime)!;

  /// Sets the value of the nearest ancestor [MutablePylon] widget of type T
  /// This will throw an error if the pylon is not mutable or if there is
  /// no [MutablePylon] of type T
  void setPylon<T>(T value) => MutablePylon.of<T>(this).value = value;

  /// Modifies the value of the nearest ancestor [MutablePylon] widget of type T
  void modPylon<T>(T Function(T) modifier) {
    MutablePylonState<T> v = MutablePylon.of<T>(this);
    v.value = modifier(v.value);
  }

  /// Returns the stream of the nearest ancestor [MutablePylon] widget of type T
  Stream<T> streamPylon<T>() => MutablePylon.of<T>(this).stream;

  /// Watch (stream) a pylon value of a [MutablePylon] widget of type T
  /// This does not provide a build context, this is just for small widgets
  Widget watchPylon<T>(Widget Function(T data) builder) => StreamBuilder<T>(
        stream: streamPylon<T>(),
        initialData: pylonOr<T>(),
        builder: (context, snap) =>
            snap.hasData ? builder(snap.data as T) : const SizedBox.shrink(),
      );
}

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

// Represents a codec for pylon value types
abstract class PylonCodec<T> {
  const PylonCodec();

  dynamic pylonToValue(T t);

  Future<T> pylonFromValue(dynamic d);
}

class LiteralPylonCodec<T> extends PylonCodec<T> {
  const LiteralPylonCodec();

  @override
  Future<T> pylonFromValue(d) async => d as T;

  @override
  dynamic pylonToValue(T t) => t;
}

extension XContextPylonCodec on BuildContext {
  PylonCodec<T>? _standardPylonCodec<T>() =>
      pylonStandardCodecs.whereType<PylonCodec<T>>().firstOrNull;

  PylonCodec<T>? _flatPylonCodec<T>() =>
      _flatCodecs.whereType<PylonCodec<T>>().firstOrNull;

  PylonCodec<T> pylonCodec<T>() =>
      _standardPylonCodec<T>() ??
      _flatPylonCodec<T>() ??
      pylon<PylonCodec<T>>();

  PylonCodec<T>? pylonCodecOr<T>() =>
      _standardPylonCodec<T>() ??
      _flatPylonCodec<T>() ??
      pylonOr<PylonCodec<T>>();

  bool hasPylonCodec<T>() => pylonCodecOr<T>() != null;

  String pylonEncode<T>(T value) =>
      UriPylonCodecUtils.toUrlValue(pylonCodec<T>().pylonToValue(value));

  Future<T> pylonDecode<T>(String value) =>
      pylonCodec<T>().pylonFromValue(UriPylonCodecUtils.fromUrlValue(value));
}

class UriPylonCodecUtils {
  static void setUri(Uri uri) {
    if (kIsWeb) {
      html.window.history.pushState(null, "", uri.toString());
    }
  }

  static Uri getUri() {
    if (kIsWeb) {
      return Uri.parse(html.window.location.href);
    }
    return Uri.base;
  }

  static String toUrlValue(dynamic value) {
    String out = "xENCODE_ERROR";

    if (value is String) {
      out = "s$value";
    } else if (value is int) {
      out = "i$value";
    } else if (value is double) {
      out = "d$value";
    } else if (value is bool) {
      out = "b${value ? "y" : "n"}";
    } else if (value is DateTime) {
      out = "t${value.toIso8601String()}";
    } else {
      out = "j${jsonEncode(value)}";
    }

    out = "*$out";

    return out;
  }

  static dynamic fromUrlValue(String value) {
    assert(value.startsWith("*"));
    String t = value.substring(1, 2);
    String v = value.substring(2);

    if (t == "s") {
      return v;
    } else if (t == "i") {
      return int.parse(v);
    } else if (t == "d") {
      return double.parse(v);
    } else if (t == "b") {
      return v == "1";
    } else if (t == "t") {
      return DateTime.parse(v);
    } else if (t == "j") {
      return jsonDecode(v);
    } else {
      throw "Unknown type: $t";
    }
  }

  static String doubleToBase36String(double value, {int decimalPlaces = 6}) {
    final integerPart = value.floor();
    final fraction = value - integerPart;
    final fractionAsInt = (fraction * pow(10, decimalPlaces)).round();
    final encodedInt = integerPart.toRadixString(36);
    final encodedFrac = fractionAsInt.toRadixString(36);

    return '$encodedInt.$encodedFrac';
  }

  static double base36StringToDouble(String base36String,
      {int decimalPlaces = 6}) {
    final parts = base36String.split('.');
    if (parts.length != 2) {
      throw const FormatException('Expected format "int.frac" in base36');
    }

    final intPart = int.parse(parts[0], radix: 36);
    final fracPart = int.parse(parts[1], radix: 36);
    final fracString = fracPart.toString().padLeft(decimalPlaces, '0');
    final doubleString = '$intPart.$fracString';

    return double.parse(doubleString);
  }

  static void updateUri(BuildContext context) {
    if (kIsWeb) {
      Future.delayed(
          const Duration(milliseconds: 1000),
          () => UriPylonCodecUtils.setUri(Pylon.visibleBroadcastToUri(
              context, UriPylonCodecUtils.getUri())));
    }
  }
}

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
