import 'dart:convert';
import 'dart:io';

import 'package:offline_hn/data/prune_service.dart';

Object? fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync());

String fixtureText(String name) =>
    File('test/fixtures/$name').readAsStringSync();

/// Saved files for pruning: every path a row names exists unless listed in
/// [missing], [stored] are the files on disk, and deletions land in [deleted].
class FakeFiles implements StoredFiles {
  FakeFiles(this.deleted, {this.stored = const [], this.missing = const {}});

  final List<String> deleted;
  final List<({String path, DateTime modified, int bytes})> stored;
  final Set<String> missing;

  @override
  Future<List<({String path, DateTime modified, int bytes})>> list() async =>
      stored;

  @override
  bool exists(String relativePath) => !missing.contains(relativePath);

  @override
  Future<void> delete(String relativePath) async => deleted.add(relativePath);
}
