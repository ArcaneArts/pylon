import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pylon/pylon.dart';
import 'package:pylon/src/util/address_bar_io.dart'
    if (dart.library.js_interop) 'package:pylon/src/util/address_bar_js.dart'
    if (dart.library.html) 'package:pylon/src/util/address_bar_html.dart';
import 'package:toxic/extensions/future.dart';

/// A widget that synchronizes a pylon value with URL query parameters.
///
/// [PylonPort] enables persistence of a value of type [T] via URL query parameters,
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
  /// The query parameter name used in the URL to store the encoded value.
  ///
  /// This should be unique within your application to avoid conflicts with other
  /// query parameters. It will be used as the key in the URL's query string.
  final String tag;

  /// A function that builds a widget using the provided context.
  ///
  /// The builder can access the loaded value using `context.pylon<T>()` or
  /// `context.pylonOr<T>()` if [nullable] is true.
  final PylonBuilder builder;

  /// The widget to display while the value is being loaded from the URL.
  ///
  /// This widget is shown before the value is loaded from the URL. If [nullable] is true,
  /// this widget is never displayed and instead the builder is called with a null value.
  final Widget loading;

  /// The widget to display if an error occurs during loading or decoding.
  ///
  /// This widget is shown if there is an error loading or decoding the value from the URL.
  /// If [errorsAreNull] is true, this widget is never displayed and instead the builder
  /// is called with a null value.
  final Widget error;

  /// Determines if the value can be null.
  ///
  /// When set to true, the [loading] widget is never shown, and instead the builder
  /// is immediately called with a null value. This is useful when you want to display
  /// content without waiting for the URL value to load.
  final bool nullable;

  /// Determines if errors during loading should be treated as null values.
  ///
  /// When set to true, any errors that occur during loading or decoding the value
  /// from the URL will result in a null value being provided to the builder instead of
  /// showing the [error] widget. This option can only be used if [nullable] is also true.
  final bool errorsAreNull;

  /// Creates a [PylonPort] widget.
  ///
  /// The [tag] parameter is required and specifies the query parameter name in the URL.
  /// The [builder] parameter is required and is used to build the widget with the loaded value.
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
/// This class manages the loading, decoding, and updating of the value in the URL.
class _PylonPortState<T extends PylonCodec> extends State<PylonPort<T>> {
  /// The future that resolves to the loaded value from the URL.
  late Future<T?> value;
  
  /// The codec used to encode and decode the value to and from a string.
  late PylonCodec codec;
  
  /// The initial value if available from the context before loading from URL.
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
      // If a value exists in the widget tree, update the URL and use it
      pushUrl(value);
      initialData = value;
      this.value = Future.value(value);
    } else {
      // Otherwise, attempt to load the value from the URL
      this.value = pullUrl().bang.thenRun((u) => pushUrl(u));
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

  /// A placeholder string used to temporarily replace hash fragments in URLs.
  ///
  /// This is used as an internal helper for URL manipulations to handle hash fragments
  /// properly during encoding and decoding.
  String _frag = "/HHAASSHH_FFRRAAGG/";
  
  /// Returns the current URL with hash fragments replaced by [_frag].
  ///
  /// This is used to properly manipulate URLs with hash fragments.
  String get $hrefNonHash => $hrefPylon.replaceAll("/#/", _frag);

  /// Updates the URL query parameter with the encoded value.
  ///
  /// This method encodes the provided [value] using the registered codec
  /// and updates the URL query parameter specified by [widget.tag] with the
  /// encoded string. This only happens in web environments.
  ///
  /// Parameters:
  /// - [value]: The value to encode and store in the URL.
  void pushUrl(T value) {
    if (kIsWeb) {
      Uri uri = Uri.parse($hrefNonHash);
      $pushHrefPylon(
          null,
          "",
          uri
              .replace(queryParameters: {
                ...uri.queryParameters,
                widget.tag: codec.pylonEncode(value)
              })
              .toString()
              .replaceAll(_frag, "/#/"));
    }
  }

  /// Retrieves and decodes the value from the URL query parameter.
  ///
  /// This method extracts the query parameter specified by [widget.tag]
  /// from the URL, then decodes it using the registered codec to produce
  /// a value of type [T]. This only works in web environments.
  ///
  /// Returns:
  /// - A [Future] that resolves to the decoded value, or null if the value
  ///   is not present in the URL or not in a web environment.
  Future<T?> pullUrl() async {
    if (kIsWeb) {
      Uri uri = Uri.parse($hrefNonHash);
      String? value = uri.queryParameters[widget.tag];
      if (value != null) {
        return codec.pylonDecode(value).then((v) => v as T);
      }
    }
    return null;
  }

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
