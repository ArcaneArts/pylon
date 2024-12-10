import 'package:flutter/material.dart';
import 'package:pylon/pylon.dart';

void main() => runApp(const MainS());

class MainS extends StatelessWidget {
  const MainS({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: CounterApp(),
      );
}

typedef MUT = MutablePylon<int>;

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) => MUT(
        rebuildChildren: true,
        value: 0,
        builder: (context) => Pylon<int>(
            value: context.pylon<int>(),
            broadcast: "counter",
            builder: (context) => Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                            'You have pushed the button this many times:'),
                        Text('${context.pylon<int>()}'),
                        Text(
                            '${Pylon.visibleBroadcastToUri(context, Uri.base)}'),
                        ElevatedButton(
                            onPressed: () => Pylon.push(context, OtherScreen()),
                            child: Text("Test route"))
                      ],
                    ),
                  ),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () => context.modPylon<int>((t) => t + 1),
                    tooltip: 'Increment',
                    child: const Icon(Icons.add),
                  ),
                )),
      );
}

class OtherScreen extends StatelessWidget {
  const OtherScreen({super.key});

  @override
  Widget build(BuildContext context) => PylonPort<int>(
      pull: "counter",
      builder: (context) =>
          Scaffold(body: Text("Value pulled as ${context.pylon<int>()}")));
}
