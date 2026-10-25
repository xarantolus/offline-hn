import 'dart:convert';

import 'package:offline_hn/data/model/comment_order.dart';
import 'package:offline_hn/data/model/daily_time.dart';
import 'package:offline_hn/data/model/feed_kind.dart';
import 'package:offline_hn/data/model/filter_list_status.dart';
import 'package:offline_hn/data/model/viewer_kind.dart';
import 'package:offline_hn/data/policy/keep_window.dart';
import 'package:page_capture/filters.dart';

class Setting<T> {
  const Setting(this.key, this.defaultValue, this._decode, this._encode);

  final String key;
  final T defaultValue;
  final T Function(String raw) _decode;
  final String Function(T value) _encode;

  T read(Map<String, String> raw) {
    final stored = raw[key];
    if (stored == null) return defaultValue;
    return _decode(stored);
  }

  String encode(T value) => _encode(value);
}

abstract final class Settings {
  static const gibibyte = 1024 * 1024 * 1024;

  static const dailyTime = Setting<DailyTime>(
    'dailyTime',
    DailyTime(5, 0),
    _decodeDailyTime,
    _encodeDailyTime,
  );

  /// Null switches the periodic run off.
  static const intervalHours = Setting<int?>(
    'intervalHours',
    2,
    _decodeInterval,
    _encodeInterval,
  );

  static const wifiOnly = Setting<bool>(
    'wifiOnly',
    true,
    _decodeBool,
    _encodeBool,
  );

  static const chargingOnly = Setting<bool>(
    'chargingOnly',
    true,
    _decodeBool,
    _encodeBool,
  );

  static const pagesOnMobile = Setting<bool>(
    'pagesOnMobile',
    false,
    _decodeBool,
    _encodeBool,
  );

  static const pageBudgetBytes = Setting<int>(
    'pageBudgetBytes',
    gibibyte,
    int.parse,
    _encodeInt,
  );

  static const commentTextScale = Setting<double>(
    'commentTextScale',
    1,
    double.parse,
    _encodeDouble,
  );

  static const commentOrder = Setting<CommentOrder>(
    'commentOrder',
    CommentOrder.hn,
    _decodeCommentOrder,
    _encodeCommentOrder,
  );

  static const enabledFeeds = Setting<Set<FeedKind>>(
    'enabledFeeds',
    {...FeedKind.values},
    _decodeFeeds,
    _encodeFeeds,
  );

  static const viewer = Setting<ViewerKind>(
    'viewer',
    ViewerKind.customTab,
    _decodeViewer,
    _encodeViewer,
  );

  static const adBlocking = Setting<bool>(
    'adBlocking',
    true,
    _decodeBool,
    _encodeBool,
  );

  static const rejectCookiePopups = Setting<bool>(
    'rejectCookiePopups',
    true,
    _decodeBool,
    _encodeBool,
  );

  static const filterListUrls = Setting<List<String>>(
    'filterListUrls',
    FilterSources.defaultLists,
    _decodeUrls,
    jsonEncode,
  );

  /// Bookkeeping the downloader keeps per filter list URL.
  static const filterListStatus = Setting<Map<String, FilterListStatus>>(
    'filterListStatus',
    {},
    FilterListStatus.decodeAll,
    FilterListStatus.encodeAll,
  );

  static const keepDays = Setting<int>(
    keepDaysKey,
    defaultKeepDays,
    int.parse,
    _encodeInt,
  );

  static const hideReadStories = Setting<bool>(
    'hideReadStories',
    false,
    _decodeBool,
    _encodeBool,
  );

  static const askedForNotifications = Setting<bool>(
    'askedForNotifications',
    false,
    _decodeBool,
    _encodeBool,
  );

  static DailyTime _decodeDailyTime(String raw) =>
      DailyTime.tryParse(raw) ?? (throw FormatException('daily time', raw));

  static String _encodeDailyTime(DailyTime value) => value.encode();

  static const _off = 'off';

  static int? _decodeInterval(String raw) =>
      raw == _off ? null : int.parse(raw);

  static String _encodeInterval(int? value) => value?.toString() ?? _off;

  static bool _decodeBool(String raw) => switch (raw) {
    'true' => true,
    'false' => false,
    _ => throw FormatException('bool', raw),
  };

  static List<String> _decodeUrls(String raw) {
    return List<String>.from(jsonDecode(raw) as List<Object?>);
  }

  static String _encodeBool(bool value) => value.toString();

  static String _encodeInt(int value) => value.toString();

  static String _encodeDouble(double value) => value.toString();

  static Set<FeedKind> _decodeFeeds(String raw) => {
    if (raw.isNotEmpty)
      for (final name in raw.split(',')) FeedKind.values.byName(name),
  };

  static String _encodeFeeds(Set<FeedKind> value) =>
      value.map((kind) => kind.name).join(',');

  static CommentOrder _decodeCommentOrder(String raw) =>
      CommentOrder.values.byName(raw);

  static String _encodeCommentOrder(CommentOrder value) => value.name;

  static ViewerKind _decodeViewer(String raw) {
    for (final kind in ViewerKind.values) {
      if (kind.name == raw) return kind;
    }
    throw FormatException('viewer', raw);
  }

  static String _encodeViewer(ViewerKind value) => value.name;
}

class AppSettings {
  const AppSettings({
    required this.dailyTime,
    required this.intervalHours,
    required this.wifiOnly,
    required this.chargingOnly,
    required this.pagesOnMobile,
    required this.pageBudgetBytes,
    required this.commentTextScale,
    required this.commentOrder,
    required this.enabledFeeds,
    required this.viewer,
    required this.adBlocking,
    required this.rejectCookiePopups,
    required this.filterListUrls,
    required this.filterListStatus,
    required this.keepDays,
    required this.hideReadStories,
  });

  factory AppSettings.defaults() => AppSettings.fromRaw(const {});

  factory AppSettings.fromRaw(Map<String, String> raw) => AppSettings(
    dailyTime: Settings.dailyTime.read(raw),
    intervalHours: Settings.intervalHours.read(raw),
    wifiOnly: Settings.wifiOnly.read(raw),
    chargingOnly: Settings.chargingOnly.read(raw),
    pagesOnMobile: Settings.pagesOnMobile.read(raw),
    pageBudgetBytes: Settings.pageBudgetBytes.read(raw),
    commentTextScale: Settings.commentTextScale.read(raw),
    commentOrder: Settings.commentOrder.read(raw),
    enabledFeeds: Settings.enabledFeeds.read(raw),
    viewer: Settings.viewer.read(raw),
    adBlocking: Settings.adBlocking.read(raw),
    rejectCookiePopups: Settings.rejectCookiePopups.read(raw),
    filterListUrls: Settings.filterListUrls.read(raw),
    filterListStatus: Settings.filterListStatus.read(raw),
    keepDays: readKeepDays(raw),
    hideReadStories: Settings.hideReadStories.read(raw),
  );

  final DailyTime dailyTime;
  final int? intervalHours;
  final bool wifiOnly;
  final bool chargingOnly;
  final bool pagesOnMobile;
  final int pageBudgetBytes;
  final double commentTextScale;
  final CommentOrder commentOrder;
  final Set<FeedKind> enabledFeeds;
  final ViewerKind viewer;
  final bool adBlocking;
  final bool rejectCookiePopups;
  final List<String> filterListUrls;
  final Map<String, FilterListStatus> filterListStatus;
  final int keepDays;
  final bool hideReadStories;
}
