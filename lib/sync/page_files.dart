import 'dart:io';

import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/prune_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where saved pages live: under the app-support directory, never the cache,
/// which the system may empty. Paths in the database are relative to [root].
class PageFiles implements StoredFiles {
  const PageFiles(this.root);

  static const directoryName = 'pages';
  static const linkDirectoryName = 'links';

  final Directory root;

  static Future<PageFiles> locate() async =>
      PageFiles(await getApplicationSupportDirectory());

  String relativePathFor(int storyId, PageKind kind) =>
      '$directoryName/$storyId.${kind == PageKind.pdf ? 'pdf' : 'mhtml'}';

  String relativeLinkPathFor(int linkId, PageKind kind) =>
      '$directoryName/$linkDirectoryName/$linkId.${kind == PageKind.pdf ? 'pdf' : 'mhtml'}';

  File fileFor(String relativePath) => File(p.join(root.path, relativePath));

  Future<void> ensureDirectory() =>
      Directory(p.join(root.path, directoryName, linkDirectoryName))
          .create(recursive: true);

  @override
  Future<void> delete(String relativePath) async {
    final file = fileFor(relativePath);
    if (file.existsSync()) await file.delete();
  }

  @override
  bool exists(String relativePath) => fileFor(relativePath).existsSync();

  /// Every file under the pages directory.
  @override
  Future<List<({String path, DateTime modified, int bytes})>> list() async {
    final directory = Directory(p.join(root.path, directoryName));
    if (!directory.existsSync()) return const [];
    final found = <({String path, DateTime modified, int bytes})>[];
    await for (final entity in directory.list(recursive: true)) {
      if (entity is! File) continue;
      final stat = await entity.stat();
      found.add((
        path: p.relative(entity.path, from: root.path),
        modified: stat.modified,
        bytes: stat.size,
      ));
    }
    return found;
  }
}
