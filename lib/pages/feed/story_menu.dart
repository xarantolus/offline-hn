import 'package:flutter/material.dart';
import 'package:offline_hn/data/db/database.dart';

enum StoryAction { comments, bookmark, read, hide, share }

Future<StoryAction?> showStoryMenu(BuildContext context, StoryRow story) {
  return showModalBottomSheet<StoryAction>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _item(
            context,
            StoryAction.comments,
            Icons.mode_comment_outlined,
            'Comments',
          ),
          _item(
            context,
            StoryAction.bookmark,
            story.saved ? Icons.bookmark : Icons.bookmark_border,
            story.saved ? 'Remove bookmark' : 'Bookmark',
          ),
          _item(
            context,
            StoryAction.read,
            story.read ? Icons.mark_email_unread_outlined : Icons.done,
            story.read ? 'Mark as unread' : 'Mark as read',
          ),
          _item(context, StoryAction.share, Icons.ios_share, 'Share'),
          _item(
            context,
            StoryAction.hide,
            Icons.visibility_off_outlined,
            'Hide story',
          ),
        ],
      ),
    ),
  );
}

Widget _item(
  BuildContext context,
  StoryAction action,
  IconData icon,
  String label,
) => ListTile(
  leading: Icon(icon),
  title: Text(label),
  onTap: () => Navigator.of(context).pop(action),
);
