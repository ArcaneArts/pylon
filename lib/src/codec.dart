const List<PylonCodec> pylonStandardCodecs = [
  LiteralPylonCodec<String>(),
  LiteralPylonCodec<int>(),
  LiteralPylonCodec<double>(),
  LiteralPylonCodec<bool>(),
];

List<PylonCodec> pylonFlatCodecs = [];

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
