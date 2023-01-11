import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;
import 'package:async/async.dart' show StreamGroup;

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
      : name = json['name'] as String,
        age = json['age'] as int;

  @override
  String toString() => 'Person (name: $name, age: $age)';
}

// Creates instances of request
@immutable
class PersonsRequest {
  final ReceivePort receivePort;
  final Uri uri;

  const PersonsRequest(
    this.receivePort,
    this.uri,
  );

  static Iterable<PersonsRequest> all() sync* {
    for (final i in Iterable.generate(3, (i) => i)) {
      yield PersonsRequest(
        ReceivePort(),
        Uri.parse('http://10.0.2.2:5500/apis/people${i + 1}.json'),
      );
    }
  }
}

// Convert instance of PersonsRequest to Request
@immutable
class Request {
  final SendPort sendPort;
  final Uri uri;
  const Request(this.sendPort, this.uri);

  Request.from(PersonsRequest request)
      : sendPort = request.receivePort.sendPort,
        uri = request.uri;
}

// Consumer/Entrance
Stream<Iterable<Person>> getPersons() {
  final streams = PersonsRequest.all().map((req) =>
      Isolate.spawn(_getPersons, Request.from(req))
          .asStream()
          .asyncExpand((_) => req.receivePort)
          .takeWhile((element) => element is Iterable<Person>)
          .cast());

  return StreamGroup.merge(streams).cast();
}

// Main function to return Iterable value
void _getPersons(Request request) async {
  final persons = await HttpClient()
      .getUrl(request.uri)
      .then((req) => req.close())
      .then((response) => response.transform(utf8.decoder).join())
      .then((jsonString) => json.decode(jsonString) as List<dynamic>)
      .then((json) => json.map((map) => Person.fromJson(map)));
  // request.sendPort.send(persons); // Send Copy
  Isolate.exit(request.sendPort, persons); // Pass value, more efficient
}

void testIt() async {
  await for (final msg in getPersons()) {
    msg.log();
  }
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
          onPressed: () {
            testIt();
          },
          child: const Text('Press me'),
        ));
  }
}
