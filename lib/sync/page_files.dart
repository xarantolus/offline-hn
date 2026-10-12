import 'dart:io';

import 'package:offline_hn/data/model/page_enums.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where saved pages live: under the app-support directory, never the cache,
/// which the system may empty. Paths in the database are relative to [root].
class PageFiles {
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

  Future<void> delete(String relativePath) async {
    final file = fileFor(relativePath);
    if (file.existsSync()) await file.delete();
  }
}
