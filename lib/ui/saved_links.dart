import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:offline_hn/data/policy/link_scope.dart';

/// The addresses that have a saved copy, for the links in the comments below.
class SavedLinks extends InheritedWidget {
  const SavedLinks({super.key, required this.urls, required super.child});

  final Set<String> urls;

  static bool has(BuildContext context, Uri uri) =>
      context.dependOnInheritedWidgetOfExactType<SavedLinks>()?.urls.contains(
        linkKey(uri),
      ) ??
      false;

  @override
  bool updateShouldNotify(SavedLinks oldWidget) =>
      !setEquals(urls, oldWidget.urls);
}
