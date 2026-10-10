import 'dart:convert';
import 'dart:io';

Object? fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync());

String fixtureText(String name) =>
    File('test/fixtures/$name').readAsStringSync();
