import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pylon/pylon.dart';
import 'package:toxic/toxic.dart';

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

  static void registerCodec(PylonCodec codec) => pylonFlatCodecs.add(codec);

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

/// Represents common route types for [Pylon.push]
enum PylonRouteType {
  /// Represents a [MaterialPageRoute]
  material,

  /// Represents a [CupertinoPageRoute]
  cupertino,
}

typedef PylonBuilder = Widget Function(BuildContext context);
