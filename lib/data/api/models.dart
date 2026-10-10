class RemoteStory {
  const RemoteStory({
    required this.id,
    this.title,
    this.url,
    this.by,
    this.points,
    this.commentCount,
    this.time,
    this.type = 'story',
    this.text,
  });

  final int id;
  final String? title;
  final String? url;
  final String? by;
  final int? points;
  final int? commentCount;
  final DateTime? time;
  final String type;
  final String? text;
}

class RemoteComment {
  const RemoteComment({
    required this.id,
    this.parentId,
    this.by,
    this.text,
    this.time,
    this.dead = false,
    this.deleted = false,
    this.children = const [],
  });

  final int id;
  final int? parentId;
  final String? by;
  final String? text;
  final DateTime? time;
  final bool dead;
  final bool deleted;
  final List<RemoteComment> children;
}

class RemoteThread {
  const RemoteThread({required this.story, required this.comments});

  final RemoteStory story;
  final List<RemoteComment> comments;
}
