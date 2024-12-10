Map<Type, PylonCodec> pylonCodecs = {};

void registerPylonCodec<T extends PylonCodec>(T codec) =>
    pylonCodecs[T] = codec;

abstract class PylonCodec<T> {
  /// Encoding expects to encode value, NOT this instance!
  String pylonEncode(T value);

  /// Decoding expects a new instance of this class even though it is in an instance of this class
  Future<T> pylonDecode(String value);
}
