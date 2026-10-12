import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:offline_hn/capture/archive_anchor.dart';

/// Shows a saved web archive inside the app. Nothing here touches the network:
/// the page is already complete on disk.
class SavedPageViewer extends StatefulWidget {
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
  State<SavedPageViewer> createState() => _SavedPageViewerState();
}

class _SavedPageViewerState extends State<SavedPageViewer> {
  final _loading = ValueNotifier<bool>(true);
  late final Future<Uri?> _location = archiveLocation(File(widget.path));

  @override
  void dispose() {
    _loading.dispose();
    super.dispose();
  }

  void _loaded(Object? _, Object? _) => _loading.value = false;

  /// A link to a section of the page points at the live address, which
  /// WebView would load from the network. Load the copy at that fragment
  /// instead: WebView does not treat a jump within an archive as a jump.
  Future<NavigationActionPolicy> _followLink(
    InAppWebViewController controller,
    NavigationAction action,
  ) async {
    final request = action.request.url?.uriValue;
    final location = await _location;
    if (request == null || location == null) {
      return NavigationActionPolicy.ALLOW;
    }
    final target = sameDocumentTarget(request, location, Uri.file(widget.path));
    if (target == null) return NavigationActionPolicy.ALLOW;
    await controller.loadUrl(urlRequest: URLRequest(url: WebUri.uri(target)));
    return NavigationActionPolicy.CANCEL;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (widget.onOpenLive != null)
            IconButton(
              tooltip: 'Open live site',
              icon: const Icon(Icons.open_in_new),
              onPressed: widget.onOpenLive,
            ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri.uri(Uri.file(widget.path)),
            ),
            initialSettings: InAppWebViewSettings(
              allowFileAccess: true,
              javaScriptEnabled: false,
              useWideViewPort: true,
              // Left unset, WebView scales text by the system font size and
              // breaks the page's layout; pinch zoom is there instead.
              textZoom: 100,
              supportZoom: true,
              builtInZoomControls: true,
              displayZoomControls: false,
              useShouldOverrideUrlLoading: true,
            ),
            shouldOverrideUrlLoading: _followLink,
            onLoadStop: _loaded,
            onReceivedError: (_, _, _) => _loading.value = false,
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _loading,
            builder: (context, loading, _) => loading
                ? ColoredBox(
                    color: Theme.of(context).colorScheme.surface,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
