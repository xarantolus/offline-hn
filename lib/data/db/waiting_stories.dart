/// Stories only a ranking still waiting for its comments has brought in.
/// Nothing but the feed's own lists is meant to see them before it publishes;
/// a bookmark or an earlier published ranking makes a story visible anyway.
const waitingStoryIds = '''(
  SELECT DISTINCT u.story_id FROM feed_snapshots u
  WHERE u.published = 0
    AND NOT EXISTS (
      SELECT 1 FROM feed_snapshots p
      WHERE p.published = 1 AND p.story_id = u.story_id)
    AND NOT EXISTS (
      SELECT 1 FROM stories b WHERE b.id = u.story_id AND b.saved = 1))''';
