import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pylon/pylon.dart';

/// A widget that synchronizes a pylon value with URL query parameters.
///
/// [PylonPort] enables persistence of a [Pylon] value of type [T] via URL query parameters,
/// which is particularly useful for web applications to maintain state across page refreshes
/// or for sharing application state via URLs.
///
/// The value is encoded and decoded using the registered [PylonCodec] for type [T].
/// You must register a codec for the type [T] before using this widget.
///
/// Example:
/// ```dart
/// // Register a codec for your custom type
/// void main() {
///   registerPylonCodec<MyData>(const MyDataCodec());
///   runApp(MyApp());
/// }
///
/// // Use PylonPort to persist a value in the URL
/// PylonPort<MyData>(
///   tag: 'myData',
///   builder: (context) => MyWidget(),
/// )
/// ```
class PylonPort<T extends PylonCodec> extends StatefulWidget {
  /// The query parameter name used in the URL to store the encoded [Pylon] value.
  ///
  /// This should be unique within your application to avoid conflicts with other
  /// query parameters. It will be used as the key in the URL's query string.
  final String tag;

  /// A function that builds a widget using the provided context and the loaded [Pylon] value.
  ///
  /// The builder can access the loaded value using `context.pylon<T>()` or
  /// `context.pylonOr<T>()` if [nullable] is true.
  final PylonBuilder builder;

  /// The widget to display while the [Pylon] value is being loaded from the URL.
  ///
  /// This widget is shown before the value is loaded from the URL. If [nullable] is true,
  /// this widget is never displayed and instead the builder is called with a null value.
  final Widget loading;

  /// The widget to display if an error occurs during loading or decoding the [Pylon] value.
  ///
  /// This widget is shown if there is an error loading or decoding the value from the URL.
  /// If [errorsAreNull] is true, this widget is never displayed and instead the builder
  /// is called with a null value.
  final Widget error;

  /// Determines if the [Pylon] value can be null.
  ///
  /// When set to true, the [loading] widget is never shown, and instead the builder
  /// is immediately called with a null value. This is useful when you want to display
  /// content without waiting for the URL value to load.
  final bool nullable;

  /// Determines if errors during loading the [Pylon] value should be treated as null values.
  ///
  /// When set to true, any errors that occur during loading or decoding the value
  /// from the URL will result in a null value being provided to the builder instead of
  /// showing the [error] widget. This option can only be used if [nullable] is also true.
  final bool errorsAreNull;

  /// Creates a [PylonPort] widget for synchronizing a [Pylon] value with URL query parameters.
  ///
  /// The [tag] parameter specifies the query parameter name in the URL.
  /// The [builder] parameter is used to build the widget with the loaded [Pylon] value.
  /// The [nullable] parameter defaults to false. When true, null values are allowed and the
  /// loading widget is never shown.
  /// The [errorsAreNull] parameter defaults to false. When true, errors are treated as null
  /// values, and can only be true if [nullable] is also true.
  /// The [loading] parameter defaults to an empty widget and is shown while loading.
  /// The [error] parameter defaults to a simple error message and is shown on error.
  const PylonPort(
      {super.key,
      required this.tag,
      required this.builder,
      this.nullable = false,
      this.errorsAreNull = false,
      this.loading = const SizedBox.shrink(),
      this.error = const Text("Something went wrong")})
      : assert((errorsAreNull && nullable) || !errorsAreNull,
            'errorsAreNull can only be true if nullable is true');

  @override
  State<PylonPort> createState() => _PylonPortState<T>();
}

/// The state for the [PylonPort] widget.
///
/// This class manages the loading, decoding, and updating of the [Pylon] value in the URL,
/// integrating with [PylonFuture] for asynchronous value handling.
class _PylonPortState<T extends PylonCodec> extends State<PylonPort<T>> {
  /// The future that resolves to the loaded [Pylon] value from the URL.
  late Future<T?> value;

  /// The codec used to encode and decode the [Pylon] value to and from a string.
  late PylonCodec codec;

  /// The initial [Pylon] value if available from the context before loading from URL.
  T? initialData;

  @override
  void initState() {
    // Verify that a codec is registered for type T
    assert(pylonCodecs[T] != null,
        'No codec registered for type $T. Use registerPylonCodec<$T>(const $T()); somewhere in your main before app launch!');
    codec = pylonCodecs[T] as PylonCodec;

    // Check if a value is already available in the widget tree
    T? value = context.pylonOr<T>();

    if (value != null) {
      initialData = value;
      this.value = Future.value(value);
    }

    // Handle errors during loading
    this.value = this.value.catchError((e, ex) {
      if (kDebugMode) {
        print("PylonPort Error $e, $ex");
      }
    });

    // If errorsAreNull is true, convert any errors to null values
    if (widget.errorsAreNull) {
      this.value = this.value.catchError((e) => null);
    }

    super.initState();
  }

  /// Builds the widget using [PylonFuture] to handle the asynchronous [Pylon] value.
  ///
  /// This method wraps the [widget.builder] in a [PylonFuture] to manage loading,
  /// error states, and initial data for the [Pylon] value synchronized with the URL.
  @override
  Widget build(BuildContext context) => PylonFuture<T?>(
      future: value,
      builder: widget.builder,
      error: widget.error,
      loading: widget.nullable
          ? Pylon<T?>(value: null, builder: widget.builder)
          : widget.loading,
      initialData: initialData);
}
