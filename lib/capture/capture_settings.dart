import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/policy/capture_scope.dart';
import 'package:page_capture/page_capture.dart';

CaptureOptions captureOptionsFor(
  AppSettings settings, {
  String? filterListsDirectory,
}) => CaptureOptions(
  cleanup: CaptureCleanup(
    blockRequests: settings.adBlocking,
    hideElements: settings.adBlocking,
    rejectConsent: settings.rejectCookiePopups,
  ),
  maxBytes: maxPageBytes,
  filterListsDirectory: filterListsDirectory,
);
