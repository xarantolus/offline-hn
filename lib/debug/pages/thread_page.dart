import 'package:flutter/material.dart';
import 'package:offline_hn/debug/mock_data.dart';
import 'package:offline_hn/ui/comment_row.dart';
import 'package:offline_hn/ui/thread_header.dart';

class MockThreadPage extends StatefulWidget {
  const MockThreadPage({super.key, required this.thread});

  final MockThread thread;

  @override
  State<MockThreadPage> createState() => _MockThreadPageState();
}

class _MockThreadPageState extends State<MockThreadPage> {
  late final Set<int> _collapsed = widget.thread.initiallyCollapsed;

  void _toggle(int id) {
    setState(() {
      if (!_collapsed.remove(id)) _collapsed.add(id);
    });
  }

  void _announce(String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(what)));
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;
    final story = thread.story;
    final copy = story.savedCopy;
    final items = thread.visible(_collapsed);
    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: ListView.builder(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
        ),
        itemCount: items.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return ThreadHeader(
              title: story.title,
              domain: story.domain,
              author: story.author,
              points: story.points,
              comments: story.comments,
              newComments: thread.newCount,
              savedCopy: copy == null
                  ? null
                  : SavedCopyInfo(
                      sizeMb: copy.sizeMb,
                      fetchedAt: copy.fetchedAt,
                    ),
              onOpenSaved: () => _announce('Open saved copy'),
              onOpenLive: () => _announce('Open live site'),
              onSave: () => _announce('Save'),
              onShare: () => _announce('Share'),
            );
          }
          final item = items[i - 1];
          final c = item.comment;
          return CommentRow(
            author: c.author,
            age: c.age,
            depth: c.depth,
            blocks: c.blocks,
            isOp: c.isOp,
            isNew: c.isNew,
            collapsed: item.collapsed,
            hiddenCount: item.hiddenCount,
            hasChildren: item.hasChildren,
            onToggle: () => _toggle(c.id),
          );
        },
      ),
    );
  }
}
