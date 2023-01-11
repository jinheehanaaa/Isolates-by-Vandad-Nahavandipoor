import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

extension Log on Object {
  void log() => devtools.log(toString());
}

void main() {
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    ),
  );
}

@immutable
class Person {
  final String name;
  final int age;

  const Person({
    required this.name,
    required this.age,
  });

  Person.fromJson(Map<String, dynamic> json)
      : name = json["name"] as String,
        age = json["age"] as int;
}

// Entrance function to isolate (Consumer)
Future<Iterable<Person>> getPersons() async {
  final rp = ReceivePort(); // Grab values
  await Isolate.spawn(_getPersons, rp.sendPort);
  return await rp.first;
}

// Main body of isolate
void _getPersons(SendPort sp) async {
  const url = 'http://10.0.2.2:5500/apis/people1.json';
  final persons = await HttpClient()
      .getUrl(Uri.parse(url))
      .then((req) => req.close())
      .then((response) => response.transform(utf8.decoder).join())
      .then((jsonString) => json.decode(jsonString) as List<dynamic>)
      .then((json) => json.map((map) => Person.fromJson(map)));

  Isolate.exit(sp, persons);
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Home Page'),
        ),
        body: ElevatedButton(
          onPressed: () async {
            final persons = await getPersons();
            persons.log();
          },
          child: const Text('Press me'),
        ));
  }
}
