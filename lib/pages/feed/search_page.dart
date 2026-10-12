import 'package:flutter/material.dart';
import 'package:offline_hn/app_services.dart';
import 'package:offline_hn/data/repository/story_repository.dart';
import 'package:offline_hn/pages/feed/empty_feed.dart';
import 'package:offline_hn/pages/feed/story_entry_tile.dart';
import 'package:offline_hn/ui/small_caps.dart';
import 'package:offline_hn/ui/tokens.dart';

/// Searches every story on the phone. Nothing here asks the network.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.services});

  final AppServices services;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Stream<List<FeedEntry>>? _results;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _search(String query) {
    final text = query.trim();
    setState(
      () => _results = text.isEmpty
          ? null
          : widget.services.stories.watchSearch(text),
    );
  }

  void _clear() {
    _controller.clear();
    _search('');
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final onBar =
        Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).colorScheme.onPrimary;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          autofocus: true,
          cursorColor: onBar,
          style: TextStyle(color: onBar, fontSize: 18),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search stored stories',
            hintStyle: TextStyle(color: onBar.withValues(alpha: 0.85)),
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.close),
              onPressed: _clear,
            ),
        ],
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final results = _results;
    if (results == null) {
      return EmptyMessage(
        title: 'Search your stories',
        hint:
            'Looks through the titles, sources, authors and text posts '
            'stored on this phone.',
        tokens: context.tokens,
      );
    }
    return StreamBuilder<List<FeedEntry>>(
      stream: results,
      builder: (context, snapshot) {
        final entries = snapshot.data;
        if (entries == null) return const SizedBox.shrink();
        if (entries.isEmpty) {
          return EmptyMessage(
            title: 'No stored stories match',
            hint: 'Only stories already on this phone are searched.',
            tokens: context.tokens,
          );
        }
        final now = DateTime.now();
        return ListView.separated(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewPaddingOf(context).bottom,
          ),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const Hairline(inset: 22),
          itemBuilder: (context, index) => StoryEntryTile(
            key: ValueKey(entries[index].story.id),
            services: widget.services,
            entry: entries[index],
            entries: entries,
            now: now,
            onOpen: _focus.unfocus,
          ),
        );
      },
    );
  }
}
