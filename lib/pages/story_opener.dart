import 'dart:io';

import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/data/db/database.dart';
import 'package:offline_hn/data/model/page_enums.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/model/viewer_kind.dart';
import 'package:offline_hn/pages/saved_page_viewer.dart';
import 'package:page_capture/page_capture.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Everything that leaves a story for something else: its saved copy, the
/// live site, a link in a comment, the share sheet.
class StoryOpener {
  const StoryOpener(this._services);

  final AppServices _services;

  static Uri discussionUri(int storyId) =>
      Uri.https('news.ycombinator.com', '/item', {'id': '$storyId'});

  Future<void> openSavedCopy(
    BuildContext context,
    StoryRow story,
    PageCopyRow page,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final relative = page.relativePath;
    final file = relative == null
        ? null
        : _services.pageFiles.fileFor(relative);
    if (file == null || !file.existsSync()) {
      _say(messenger, 'The saved copy is missing');
      return;
    }
    await _services.pages.markOpened(story.id, DateTime.now());
    if (!context.mounted) return;
    await _show(
      context,
      file,
      page.kind,
      title: story.title,
      live: story.url == null ? null : Uri.tryParse(story.url!),
    );
  }

  /// A page saved from a link in a comment. False when its file is gone, so
  /// the caller can open the link as usual.
  Future<bool> openLinkCopy(
    BuildContext context,
    Uri uri,
    LinkCopyRow copy,
  ) async {
    final relative = copy.relativePath;
    final file = relative == null
        ? null
        : _services.pageFiles.fileFor(relative);
    if (file == null || !file.existsSync()) return false;
    await _services.links.markOpened(copy.id, DateTime.now());
    if (!context.mounted) return true;
    await _show(context, file, copy.kind, title: uri.host, live: uri);
    return true;
  }

  Future<void> _show(
    BuildContext context,
    File file,
    PageKind kind, {
    required String title,
    required Uri? live,
  }) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final viewer = await _services.settings.read(Settings.viewer);
    final shown = switch (kind) {
      PageKind.pdf => await PageCapture.openPdf(file.path),
      PageKind.mhtml =>
        viewer == ViewerKind.customTab &&
            await PageCapture.openInCustomTab(file.path),
      PageKind.thread => false,
    };
    if (shown) return;
    if (kind == PageKind.pdf) {
      _say(messenger, 'No app on this phone can show PDFs');
      return;
    }
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => SavedPageViewer(
          path: file.path,
          title: title,
          onOpenLive: live == null
              ? null
              : () => openWeb(navigator.context, live),
        ),
      ),
    );
  }

  /// The saved copy when there is one, else the live site while online, else
  /// nothing.
  Future<void> openArticle(BuildContext context, StoryRow story) async {
    final page = await _services.pages.watch(story.id).first;
    if (!context.mounted) return;
    if (page != null &&
        page.status == PageStatus.ok &&
        page.relativePath != null) {
      await openSavedCopy(context, story, page);
      return;
    }
    final url = story.url == null ? null : Uri.tryParse(story.url!);
    if (url == null) return;
    final connection = await _services.sync.connection.first;
    if (!context.mounted || connection == ConnectionKind.none) return;
    await openWeb(context, url);
  }

  /// In a custom tab. Says so instead of opening an error page when the phone
  /// is offline.
  Future<void> openWeb(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final connection = await _services.sync.connection.first;
    if (connection == ConnectionKind.none) {
      _say(messenger, 'You are offline. The live site needs a connection.');
      return;
    }
    final opened =
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView) ||
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) _say(messenger, 'No app can open this link');
  }

  Future<void> share(String title, Uri uri) => SharePlus.instance.share(
    ShareParams(subject: title, text: '$title\n$uri'),
  );

  void _say(ScaffoldMessengerState messenger, String text) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}
