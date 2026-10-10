import 'package:flutter_test/flutter_test.dart';
import 'package:offline_hn/data/model/settings.dart';
import 'package:offline_hn/data/model/sync_enums.dart';
import 'package:offline_hn/data/policy/network_policy.dart';
import 'package:offline_hn/data/policy/staleness.dart';
import 'package:offline_hn/data/policy/run_policy.dart';

AppSettings _settings({bool wifiOnly = true, bool pagesOnMobile = false}) =>
    AppSettings.fromRaw({
      Settings.wifiOnly.key: '$wifiOnly',
      Settings.pagesOnMobile.key: '$pagesOnMobile',
    });

SyncAllowance _decide(
  SyncTrigger trigger,
  ConnectionKind connection,
  AppSettings settings,
) =>
    syncAllowance(trigger: trigger, connection: connection, settings: settings);

void main() {
  test('no connection allows nothing, whatever the trigger', () {
    for (final trigger in SyncTrigger.values) {
      expect(
        _decide(trigger, ConnectionKind.none, _settings(wifiOnly: false)),
        SyncAllowance.nothing,
      );
    }
  });

  test('Wi-Fi allows text and pages for every sync trigger', () {
    for (final trigger in [
      SyncTrigger.scheduled,
      SyncTrigger.periodic,
      SyncTrigger.catchUp,
      SyncTrigger.manual,
    ]) {
      expect(
        _decide(trigger, ConnectionKind.wifi, _settings()),
        SyncAllowance.textAndPages,
      );
    }
  });

  test('automatic runs on mobile data wait for Wi-Fi by default', () {
    for (final trigger in [
      SyncTrigger.scheduled,
      SyncTrigger.periodic,
      SyncTrigger.catchUp,
    ]) {
      expect(
        _decide(trigger, ConnectionKind.mobile, _settings()),
        SyncAllowance.nothing,
      );
    }
  });

  test('a manual fetch on mobile data still gets text, but not pages', () {
    expect(
      _decide(SyncTrigger.manual, ConnectionKind.mobile, _settings()),
      SyncAllowance.textOnly,
    );
  });

  test('mobile data allowed: text only until pages on mobile is also on', () {
    expect(
      _decide(
        SyncTrigger.periodic,
        ConnectionKind.mobile,
        _settings(wifiOnly: false),
      ),
      SyncAllowance.textOnly,
    );
    expect(
      _decide(
        SyncTrigger.periodic,
        ConnectionKind.mobile,
        _settings(wifiOnly: false, pagesOnMobile: true),
      ),
      SyncAllowance.textAndPages,
    );
  });

  test('pages on mobile does not override Wi-Fi only for automatic runs', () {
    expect(
      _decide(
        SyncTrigger.scheduled,
        ConnectionKind.mobile,
        _settings(pagesOnMobile: true),
      ),
      SyncAllowance.nothing,
    );
  });

  test('a manual fetch may take pages on mobile when the user opted in', () {
    expect(
      _decide(
        SyncTrigger.manual,
        ConnectionKind.mobile,
        _settings(pagesOnMobile: true),
      ),
      SyncAllowance.textAndPages,
    );
  });

  test('filter lists are never pages', () {
    expect(
      _decide(SyncTrigger.filterLists, ConnectionKind.wifi, _settings()),
      SyncAllowance.textOnly,
    );
    expect(
      _decide(
        SyncTrigger.filterLists,
        ConnectionKind.mobile,
        _settings(pagesOnMobile: true),
      ),
      SyncAllowance.textOnly,
    );
  });

  group('staleness', () {
    final now = DateTime.utc(2026, 10, 10, 12);

    test('never synced is stale', () {
      expect(isStale(null, now), isTrue);
    });

    test('fresh up to two hours, stale after', () {
      expect(
        isStale(now.subtract(const Duration(hours: 1, minutes: 59)), now),
        isFalse,
      );
      expect(
        isStale(now.subtract(const Duration(hours: 2, minutes: 1)), now),
        isTrue,
      );
    });

    test('a sync dated in the future (clock set back) is stale', () {
      expect(isStale(now.add(const Duration(hours: 1)), now), isTrue);
    });
  });

  group('resuming a run', () {
    final now = DateTime.utc(2026, 10, 10, 12);

    test('a recent unfinished run is continued, an old one is not', () {
      expect(
        canResumeRun(now.subtract(const Duration(minutes: 20)), now),
        isTrue,
      );
      expect(
        canResumeRun(now.subtract(const Duration(hours: 10)), now),
        isFalse,
      );
    });
  });
}
