import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pylon/pylon.dart';

void main() {
  testWidgets('immediate child lookups still resolve the current pylon',
      (tester) async {
    String? valueFromContext;
    String? valueFromWidgetLookup;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Pylon<String>.withChild(
          value: 'root',
          child: Builder(
            builder: (context) {
              valueFromContext = context.pylon<String>();
              valueFromWidgetLookup = Pylon.widgetOfOr<String>(context)?.value;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(valueFromContext, 'root');
    expect(valueFromWidgetLookup, 'root');
  });

  testWidgets('pylon remove preserves nullable lookup behavior',
      (tester) async {
    int? typedValue;
    Pylon<int?>? removedValue;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Pylon<int>(
          value: 42,
          builder: (context) => PylonRemove<int>(
            builder: (context) {
              typedValue = context.pylonOr<int>();
              removedValue = Pylon.widgetOfOr<int?>(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(typedValue, 42);
    expect(removedValue, isNotNull);
    expect(removedValue?.value, isNull);
  });

  testWidgets(
      'visible pylons still collect nearest unique pylons and respect locals',
      (tester) async {
    List<Object?> allVisible = const <Object?>[];
    List<Object?> mirrored = const <Object?>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Pylon<String>(
          value: 'root',
          builder: (context) => Pylon<int>(
            value: 7,
            builder: (context) => Pylon<double>(
              value: 1.5,
              local: true,
              builder: (context) {
                allVisible = Pylon.visiblePylons(context)
                    .map((pylon) => pylon.value)
                    .toList();
                mirrored = Pylon.visiblePylons(context, ignoreLocals: true)
                    .map((pylon) => pylon.value)
                    .toList();
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );

    expect(allVisible, equals(const <Object?>[1.5, 7, 'root']));
    expect(mirrored, equals(const <Object?>[7, 'root']));
  });
}
