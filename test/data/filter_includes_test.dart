import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:page_capture/filters.dart';

http.Client _server(Map<String, String> files, List<String> asked) =>
    MockClient((request) async {
      asked.add(request.url.toString());
      final body = files[request.url.toString()];
      return body == null ? http.Response('', 404) : http.Response(body, 200);
    });

void main() {
  const base = 'https://lists.example/filters/main.txt';

  test('an include is replaced by the file it names, in place', () async {
    final asked = <String>[];
    final client = _server({
      base: '! head\n||a.example^\n!#include more.txt\n||z.example^\n',
      'https://lists.example/filters/more.txt': '||b.example^\n',
    }, asked);
    final text = await FilterSources.downloadList(client, base);
    expect(text.split('\n').where((l) => l.startsWith('||')).toList(), [
      '||a.example^',
      '||b.example^',
      '||z.example^',
    ]);
  });

  test('a list without includes is fetched once', () async {
    final asked = <String>[];
    final client = _server({base: '||a.example^\n'}, asked);
    await FilterSources.downloadList(client, base);
    expect(asked, [base]);
  });

  test('an include on another host is refused', () async {
    final client = _server({
      base: '!#include https://elsewhere.example/x.txt\n',
    }, []);
    expect(
      FilterSources.downloadList(client, base),
      throwsA(isA<FilterListException>()),
    );
  });

  test('a missing include fails the whole list', () async {
    final client = _server({base: '!#include gone.txt\n||a.example^\n'}, []);
    expect(
      FilterSources.downloadList(client, base),
      throwsA(isA<FilterListException>()),
    );
  });

  test('includes inside an included file are left alone', () async {
    final asked = <String>[];
    final client = _server({
      base: '!#include one.txt\n',
      'https://lists.example/filters/one.txt': '!#include two.txt\n||a^\n',
    }, asked);
    await FilterSources.downloadList(client, base);
    expect(asked, hasLength(2));
  });

  test('every default list has a name, in the same order', () {
    expect(
      FilterSources.defaultNames.keys.toList(),
      FilterSources.defaultLists,
    );
  });
}
