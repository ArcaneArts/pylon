import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pylon/pylon.dart';

/// A widget that nullifies a pylon value of type [T] from the widget tree.
/// 
/// This widget creates a [Pylon] with a null value, effectively removing or overriding
/// any ancestor [Pylon] of the same type [T] for all descendant widgets.
class PylonRemove<T> extends StatelessWidget {
  /// The builder function that creates the child widget with access to the nullified pylon.
  final PylonBuilder builder;
  
  /// If true, the nullification only applies to the current route and won't be transferred
  /// when navigating to new routes.
  final bool local;
  
  /// Creates a [PylonRemove] widget.
  /// 
  /// The [builder] parameter is required and is used to create the child widget.
  /// The [local] parameter defaults to false, meaning the nullification will be transferred
  /// when navigating to new routes.
  const PylonRemove({super.key, required this.builder, this.local = false});

  @override
  Widget build(BuildContext context) => Pylon<T?>(
        value: null,
        builder: builder,
        local: local,
      );
}

/// A widget that provides a value of type [T] to its descendants in the widget tree.
/// 
/// [Pylon] is a state management solution that allows values to be passed down the widget tree
/// and accessed by descendant widgets without the need for explicit passing through constructor parameters.
/// It is designed to be simple, reliable, and intuitive, working similarly to but more reliably than
/// the Provider package.
/// 
/// Key features:
/// - Provides values to descendant widgets
/// - Can be accessed across navigation routes
/// - Supports builders for immediate access to values
/// - Can be combined with other pylons using [PylonCluster]
/// 
/// Descendant widgets can access the value using BuildContext extensions like:
/// - `context.pylon<T>()` - Get the value (throws if not found)
/// - `context.pylonOr<T>()` - Get the value or null if not found
/// - `context.hasPylon<T>()` - Check if a pylon of type T is available
class Pylon<T> extends StatelessWidget {
  /// The value of type [T] that will be provided to descendant widgets.
  final T value;
  
  /// Optional builder function to create a child widget with access to the pylon value.
  /// If provided, [child] must be null.
  final PylonBuilder? builder;
  
  /// Optional child widget. If provided, [builder] must be null.
  final Widget? child;

  /// If true, this pylon won't be transferred across navigation routes.
  /// 
  /// When false (the default), the value will be available in new routes
  /// created using [Pylon.push] and similar navigation methods.
  final bool local;

  /// Creates a [Pylon] widget with a builder function.
  /// 
  /// The [value] parameter is the value to be provided to descendant widgets.
  /// The [builder] parameter is a function that creates a child widget with access to the pylon value.
  /// If [local] is true, the pylon won't be transferred across navigation routes.
  const Pylon({
    super.key,
    required this.value,
    required this.builder,
    this.local = false
  }) : child = null;

  /// Creates a [Pylon] widget with a child widget.
  /// 
  /// Use this constructor when you want to pass a value to a single child widget and don't need a builder function.
  /// Note that if you need to use the value immediately in the child widget, it won't be available until either
  /// a builder function is used or the child widget's build method uses it.
  /// 
  /// The [value] parameter is the value to be provided to descendant widgets.
  /// The [child] parameter is the widget that will have access to the pylon value.
  /// If [local] is true, the pylon won't be transferred across navigation routes.
  const Pylon.withChild({
    super.key, 
    required this.value, 
    required this.child, 
    this.local = false
  }) : builder = null;

  /// Creates a [Pylon] widget with only data, no child or builder.
  /// 
  /// This is primarily used for [PylonCluster]. Using this constructor produces a widget which will
  /// throw an error if built as it doesn't have a child or builder function.
  /// 
  /// The [value] parameter is the value to be provided to descendant widgets.
  /// If [local] is true, the pylon won't be transferred across navigation routes.
  const Pylon.data({
    super.key, 
    required this.value, 
    this.local = false
  }) : builder = null,
       child = null;

  /// Returns the value of the nearest ancestor [Pylon] widget of type [T] or null if not found.
  /// 
  /// This method searches up the widget tree for a [Pylon<T>] widget and returns it.
  /// If no matching [Pylon] is found, returns null.
  /// 
  /// Example:
  /// ```dart
  /// Pylon<String>? stringPylon = Pylon.widgetOfOr<String>(context);
  /// ```
  static Pylon<T>? widgetOfOr<T>(BuildContext context) =>
      context.findAncestorWidgetOfExactType<Pylon<T>>();

  /// Returns the type of value stored in this pylon.
  Type get valueType => T;

  /// Returns the value of the nearest ancestor [Pylon] widget of type [T] or throws an error if not found.
  /// 
  /// This method searches up the widget tree for a [Pylon<T>] widget and returns it.
  /// If no matching [Pylon] is found, it throws an error.
  /// 
  /// Example:
  /// ```dart
  /// Pylon<String> stringPylon = Pylon.widgetOf<String>(context);
  /// ```
  static Pylon<T> widgetOf<T>(BuildContext context) => widgetOfOr(context)!;

  /// Replaces the current route with a new one, transferring pylon values.
  /// 
  /// This method creates a new route that includes all ancestral pylons from the current context,
  /// then performs a [Navigator.pushReplacement] operation.
  /// 
  /// Parameters:
  /// - [context]: The build context from which to get current pylons.
  /// - [child]: The widget to display in the new route.
  /// - [settings]: Optional route settings.
  /// - [type]: The type of route to create (material or cupertino).
  /// - [route]: Optional custom route to use instead of the default.
  /// 
  /// Returns a [Future] that completes with the value returned by the new route.
  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget child, {
    RouteSettings? settings,
    PylonRouteType type = PylonRouteType.material,
    Route<T>? route,
  }) =>
      Navigator.pushReplacement<T?, TO?>(
          context,
          route ??
              switch (type) {
                PylonRouteType.material => Pylon.materialPageRoute(
                    context, (context) => child,
                    settings: settings),
                PylonRouteType.cupertino => Pylon.cupertinoPageRoute(
                    context, (context) => child,
                    settings: settings),
              });

  /// Pushes a new route and removes routes until [predicate] returns true, transferring pylon values.
  /// 
  /// This method creates a new route that includes all ancestral pylons from the current context,
  /// then performs a [Navigator.pushAndRemoveUntil] operation.
  /// 
  /// Parameters:
  /// - [context]: The build context from which to get current pylons.
  /// - [child]: The widget to display in the new route.
  /// - [settings]: Optional route settings.
  /// - [type]: The type of route to create (material or cupertino).
  /// - [route]: Optional custom route to use instead of the default.
  /// - [predicate]: A function that determines whether a route should remain on the stack.
  /// 
  /// Returns a [Future] that completes with the value returned by the new route.
  static Future<T?> pushAndRemoveUntil<T extends Object?>(
    BuildContext context,
    Widget child, {
    RouteSettings? settings,
    PylonRouteType type = PylonRouteType.material,
    Route<T>? route,
    required RoutePredicate predicate,
  }) =>
      Navigator.pushAndRemoveUntil<T?>(
          context,
          route ??
              switch (type) {
                PylonRouteType.material => Pylon.materialPageRoute(
                    context, (context) => child,
                    settings: settings),
                PylonRouteType.cupertino => Pylon.cupertinoPageRoute(
                    context, (context) => child,
                    settings: settings),
              },
          predicate);

  /// Pushes a new route to the navigator with all visible [Pylon] widgets from the current context.
  /// 
  /// This method creates a new route that includes all non-local ancestral pylons from the current context,
  /// making those pylon values available in the new route.
  /// 
  /// Parameters:
  /// - [context]: The build context from which to get current pylons.
  /// - [child]: The widget to display in the new route.
  /// - [settings]: Optional route settings.
  /// - [type]: The type of route to create (material or cupertino).
  /// - [route]: Optional custom route to use instead of the default.
  /// 
  /// Returns a [Future] that completes with the value returned by the new route.
  /// 
  /// Example:
  /// ```dart
  /// Pylon.push(context, DetailScreen());
  /// ```
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget child, {
    RouteSettings? settings,
    PylonRouteType type = PylonRouteType.material,
    Route<T>? route,
  }) =>
      Navigator.push<T?>(
          context,
          route ??
              switch (type) {
                PylonRouteType.material => Pylon.materialPageRoute(
                    context, (context) => child,
                    settings: settings),
                PylonRouteType.cupertino => Pylon.cupertinoPageRoute(
                    context, (context) => child,
                    settings: settings),
              });

  /// Creates a [MaterialPageRoute] with all pylon values from the current context transferred to the new route.
  /// 
  /// Parameters:
  /// - [context]: The build context from which to get current pylons.
  /// - [builder]: A function that builds the route's primary contents.
  /// - [settings]: Optional route settings.
  /// 
  /// Returns a [MaterialPageRoute] that includes all non-local pylons from the current context.
  static MaterialPageRoute<T> materialPageRoute<T extends Object?>(
          BuildContext context, Widget Function(BuildContext) builder,
          {RouteSettings? settings}) =>
      MaterialPageRoute<T>(
          settings: settings, builder: mirror(context, builder));

  /// Creates a [CupertinoPageRoute] with all pylon values from the current context transferred to the new route.
  /// 
  /// Parameters:
  /// - [context]: The build context from which to get current pylons.
  /// - [builder]: A function that builds the route's primary contents.
  /// - [settings]: Optional route settings.
  /// 
  /// Returns a [CupertinoPageRoute] that includes all non-local pylons from the current context.
  static CupertinoPageRoute<T> cupertinoPageRoute<T extends Object?>(
          BuildContext context, Widget Function(BuildContext) builder,
          {RouteSettings? settings}) =>
      CupertinoPageRoute<T>(
          settings: settings, builder: mirror(context, builder));

  /// Returns a list of all visible [Pylon] widgets in the widget tree, starting from [context].
  /// 
  /// This method traverses up the widget tree and collects all ancestors that are [Pylon] widgets.
  /// If [ignoreLocals] is true, pylons with [local] set to true will be excluded.
  /// 
  /// Parameters:
  /// - [context]: The starting build context.
  /// - [ignoreLocals]: Whether to ignore pylons with [local] set to true.
  /// 
  /// Returns a list of [Pylon] widgets.
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

  /// Creates a builder function that incorporates all visible pylon values from the current context.
  /// 
  /// This function is used internally by navigation methods to transfer pylon values to new routes.
  /// It creates a [PylonCluster] that contains all non-local pylon values from the original context.
  /// 
  /// Parameters:
  /// - [context]: The build context from which to get current pylons.
  /// - [builder]: The builder function to wrap with pylons.
  /// 
  /// Returns a new builder function that includes all pylons from the original context.
  static Widget Function(BuildContext) mirror(
      BuildContext context, Widget Function(BuildContext) builder) {
    List<Pylon> providers = visiblePylons(context, ignoreLocals: true);

    return (context) => PylonCluster(
          pylons: providers.reversed.toList(),
          builder: builder,
        );
  }

  @override
  Widget build(BuildContext context) => child ?? Builder(builder: builder!);

  /// Returns a copy of this widget with the child widget set to [child].
  /// 
  /// This method creates a new [Pylon] with the same value as this one but
  /// with the child widget set to the provided [child].
  /// 
  /// Parameters:
  /// - [child]: The new child widget.
  /// 
  /// Returns a new [Pylon] widget.
  Pylon<T> copyWithChild(Widget child) =>
      Pylon.withChild(value: value, child: child, local: local);

  /// Returns a copy of this widget with the builder function set to [builder].
  /// 
  /// This method creates a new [Pylon] with the same value as this one but
  /// with the builder function set to the provided [builder].
  /// 
  /// Parameters:
  /// - [builder]: The new builder function.
  /// 
  /// Returns a new [Pylon] widget.
  Pylon<T> copyWithBuilder(PylonBuilder builder) =>
      Pylon(value: value, builder: builder, local: local);
}

/// Represents common route types for navigation methods in [Pylon].
/// 
/// This enum is used to specify the type of route to create when navigating
/// between screens while maintaining pylon values.
enum PylonRouteType {
  /// Represents a [MaterialPageRoute], used for Material Design navigation transitions.
  material,

  /// Represents a [CupertinoPageRoute], used for iOS-style navigation transitions.
  cupertino,
}

/// A typedef for a function that builds a widget given a [BuildContext].
/// 
/// This is used throughout the Pylon package for builder functions that create widgets
/// with access to pylon values from the provided context.
typedef PylonBuilder = Widget Function(BuildContext context);
