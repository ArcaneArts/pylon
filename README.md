# Pylon

A simple, reliable state management solution for Flutter that works the way you expect it to.

[![pub package](https://img.shields.io/pub/v/pylon.svg)](https://pub.dev/packages/pylon)

## Overview

Pylon is a state management package that works similarly to [provider](https://pub.dev/packages/provider), but with a focus on reliability and simplicity. It provides an intuitive way to pass values down the widget tree and access them from descendant widgets without the typical headaches of other state management solutions.

### Design Philosophy

Unlike other state management packages, Pylon's primary job is to manage state reliably. We prioritize reliability over efficiency and speed. If a solution doesn't work 100% of the time or requires developers to understand complex internal mechanisms, we consider it inadequate. Pylon is designed to be simple, intuitive, and consistently reliable.

### Key Features

* **Simple API** - Easy to understand and use with minimal boilerplate
* **Navigation Support** - Works across navigation routes with built-in helpers
* **Immediate Access** - Access values even from immediate parent widgets
* **Mutable State** - Easily update values and rebuild dependent widgets
* **Async Support** - Seamlessly integrate with Future and Stream data
* **URL Integration** - Synchronize state with URL parameters (great for web apps)
* **Global State** - Use Conduit for application-wide state management
* **Combining Pylons** - Efficiently group multiple Pylons with PylonCluster

## Table of Contents

- [Getting Started](#getting-started)
- [Core Components](#core-components)
  - [Pylon](#pylon-1)
  - [MutablePylon](#mutablepylon)
  - [PylonCluster](#pyloncluster)
  - [PylonStream](#pylonstream)
  - [PylonFuture](#pylonfuture)
  - [PylonPort](#pylonport)
  - [Conduit](#conduit)
- [Extensions](#extensions)
- [Advanced Usage](#advanced-usage)
- [Examples](#examples)

## Getting Started

Add Pylon to your `pubspec.yaml`:

```yaml
dependencies:
  pylon: ^latest_version
```

Import it in your Dart code:

```dart
import 'package:pylon/pylon.dart';
```

## Core Components

### Pylon

The `Pylon<T>` widget is the foundation of the package. It provides a value of type `T` to its descendants in the widget tree.

#### Basic Usage

```dart
Pylon<int>(
  value: 42,
  builder: (context) => Text('The answer is ${context.pylon<int>()}'),
)
```

#### Constructors

- `Pylon({required T value, required PylonBuilder builder, bool local = false})` - Basic constructor with a builder
- `Pylon.withChild({required T value, required Widget child, bool local = false})` - Use when you don't need to access the value immediately
- `Pylon.data({required T value, bool local = false})` - Used primarily with PylonCluster

#### Accessing Values

You can access pylon values using BuildContext extensions:

```dart
// Get the value (throws if not found)
int count = context.pylon<int>();

// Get the value or null if not found
String? name = context.pylonOr<String>();

// Check if a pylon is available
bool hasTheme = context.hasPylon<ThemeData>();
```

#### Navigation with Pylons

Pylon provides methods to navigate while preserving pylon values:

```dart
// Push a new route with all visible pylons
Pylon.push(context, DetailsScreen());

// Replace the current route
Pylon.pushReplacement(context, HomeScreen());

// Push and remove routes until predicate
Pylon.pushAndRemoveUntil(context, LoginScreen(), 
  predicate: (route) => false); // Clear all routes
```

#### Nullifying Pylons

You can use `PylonRemove<T>` to nullify a pylon value:

```dart
// Remove the current theme pylon for all descendants
PylonRemove<ThemeData>(
  builder: (context) => MyWidget(),
)
```

### MutablePylon

`MutablePylon<T>` extends `Pylon<T>` to provide mutable state management. It allows the value to be modified after the widget has been built.

#### Basic Usage

```dart
MutablePylon<int>(
  value: 0, // Initial value
  builder: (context) => Column(
    children: [
      Text('Count: ${context.pylon<int>()}'),
      ElevatedButton(
        onPressed: () => context.modPylon<int>((value) => value + 1),
        child: Text('Increment'),
      ),
    ],
  ),
)
```

#### Modifying Values

There are several ways to modify a MutablePylon's value:

```dart
// Using BuildContext extensions
context.setPylon<int>(42); // Set to specific value
context.modPylon<int>((value) => value + 1); // Modify based on current value

// Using MutablePylon static methods
MutablePylon.of<int>(context).value = 42;
```

#### Reactive Streaming

You can listen to value changes:

```dart
// Get the stream
Stream<int> counterStream = context.streamPylon<int>();

// Use the watchPylon extension for reactive UI
Widget counterDisplay = context.watchPylon<int>((count) => 
  Text('Count: $count')
);
```

### PylonCluster

`PylonCluster` allows you to group multiple `Pylon` widgets together efficiently, reducing the nesting depth of your widget tree.

#### Basic Usage

```dart
PylonCluster(
  pylons: [
    Pylon<int>.data(value: 42),
    Pylon<String>.data(value: "Hello"),
    Pylon<List<String>>.data(value: ["one", "two", "three"]),
  ],
  builder: (context) {
    // All pylons are accessible here
    int count = context.pylon<int>();
    String message = context.pylon<String>();
    List<String> items = context.pylon<List<String>>();
    
    return YourWidget(count: count, message: message, items: items);
  },
)
```

### PylonStream

`PylonStream<T>` combines a `StreamBuilder` with a `Pylon` to provide reactive state management from a Stream.

#### Basic Usage

```dart
// Create a stream
final counterStream = Stream.periodic(
  Duration(seconds: 1), 
  (i) => i
).take(10);

// Use PylonStream to provide the latest value
PylonStream<int>(
  stream: counterStream,
  initialData: 0, // Optional initial value
  builder: (context) => Text('Stream value: ${context.pylon<int>()}'),
  loading: CircularProgressIndicator(), // Shown before first emission
)
```

#### Stream Extension

You can also use the `asPylon()` extension method on Stream:

```dart
counterStream.asPylon(
  (context) => Text('Count: ${context.pylon<int>()}'),
  initialData: 0,
)
```

### PylonFuture

`PylonFuture<T>` combines a `FutureBuilder` with a `Pylon` to handle asynchronous data loading.

#### Basic Usage

```dart
PylonFuture<User>(
  future: userRepository.fetchUser(userId),
  builder: (context) => UserProfileWidget(), // Builds when data is ready
  loading: LoadingIndicator(), // Shown while loading
  error: ErrorWidget(), // Shown on error
)
```

### PylonPort

`PylonPort<T>` synchronizes a pylon value with URL query parameters, which is particularly useful for web applications.

#### Setup

First, register a codec for your data type:

```dart
void main() {
  // Register built-in codecs (e.g., string, int, double, etc.)
  // or custom codecs for your types
  registerPylonCodec<MyData>(const MyDataCodec());
  runApp(MyApp());
}
```

#### Basic Usage

```dart
PylonPort<int>(
  tag: 'count', // URL query parameter name
  builder: (context) => CounterWidget(),
  nullable: true, // Allow null values when parameter isn't in URL
)
```

With this setup, the counter value will be stored in the URL as `?count=42` and restored when the page is refreshed or shared.

### Conduit

`Conduit` provides global state management using BehaviorSubjects. It's useful for application-wide state that needs to be accessed from anywhere.

#### Basic Usage

```dart
// Push a value to a global stream
Conduit.push<ThemeMode>(ThemeMode.dark);

// Access the value
ThemeMode currentTheme = Conduit.pull<ThemeMode>();

// Modify the value
Conduit.mod<ThemeMode>((current) => 
  current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark
);

// Use in widget tree
Conduit<ThemeMode>(
  builder: (context, value) => 
    Text('Current theme: ${value ?? ThemeMode.system}'),
  defaultData: ThemeMode.system, // Used when value is null
)
```

## Extensions

Pylon provides several helpful extensions:

### BuildContext Extensions

```dart
// Access values
T value = context.pylon<T>();
T? valueOrNull = context.pylonOr<T>();
bool exists = context.hasPylon<T>();

// Modify values (for MutablePylon)
context.setPylon<T>(newValue);
context.modPylon<T>((value) => modifiedValue);

// Access streams (for MutablePylon)
Stream<T> stream = context.streamPylon<T>();
Widget reactive = context.watchPylon<T>((value) => MyWidget(value));
```

### Stream Extensions

```dart
// Convert a stream to a PylonStream
myStream.asPylon((context) => MyWidget());
```

### Iterable Extensions

```dart
// Convert an iterable to a list of Pylons
List<Widget> widgets = myItems.withPylons((context) => ItemWidget());
```

## Advanced Usage

### Combining Different Pylon Types

You can compose different Pylon types to create powerful patterns:

```dart
// Stream data with persistence in URL
PylonStream<int>(
  stream: counterStream,
  builder: (context) => PylonPort<int>(
    tag: 'count',
    builder: (context) => CounterWidget(),
  ),
)
```

### Custom Context Extensions

Create custom extensions for cleaner code:

```dart
extension UserContext on BuildContext {
  User get user => pylon<User>();
  bool get isLoggedIn => hasPylon<User>();
  void updateUser(User updatedUser) => setPylon<User>(updatedUser);
}

// Later in your code
if (context.isLoggedIn) {
  Text('Welcome, ${context.user.name}');
}
```

## Examples

### Basic Counter

```dart
import 'package:flutter/material.dart';
import 'package:pylon/pylon.dart';

class Counter extends StatelessWidget {
  Counter({super.key});

  @override
  Widget build(BuildContext context) => Pylon<int>(
    value: 0,
    builder: (context) => Scaffold(
      appBar: AppBar(title: Text('Pylon Counter')),
      body: Center(
        child: Text("Count: ${context.pylon<int>()}", 
          style: Theme.of(context).textTheme.headline4),
      ), 
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.modPylon<int>((t) => t + 1),
        child: Icon(Icons.add),
      )
    )
  );
}
```

### Data Sharing Across Screens

```dart
// Basic dog class with copyWith
class Dog {
  final String name;
  final int age;
  
  Dog(this.name, this.age);
  
  Dog copyWith({String? name, int? age}) =>
      Dog(name ?? this.name, age ?? this.age);
}

// A list of dogs
List<Dog> dogs = [
  Dog("Fido", 3),
  Dog("Rex", 5),
  Dog("Spot", 2),
];

// A convenient extension to access the pylon value
extension DogContext on BuildContext {
  Dog get dog => pylon<Dog>();
  set dog(Dog value) => setPylon(value);
}

// A list view of our dogs
class DogList extends StatelessWidget {
  const DogList({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    // Map each dog into a Pylon<Dog>(value: e, builder: () => DogTile())
    children: dogs.withPylons((context) => DogTile()),
  );
}

// A list tile for a dog
class DogTile extends StatelessWidget {
  const DogTile({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
      title: Text(context.dog.name),
      trailing: Text("${context.dog.age}y old"),
      // Use pylon.push to navigate to the dog screen and keep the context.dog available
      onTap: () => Pylon.push(context, DogScreen()));
}

class DogScreen extends StatelessWidget {
  const DogScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(context.dog.name)),
      body: Center(
        child: Text("Age: ${context.dog.age}", 
          style: Theme.of(context).textTheme.headline4),
      ),
      floatingActionButton: FloatingActionButton(
        // Increment the age on dog which will update automatically
        onPressed: () => context.dog = context.dog
            .copyWith(age: context.dog.age + 1),
        child: Icon(Icons.add),
      ));
}
```

### Theme Switching with Conduit

```dart
void main() {
  // Set initial theme
  Conduit.push<ThemeMode>(ThemeMode.system);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Conduit<ThemeMode>(
    builder: (context, themeMode) => MaterialApp(
      title: 'Pylon Demo',
      themeMode: themeMode ?? ThemeMode.system,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: HomePage(),
    ),
  );
}

class ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(Icons.brightness_medium),
    onPressed: () => Conduit.mod<ThemeMode>((current) => 
      current == ThemeMode.light ? ThemeMode.dark : ThemeMode.light),
  );
}
```

### Form State Management

```dart
class FormState {
  final String name;
  final String email;
  final bool isValid;
  
  FormState({this.name = '', this.email = '', this.isValid = false});
  
  FormState copyWith({String? name, String? email, bool? isValid}) => 
    FormState(
      name: name ?? this.name,
      email: email ?? this.email,
      isValid: isValid ?? this.isValid,
    );
}

class FormScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MutablePylon<FormState>(
    value: FormState(),
    builder: (context) => Scaffold(
      appBar: AppBar(title: Text('Form Example')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Name'),
              onChanged: (value) => context.modPylon<FormState>(
                (form) => form.copyWith(
                  name: value,
                  isValid: value.isNotEmpty && form.email.isNotEmpty,
                )
              ),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Email'),
              onChanged: (value) => context.modPylon<FormState>(
                (form) => form.copyWith(
                  email: value,
                  isValid: form.name.isNotEmpty && value.isNotEmpty,
                )
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: context.pylon<FormState>().isValid 
                ? () => submitForm(context.pylon<FormState>())
                : null,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    ),
  );
  
  void submitForm(FormState form) {
    // Process the form data
    print('Submitting form: ${form.name}, ${form.email}');
  }
}
```