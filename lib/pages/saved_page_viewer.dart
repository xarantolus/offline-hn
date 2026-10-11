import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Shows a saved web archive inside the app. Nothing here touches the network:
/// the page is already complete on disk.
class SavedPageViewer extends StatelessWidget {
  const SavedPageViewer({
    super.key,
    required this.path,
    required this.title,
    this.onOpenLive,
  });

  final String path;
  final String title;
  final VoidCallback? onOpenLive;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (onOpenLive != null)
            IconButton(
              tooltip: 'Open live site',
              icon: const Icon(Icons.open_in_new),
              onPressed: onOpenLive,
            ),
        ],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri.uri(Uri.file(path))),
        initialSettings: InAppWebViewSettings(
          allowFileAccess: true,
          javaScriptEnabled: false,
          useWideViewPort: true,
          supportZoom: true,
          builtInZoomControls: true,
          displayZoomControls: false,
        ),
      ),
    );
  }
}
