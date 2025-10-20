# Pylon

A simple, reliable state management solution for Flutter that works the way you expect it to.

[![pub package](https://img.shields.io/pub/v/pylon.svg)](https://pub.dev/packages/pylon)

## Overview

Pylon is a lightweight state management package designed for Flutter applications, emphasizing simplicity, reliability, and intuitive usage. It draws inspiration from packages like [provider](https://pub.dev/packages/provider) but prioritizes consistent behavior and minimal boilerplate, avoiding the complexities and edge cases that can arise in more feature-heavy solutions. Pylon enables seamless value propagation down the widget tree, making state accessible to descendants without explicit parameter passing.

### Why Pylon?

- **Reliability First**: Pylon is engineered to work predictably in all scenarios, including navigation, async operations, and widget rebuilds. It avoids race conditions and ensures values are always accessible where expected.
- **Simplicity**: No need for complex setup, selectors, or listeners. Just wrap your widgets and access values via context extensions.
- **Performance**: Minimal overhead with efficient widget tree integration. It supports immutable data patterns and optional rebuild controls.
- **Flexibility**: Handles synchronous values, mutable state, streams, futures, global state, and even URL synchronization for web apps.
- **Flutter-Native**: Integrates deeply with Flutter's widget system, BuildContext, and navigation APIs.

Pylon is ideal for apps ranging from simple prototypes to complex, multi-screen applications. It's particularly useful when you want state management that "just works" without deep dives into documentation for edge cases.

### Key Features

- **Value Propagation**: Provide typed values to descendants via `Pylon<T>`.
- **Mutable State**: Update values dynamically with `MutablePylon<T>` and reactive streams.
- **Async Integration**: Handle streams (`PylonStream<T>`) and futures (`PylonFuture<T>`) with built-in loading and error states.
- **Global State**: Application-wide reactive state using `Conduit<T>` with BehaviorSubjects.
- **Efficient Grouping**: Combine multiple pylons with `PylonCluster` to flatten widget trees.
- **URL Persistence**: Synchronize state with browser URLs using `PylonPort<T>` (web-focused).
- **Navigation Helpers**: Preserve state across routes with `Pylon.push`, `Pylon.pushReplacement`, etc.
- **Nullification**: Remove or override pylons with `PylonRemove<T>`.
- **Context Extensions**: Easy access and mutation via `context.pylon<T>()`, `context.modPylon<T>()`, and more.
- **Stream/Iterable Helpers**: Extensions like `stream.asPylon()` and `iterable.withPylons()` for concise code.
- **Type Safety**: Full null safety support, explicit typing, and codec-based serialization for ports.

Pylon supports Dart 3+ and Flutter 3.0+, with no external dependencies beyond core Flutter and RxDart (for streams).

## Table of Contents

- [Installation](#installation)
- [Core Components](#core-components)
  - [Pylon](#pylon)
  - [MutablePylon](#mutablepylon)
  - [PylonCluster](#pyloncluster)
  - [PylonStream](#pylonstream)
  - [PylonFuture](#pylonfuture)
  - [PylonPort](#pylonport)
  - [Conduit](#conduit)
  - [PylonRemove](#pylonremove)
- [Navigation and Routing](#navigation-and-routing)
- [Extensions](#extensions)
- [Advanced Patterns](#advanced-patterns)
- [Best Practices](#best-practices)
- [Examples](#examples)
- [Limitations and Troubleshooting](#limitations-and-troubleshooting)
- [Contributing](#contributing)

## Installation

Add Pylon to your `pubspec.yaml`:

```yaml
dependencies:
  pylon: ^1.0.0  # Use the latest version from pub.dev
```

Run `flutter pub get` to install.

For web URL persistence with `PylonPort`, ensure your app is configured for web (Flutter web support enabled).

Import in your Dart files:

```dart
import 'package:pylon/pylon.dart';
```

No additional setup is required for basic usage. For `PylonPort`, register codecs in `main()` (see [PylonPort](#pylonport) section).

## Core Components

### Pylon

`Pylon<T>` is the foundational widget. It provides an immutable value of type `T` to all descendant widgets in the tree, accessible via context extensions. This is perfect for configuration data, themes, or read-only state like user profiles.

#### Basic Usage

Wrap your app or subtree with `Pylon`:

```dart
Pylon<String>(
  value: 'Hello, Pylon!',
  builder: (context) => Text(context.pylon<String>()),  // Access via extension
)
```

The `builder` receives a `BuildContext` where `context.pylon<T>()` resolves to the provided value. This works even in immediate children, unlike some providers that require deeper nesting.

#### Constructors

- **Standard (with Builder)**: `Pylon({required T value, required PylonBuilder builder, bool local = false})`
  - Use for immediate value access in the builder.
  - `PylonBuilder` is `Widget Function(BuildContext)`.

- **With Child**: `Pylon.withChild({required T value, required Widget child, bool local = false})`
  - For wrapping existing widgets without a builder. Values are available to the child's descendants.

- **Data-Only**: `Pylon.data({required T value, bool local = false})`
  - No builder or child; used internally by `PylonCluster`. Building this directly throws an error.

The `local` flag (default `false`) prevents value transfer across navigation routes, scoping it to the current route.

#### Accessing Values

Use these context extensions for safe, type-checked access:

```dart
// Required: Throws if no Pylon<T> found
T value = context.pylon<T>();

// Optional: Returns null if not found
T? optional = context.pylonOr<T>();

// Check existence (optionally by runtime type)
bool exists = context.hasPylon<T>(runtime: String);  // Filters by exact type

// For specific runtime types (e.g., to disambiguate generics)
T? runtimeValue = context.pylonOr<T>(runtime: MyClass);
```

These traverse the ancestor chain efficiently, stopping at the nearest matching `Pylon<T>`.

#### Use Cases

- **App Configuration**: Provide theme data, locale, or API endpoints at the root.
- **Shared Data**: Pass lists or models (e.g., user permissions) without prop drilling.
- **Performance Tip**: Use immutable values and `const` constructors for optimal rebuild avoidance.

### MutablePylon

`MutablePylon<T>` builds on `Pylon<T>` for state that needs updates, like counters, form data, or toggles. It maintains an internal value that can be modified post-build, with optional automatic rebuilds.

#### Basic Usage

```dart
MutablePylon<int>(
  value: 0,  // Initial value
  rebuildChildren: true,  // Optional: Rebuild on changes (default false)
  builder: (context) => Column(
    children: [
      Text('Count: ${context.pylon<int>()}'),
      ElevatedButton(
        onPressed: () => context.modPylon<int>((v) => v + 1),  // Modify via extension
        child: const Text('Increment'),
      ),
    ],
  ),
)
```

With `rebuildChildren: true`, value changes trigger `setState`, rebuilding the subtree. Set to `false` for manual control via streams (see below).

#### Modifying Values

- **Direct Set**: `context.setPylon<T>(newValue);` or `MutablePylon.of<T>(context).value = newValue;`
  - Throws if no `MutablePylon<T>` ancestor.

- **Modify Function**: `context.modPylon<T>((current) => current + 1);`
  - Applies a transformation to the current value.

- **Optional Access**: `MutablePylon.ofOr<T>(context)?.value = newValue;` (returns null if not found).

#### Reactive Streaming

For fine-grained rebuilds without full subtree updates:

```dart
// Get the value stream (BehaviorSubject-based)
Stream<T> changes = context.streamPylon<T>();

// Watch and rebuild specific widgets
context.watchPylon<T>(
  (value) => Text('Reactive: $value'),  // Rebuilds only this widget on changes
);
```

The stream emits the initial value and all updates, making it ideal for `StreamBuilder` or reactive UIs.

#### Use Cases

- **UI State**: Counters, toggles, or selection states.
- **Form Handling**: Track input validity or partial submissions.
- **Optimization**: Use `rebuildChildren: false` + `watchPylon` for targeted rebuilds in large trees.
- **Local vs Global**: Set `local: true` to avoid persisting mutable state across routes (e.g., temporary filters).

### PylonCluster

`PylonCluster` groups multiple `Pylon` or `MutablePylon` instances into a single widget, reducing tree depth and enabling access to all values in one builder. It's efficient for composing state from multiple sources.

#### Basic Usage

```dart
PylonCluster(
  pylons: [
    Pylon<int>.data(42),
    Pylon<String>.data('Hello'),
    MutablePylon<bool>.data(false),  // Can mix types
  ],
  builder: (context) {
    final int num = context.pylon<int>();
    final String msg = context.pylon<String>();
    final bool flag = context.pylon<bool>();
    return Text('$msg $num (Flag: $flag)');
  },
)
```

Pylons wrap each other in order: first in `pylons` wraps the last. All values are accessible in the `builder`. Empty `pylons` runs the builder directly.

#### Benefits and Use Cases

- **Flatter Trees**: Avoids deep nesting (e.g., `Pylon(A(Pylon(B(child))))` becomes one cluster).
- **Dynamic Composition**: Build clusters from lists: `items.withPylons(builder)` (via extension).
- **Performance**: Minimal overhead; only rebuilds when inner pylons change.
- **Scenarios**: Multi-provider setups like user data + theme + locale in one widget.

### PylonStream

`PylonStream<T>` integrates `StreamBuilder` with `Pylon<T>`, providing the latest stream emission as a pylon value. Ideal for real-time data like WebSockets, timers, or database listeners.

#### Basic Usage

```dart
final Stream<int> timerStream = Stream.periodic(const Duration(seconds: 1), (i) => i);

PylonStream<int>(
  stream: timerStream,
  initialData: 0,  // Shown immediately
  builder: (context) => Text('Time: ${context.pylon<int>()}'),
  loading: const CircularProgressIndicator(),  // Before first emission (if no initialData)
)
```

Once data emits, the `Pylon` updates, triggering rebuilds in dependents.

#### Extension Method

For inline usage:

```dart
timerStream.asPylon(
  (context) => Text('Inline: ${context.pylon<int>()}'),
  initialData: 0,
  loading: const SizedBox.shrink(),
)
```

#### Use Cases

- **Real-Time Updates**: Chat messages, stock tickers, or live notifications.
- **Event-Driven UI**: Respond to user actions or sensor data.
- **Error Handling**: Streams with errors will rebuild with the last good value; combine with `StreamBuilder` for custom error UI if needed.
- **Tip**: Use with `MutablePylon` streams for two-way binding.

### PylonFuture

`PylonFuture<T>` pairs `FutureBuilder` with `Pylon<T>`, loading async data (e.g., API calls) and providing it as a pylon value on success.

#### Basic Usage

```dart
PylonFuture<String>(
  future: fetchUserName(),  // Your async function
  initialData: 'Loading...',  // Optional: Immediate pylon value
  builder: (context) => Text('User: ${context.pylon<String>()}'),
  loading: const CircularProgressIndicator(),  // Pending state
  error: const Text('Failed to load'),  // Error state
)
```

On completion, the resolved value populates the `Pylon`. Errors show the `error` widget.

#### Use Cases

- **Data Fetching**: HTTP requests, database queries, or file I/O.
- **Initialization**: Load app settings or user data at startup.
- **Chaining**: Nest with other pylons for dependent async state (e.g., fetch user, then posts).
- **Null Safety**: For nullable results, use `PylonFuture<T?>` and handle null in builder.

### PylonPort

`PylonPort<T>` persists pylon values in URL query parameters, enabling bookmarkable state for web apps (e.g., filters, selections). Requires a `PylonCodec<T>` for serialization.

#### Setup

Register codecs in `main()` before `runApp`:

```dart
import 'package:pylon/pylon.dart';

void main() {
  // Built-in: int, double, String, bool, List<String>, etc. (auto-registered)
  // Custom:
  registerPylonCodec<MyModel>(MyModelCodec());  // Implement PylonCodec<T>
  runApp(MyApp());
}
```

A basic codec example:

```dart
class MyModel {
  final String id;
  final int value;
  MyModel(this.id, this.value);

  // For encoding/decoding
  Map<String, dynamic> toJson() => {'id': id, 'value': value};
  factory MyModel.fromJson(Map<String, dynamic> json) =>
      MyModel(json['id'], json['value']);
}

class MyModelCodec extends PylonCodec<MyModel> {
  @override
  String encode(MyModel value) => jsonEncode(value.toJson());
  @override
  MyModel decode(String encoded) => MyModel.fromJson(jsonDecode(encoded));
}
```

#### Basic Usage

```dart
PylonPort<MyModel>(
  tag: 'state',  // URL param: ?state=encodedValue
  builder: (context) {
    final model = context.pylon<MyModel>();
    return FilterWidget(model: model);
  },
  nullable: true,  // Treat missing param as null (no loading)
  errorsAreNull: true,  // Decode errors -> null (requires nullable=true)
  loading: const SizedBox.shrink(),  // Or custom loader
  error: const Text('Invalid state'),
)
```

- On load: Decodes from URL (or null/default).
- On update: Encodes and updates URL via `context.setPylon<T>(newValue)`.
- Web-Only: Uses `Uri.base` for browser URLs; falls back gracefully on other platforms.

#### Use Cases

- **Web Apps**: Shareable filters (e.g., ?category=tech&sort=recent).
- **Deep Linking**: Restore app state from URLs.
- **SEO-Friendly**: State in URLs for crawlers.
- **Limitations**: Only primitives/complex types via codecs; large data may bloat URLs.

### Conduit

`Conduit<T>` manages global, app-wide state using a singleton `BehaviorSubject<T>`. It's reactive and accessible from anywhere, without widget tree dependency.

#### Basic Usage

```dart
// Set initial value
Conduit.push<String>('Global Message');

// Access globally (throws if null)
String msg = Conduit.pull<String>();

// Modify
Conduit.mod<String>((current) => current.toUpperCase());

// Or with null handling
Conduit.modOr<String>((current) => current?.toUpperCase() ?? 'DEFAULT');

// In widgets
Conduit<String>(
  builder: (context, value) => Text(value ?? 'No message'),
  defaultData: 'Fallback',  // Used if null
)
```

Static methods:

- `Conduit.push<T>(T value)`: Emit new value.
- `Conduit.pull<T>()`: Get current (or throw).
- `Conduit.pullOr<T>(T default)`: Get or default.
- `Conduit.stream<T>()`: Get the stream for listening.
- `Conduit.destroy<T>()`: Clear specific type.
- `Conduit.destroyAllConduits()`: Reset all.

#### Use Cases

- **App-Wide Settings**: Theme mode, user auth status, or notifications.
- **Cross-Screen Sync**: Update a badge count from any screen.
- **Integration**: Combine with `StreamBuilder` for non-widget listeners.
- **Cleanup**: Call `destroy` in dispose for long-lived apps.

### PylonRemove

`PylonRemove<T>` nullifies an ancestor `Pylon<T>` for descendants, useful for overriding or scoping (e.g., reset a filter).

#### Basic Usage

Requires the ancestor to be `Pylon<T?>` (nullable). Provides `null` as the value.

```dart
// Assume ancestor: Pylon<String?>(value: 'Global')
PylonRemove<String>(
  builder: (context) => Text(context.pylonOr<String>() ?? 'Local Override'),
  local: true,  // Optional: Scope to route
)
```

#### Use Cases

- **Scoped Overrides**: Temporarily hide global state (e.g., disable theme in a modal).
- **Testing/Debugging**: Nullify values to isolate components.
- **Note**: Only works with nullable types; for non-nullable, redesign as `T?`.

## Navigation and Routing

Pylon simplifies navigation while preserving non-local pylons:

```dart
// Push new screen with state
Pylon.push(context, DetailScreen());  // Material default

// Cupertino style
Pylon.push(context, DetailScreen(), type: PylonRouteType.cupertino);

// Replace current
Pylon.pushReplacement(context, HomeScreen());

// Clear stack to root
Pylon.pushAndRemoveUntil(
  context,
  LoginScreen(),
  predicate: (route) => route.isFirst,  // Or (route) => false to clear all
);
```

Internally, uses `PylonCluster` to mirror visible pylons. Custom routes: Pass `route` param.

#### Use Cases

- **Multi-Screen Apps**: Maintain user data across tabs or flows.
- **Deep Links**: Combine with `PylonPort` for web navigation.

## Extensions

Pylon extends core Flutter types for convenience:

### BuildContext

- Value Access: `pylon<T>()`, `pylonOr<T>()`, `hasPylon<T>()`.
- Mutation (MutablePylon): `setPylon<T>(value)`, `modPylon<T>(fn)`.
- Streaming: `streamPylon<T>()`, `watchPylon<T>(builder)`.

### Stream<T>

- `asPylon(builder, {initialData, loading})`: Inline `PylonStream`.

### Iterable<T>

- `withPylons(builder)`: Maps to `List<Pylon<T>>` for dynamic lists.

#### Custom Extensions Example

```dart
extension AuthContext on BuildContext {
  User? get currentUser => pylonOr<User>();
  bool get isAuthenticated => hasPylon<User>();
  void logout() => removePylon<User>();  // Custom: Use PylonRemove
}
```

## Advanced Patterns

### Composing State

Mix components for complex flows:

```dart
// Async mutable state with URL sync
PylonFuture<User>(
  future: api.fetchUser(),
  builder: (context) => MutablePylon<List<Post>>(
    value: [],
    builder: (context) => PylonPort<List<Post>>(
      tag: 'posts',
      builder: (context) => PostList(posts: context.pylon<List<Post>>()),
    ),
  ),
)
```

### Global + Local State

Use `Conduit` for app globals, `MutablePylon` for screens:

```dart
// Global auth in Conduit
Conduit<User?>(builder: (context, user) => PylonCluster(
  pylons: [
    if (user != null) Pylon<User>.data(user),  // Conditional
  ],
  builder: (context) => ScreenWithLocalState(),
))
```

### Error Boundaries

Wrap in `ErrorWidget.builder` or use try-catch in modifiers.

## Best Practices

- **Immutability**: Prefer immutable values; use `copyWith` for updates.
- **Typing**: Always use explicit types; avoid `dynamic`.
- **Locals**: Set `local: true` for temporary state to prevent leaks.
- **Rebuilds**: Use `rebuildChildren: false` + streams for optimization.
- **Codecs**: For `PylonPort`, implement secure encoding (e.g., base64 + JSON).
- **Testing**: Mock contexts with `Pylon` wrappers in widget tests.
- **Performance**: Cluster pylons; avoid deep trees. Profile with Flutter DevTools.
- **Null Safety**: Use `T?` for optional state; handle with `??` or conditionals.

Follow Dart style: Inline simple functions, prefer named params, use `final` fields.

## Examples

### 1. Simple Counter (MutablePylon)

```dart
import 'package:flutter/material.dart';
import 'package:pylon/pylon.dart';

class CounterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Pylon Counter')),
      body: const Center(child: CounterWidget()),
    ),
  );
}

class CounterWidget extends StatelessWidget {
  const CounterWidget({super.key});

  @override
  Widget build(BuildContext context) => MutablePylon<int>(
    value: 0,
    rebuildChildren: true,
    builder: (context) => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Count: ${context.pylon<int>()}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton(
              onPressed: () => context.modPylon<int>((v) => v - 1),
              child: const Icon(Icons.remove),
            ),
            FloatingActionButton(
              onPressed: () => context.modPylon<int>((v) => v + 1),
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    ),
  );
}
```

### 2. Todo List with Async Fetch (PylonFuture + MutablePylon)

```dart
// Assume Todo model with copyWith
class Todo {
  final String id;
  final String title;
  final bool completed;
  Todo({required this.id, required this.title, this.completed = false});
  Todo copyWith({String? title, bool? completed}) => Todo(
    id: id,
    title: title ?? this.title,
    completed: completed ?? this.completed,
  );
}

// Fetch todos (simulate async)
Future<List<Todo>> fetchTodos() async {
  await Future.delayed(const Duration(seconds: 1));
  return [
    Todo(id: '1', title: 'Learn Pylon'),
    Todo(id: '2', title: 'Build app'),
  ];
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
    home: PylonFuture<List<Todo>>(
      future: fetchTodos(),
      builder: (context) => TodoList(todos: context.pylon<List<Todo>>()),
      loading: const Center(child: CircularProgressIndicator()),
      error: const Center(child: Text('Failed to load todos')),
    ),
  );
}

class TodoList extends StatelessWidget {
  final List<Todo> todos;
  const TodoList({super.key, required this.todos});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Todos')),
    body: ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) => PylonCluster(
        pylons: [Pylon<Todo>.data(todos[index])],
        builder: (context) => TodoItem(todo: context.pylon<Todo>()),
      ),
    ),
  );
}

class TodoItem extends StatelessWidget {
  final Todo todo;
  const TodoItem({super.key, required this.todo});

  @override
  Widget build(BuildContext context) => MutablePylon<Todo>(
    value: todo,
    local: true,  // Per-item state
    builder: (context) => CheckboxListTile(
      title: Text(context.pylon<Todo>().title),
      value: context.pylon<Todo>().completed,
      onChanged: (bool? value) => context.modPylon<Todo>(
        (t) => t.copyWith(completed: value ?? false),
      ),
    ),
  );
}
```

### 3. Theme Switcher with Conduit and Navigation

```dart
import 'package:flutter/material.dart';
import 'package:pylon/pylon.dart';

void main() {
  Conduit.push<ThemeMode>(ThemeMode.system);  // Global initial theme
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => Conduit<ThemeMode>(
    builder: (context, mode) => MaterialApp(
      title: 'Theme Demo',
      themeMode: mode ?? ThemeMode.system,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const HomeScreen(),
    ),
    defaultData: ThemeMode.system,
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Pylon Theme Switcher'),
      actions: [
        IconButton(
          icon: const Icon(Icons.brightness_6),
          onPressed: () => Conduit.mod<ThemeMode>((current) =>
            switch (current) {
              ThemeMode.light => ThemeMode.dark,
              ThemeMode.dark => ThemeMode.system,
              _ => ThemeMode.light,
            },
          ),
        ),
      ],
    ),
    body: Center(
      child: ElevatedButton(
        onPressed: () => Pylon.push(context, const DetailScreen()),
        child: const Text('Go to Detail'),
      ),
    ),
  );
}

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) => Conduit<ThemeMode>(
    builder: (context, mode) => Scaffold(  // Access global theme here
      appBar: AppBar(title: Text('Detail (Theme: ${mode?.name ?? 'system'})')),
      body: const Center(child: Text('Theme persists across navigation!')),
    ),
  );
}
```

### 4. Web Filter with PylonPort

(Assumes web setup and codec registration as shown earlier.)

```dart
class FilterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PylonPort<FilterState>(
    tag: 'filter',
    nullable: true,
    errorsAreNull: true,
    builder: (context) {
      final filter = context.pylonOr<FilterState>() ?? FilterState.initial();
      return Scaffold(
        appBar: AppBar(title: const Text('Web Filters')),
        body: Column(
          children: [
            DropdownButton<String>(
              value: filter.category,
              items: ['all', 'tech', 'news'].map((c) => DropdownMenuItem(
                value: c,
                child: Text(c),
              )).toList(),
              onChanged: (value) => context.setPylon<FilterState>(
                filter.copyWith(category: value ?? 'all'),
              ),
            ),
            // Results list using filter...
          ],
        ),
      );
    },
  );
}

class FilterState {
  final String category;
  final DateTime? dateFrom;
  static const initial = FilterState(category: 'all');
  FilterState({required this.category, this.dateFrom});
  FilterState copyWith({String? category, DateTime? dateFrom}) =>
      FilterState(category: category ?? this.category, dateFrom: dateFrom ?? this.dateFrom);
  // Implement toJson/fromJson for codec
}
```

## Limitations and Troubleshooting

- **No Automatic Disposal**: Manually call `Conduit.destroy<T>()` for cleanup in long sessions.
- **Web-Only Features**: `PylonPort` relies on browser APIs; test thoroughly.
- **Type Conflicts**: If multiple `Pylon<T>` exist, nearest ancestor wins. Use `runtime` filter or clusters.
- **Rebuilds**: With `rebuildChildren: false`, ensure listeners (e.g., `watchPylon`) are used.
- **Errors**: Access throws on missing pylons—use `pylonOr` or checks.
- **Debugging**: Enable Flutter's debug mode; check console for codec errors.
- **Performance**: For 100+ pylons, profile tree depth; use clusters.

If issues arise, check the [CHANGELOG](CHANGELOG.md) or file an issue on pub.dev.

## Contributing

Contributions welcome! Fork, fix, and PR with tests. Follow Dart style guidelines. See [example/](example/) for a demo app.

---
