import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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

  @override
  void dispose() {
    _loading.dispose();
    super.dispose();
  }

  void _loaded(Object? _, Object? _) => _loading.value = false;

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
            ),
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
