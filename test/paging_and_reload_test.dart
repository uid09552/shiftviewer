// Lists that span several pages are read in full, and a reload overtaken by a
// newer one cannot paint its older range over it.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shiftviewer/services/api_client.dart';
import 'package:shiftviewer/services/app_settings.dart';
import 'package:shiftviewer/services/shift_data_controller.dart';

const _base = 'https://example.test/api/v1';
const _settings = AppSettings(baseUrl: _base);

http.Response _json(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);

String _d(DateTime d) =>
    '${d.year}-${'${d.month}'.padLeft(2, '0')}-${'${d.day}'.padLeft(2, '0')}';

/// [count] roster entries spread over the first days of June 2026.
List<Map<String, dynamic>> _plans(int count, {String prefix = 'p'}) => [
  for (var i = 0; i < count; i++)
    {
      'id': '$prefix$i',
      'employee_id': 'e${i % 60}',
      'shift_id': 's1',
      'date': _d(DateTime(2026, 6, 1 + i % 28)),
      'is_present': true,
    },
];

/// Answers a `limit`/`offset` list request out of [all] the way the backend
/// does: `{ data, total, limit, offset }`.
http.Response _page(http.Request req, List<Object> all) {
  final limit = int.parse(req.url.queryParameters['limit'] ?? '50');
  final offset = int.parse(req.url.queryParameters['offset'] ?? '0');
  final end = (offset + limit).clamp(0, all.length);
  return _json({
    'data': offset >= all.length ? <Object>[] : all.sublist(offset, end),
    'total': all.length,
    'limit': limit,
    'offset': offset,
  });
}

void main() {
  group('paging', () {
    test('every page of the roster is read, not just the first', () async {
      final all = _plans(2500);
      final offsets = <String?>[];
      final client = ShiftApiClient(
        _settings,
        client: MockClient((req) async {
          offsets.add(req.url.queryParameters['offset']);
          expect(req.url.queryParameters['from_date'], '2026-06-01');
          return _page(req, all);
        }),
      );

      final plans = await client.confirmedShiftPlans(
        DateTime(2026, 6, 1),
        DateTime(2026, 7, 12),
      );

      expect(plans.length, 2500);
      expect(plans.map((p) => p.id).toSet().length, 2500);
      expect(offsets, ['0', '1000', '2000']);
    });

    test('a list that fits exactly into one page costs one request', () async {
      final all = _plans(1000);
      var requests = 0;
      final client = ShiftApiClient(
        _settings,
        client: MockClient((req) async {
          requests++;
          return _page(req, all);
        }),
      );

      final plans = await client.confirmedShiftPlans(
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 30),
      );

      expect(plans.length, 1000);
      expect(requests, 1, reason: 'total says there is nothing more');
    });

    test('employees past the first hundred are listed', () async {
      final all = [
        for (var i = 0; i < 250; i++)
          {'id': 'e$i', 'name': 'Person $i', 'email': 'p$i@example.test'},
      ];
      final client = ShiftApiClient(
        _settings,
        client: MockClient((req) async => _page(req, all)),
      );

      final employees = await client.listEmployees(pageSize: 100);

      expect(employees.length, 250);
      expect(employees.last.id, 'e249');
    });

    test('an endpoint answering a bare list is read once', () async {
      var requests = 0;
      final client = ShiftApiClient(
        _settings,
        client: MockClient((req) async {
          requests++;
          return _json([
            {'id': 'e1', 'name': 'Ada', 'email': 'ada@example.test'},
          ]);
        }),
      );

      final employees = await client.listEmployees(pageSize: 1);

      expect(employees.single.id, 'e1');
      expect(requests, 1);
    });

    test(
      'a server that ignores offset cannot keep the client looping',
      () async {
        var requests = 0;
        final client = ShiftApiClient(
          _settings,
          client: MockClient((req) async {
            requests++;
            // Always the same full page, and no total to stop on.
            return _json({'data': _plans(10)});
          }),
        );

        await client.getAllPages('/confirmed-shift-plans', pageSize: 10);

        expect(requests, ShiftApiClient.maxPages);
      },
    );
  });

  group('overlapping reloads', () {
    final june = (DateTime(2026, 6, 1), DateTime(2026, 6, 7));
    final july = (DateTime(2026, 7, 6), DateTime(2026, 7, 12));

    /// A backend whose roster answer for each `from_date` waits for the test
    /// to release it, so loads can be made to finish in any order.
    (ShiftDataController, Map<String, Completer<void>>) setUp() {
      final gates = {
        _d(june.$1): Completer<void>(),
        _d(july.$1): Completer<void>(),
      };
      final data = ShiftDataController(
        _settings,
        httpClientFactory: () => MockClient((req) async {
          final path = req.url.path.replaceFirst('/api/v1', '');
          if (path == '/confirmed-shift-plans') {
            final from = req.url.queryParameters['from_date']!;
            await gates[from]!.future;
            return _json({
              'data': [
                {
                  'id': 'plan-$from',
                  'employee_id': 'e1',
                  'shift_id': 's1',
                  'date': from,
                  'is_present': true,
                },
              ],
              'total': 1,
            });
          }
          if (path == '/employees') {
            return _json([
              {'id': 'e1', 'name': 'Ada', 'email': 'ada@example.test'},
            ]);
          }
          if (path == '/wish-settings') {
            return _json({'mode': 'enabled'});
          }
          return _json(<Object>[]);
        }),
      );
      return (data, gates);
    }

    test('an older load that finishes last is dropped', () async {
      final (data, gates) = setUp();

      final first = data.refresh(june.$1, june.$2);
      final second = data.refresh(july.$1, july.$2);
      gates[_d(july.$1)]!.complete();
      await second;
      gates[_d(june.$1)]!.complete();
      await first;

      expect(data.loadedFrom, july.$1);
      expect(data.allPlansForDay(july.$1).single.id, 'plan-${_d(july.$1)}');
      expect(
        data.allPlansForDay(june.$1),
        isEmpty,
        reason: 'June was asked for first and must not overwrite July',
      );
      expect(data.loading, isFalse);
    });

    test('the spinner stays until the latest load is in', () async {
      final (data, gates) = setUp();

      final first = data.refresh(june.$1, june.$2);
      final second = data.refresh(july.$1, july.$2);
      gates[_d(june.$1)]!.complete();
      await first;

      expect(data.loading, isTrue, reason: 'July is still on its way');
      expect(data.loadedFrom, isNull);

      gates[_d(july.$1)]!.complete();
      await second;
      expect(data.loading, isFalse);
      expect(data.loadedFrom, july.$1);
    });

    test('lastUpdated is stamped by a successful load only', () async {
      final (data, gates) = setUp();
      expect(data.lastUpdated, isNull);

      final load = data.refresh(june.$1, june.$2);
      expect(data.lastUpdated, isNull, reason: 'nothing has arrived yet');
      gates[_d(june.$1)]!.complete();
      await load;

      final stamped = data.lastUpdated;
      expect(stamped, isNotNull);
      expect(DateTime.now().difference(stamped!).inSeconds, lessThan(5));
    });
  });
}
