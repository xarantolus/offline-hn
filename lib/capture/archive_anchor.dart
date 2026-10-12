import 'dart:io';

/// Where an archive says it was saved from. A link to `#section` is
/// serialized as that address plus the fragment, so this is what such a link
/// points at.
Future<Uri?> archiveLocation(File archive) async {
  final head = await archive
      .openRead(0, 2048)
      .expand((chunk) => chunk)
      .toList();
  return snapshotLocation(String.fromCharCodes(head));
}

Uri? snapshotLocation(String header) {
  final match = RegExp(
    r'^Snapshot-Content-Location:[ \t]*(\S+)',
    multiLine: true,
    caseSensitive: false,
  ).firstMatch(header);
  return match == null ? null : Uri.tryParse(match.group(1)!);
}

/// The copy itself at the fragment [request] names, when [request] is only a
/// jump within the page the archive was saved from; null for any other link.
Uri? sameDocumentTarget(Uri request, Uri location, Uri copy) {
  if (!request.hasFragment ||
      !location.isScheme('https') && !location.isScheme('http')) {
    return null;
  }
  if (request.removeFragment() != location.removeFragment()) return null;
  final bare = copy.removeFragment();
  return request.fragment.isEmpty
      ? bare
      : bare.replace(fragment: Uri.decodeComponent(request.fragment));
}
