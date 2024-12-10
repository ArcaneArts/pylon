import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:pylon/pylon.dart';

// Temporary storage of the "data"
List<Note> notes = [];

// Temporary function to add a note
void _addNote(String title, String note) => notes.add(Note(
      id: notes.length,
      name: title,
      description: note,
    ));

// A note class representing our data model
class Note implements PylonCodec<Note> {
  final int id;
  final String name;
  final String description;

  const Note({
    required this.id,
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'id': id,
        'description': description,
      };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
        name: map['name'],
        description: map['description'],
        id: map['id'],
      );

  @override
  String pylonEncode(Note value) => value.id.toString();

  @override
  Future<Note> pylonDecode(String value) async => notes[int.parse(value)];
}

void main() {
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Add some "notes"
  for (int i = 0; i < 100; i++) {
    _addNote("Hello Note ${notes.length}",
        "This is the content of note ${notes.length}");
  }

  registerPylonCodec(const Note(id: -1, name: "", description: ""));

  // Register the codec
  runApp(MainS());
}

extension _XContextPylonNotes on BuildContext {
  Note get note => pylon<Note>();
}

class MainS extends StatelessWidget {
  Map<String, WidgetBuilder> routes = {
    "/": (context) => const HomeScreen(),
    "/note": (context) => const NoteScreen()
  };

  MainS({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        onGenerateRoute: (RouteSettings settings) {
          if (settings.name?.isNotEmpty ?? false) {
            String route = Uri.parse(settings.name!).path;

            if (routes.containsKey(route)) {
              return MaterialPageRoute(
                  builder: routes[route]!, settings: settings);
            }
          }
        },
        routes: routes,
        initialRoute: "/",
      );
}

// Just shows a list of notes into pylons
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ListView.builder(
          // For each note build a pylon wrapped around our note tile
          itemBuilder: (context, i) => Pylon<Note>(
            value: notes[i],
            builder: (context) => NoteTile(),
          ),
          itemCount: notes.length,
        ),
      );
}

// A list tile showing a note
class NoteTile extends StatelessWidget {
  const NoteTile({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(context.note.name),
        subtitle: Text(context.note.description),
        onTap: () => Pylon.push(context, NoteScreen(),
            settings: RouteSettings(
              name: "/note",
            )),
      );
}

class NoteScreen extends StatelessWidget {
  const NoteScreen({super.key});

  @override
  Widget build(BuildContext context) => PylonPort<Note>(
        tag: "note",
        loading:
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error:
            const Scaffold(body: Center(child: Text("Something went wrong"))),
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(context.note.name),
          ),
          body: Text(context.note.description),
        ),
      );
}
