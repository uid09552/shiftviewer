// Bulk wish edits: filling a week or a month in one pass, and what the run is
// allowed to skip while doing it.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shiftviewer/services/app_settings.dart';
import 'package:shiftviewer/services/shift_data_controller.dart';

const _base = 'https://example.test/api/v1';

/// Mon 1 June 2026 through Sun 7 June 2026.
final _week = [for (int d = 1; d <= 7; d++) DateTime(2026, 6, d)];

/// An early shift that runs Mon–Fri only, so a weekend day cannot carry it.
final _earlyShift = {
  'id': 'early',
  'name': 'Early',
  'short_name': 'E',
  'color': '#FF0000',
  'order': 1,
  'weekday_times': [
    for (int weekday = 0; weekday < 5; weekday++)
      {
        'weekday': weekday,
        'start_time': '06:00',
        'end_time': '14:00',
        'min_employees': 1,
      },
  ],
};

/// A stand-in server holding wishes in memory, counting what it was asked to do.
class _FakeApi {
  final wishes = <String, Map<String, dynamic>>{};
  var posts = 0;
  var deletes = 0;
  var nextId = 0;

  /// The tenant's wish window, as `GET /wish-settings` reports it.
  Map<String, dynamic> wishSettings = {
    'mode': 'enabled',
    'updated_at': '2026-05-01T00:00:00Z',
  };

  /// Set to fail every write from that point on.
  int? failWritesWith;

  http.Client client() => MockClient((request) async {
        final path = request.url.path.replaceFirst('/api/v1', '');

        if (request.method == 'GET') {
          switch (path) {
            case '/shifts':
              return _json([_earlyShift]);
            case '/employees':
              return _json([
                {'id': 'e1', 'name': 'Ada', 'email': 'ada@example.test'}
              ]);
            case '/workstations':
              return _json([]);
            case '/confirmed-shift-plans':
              return _json({'data': []});
            case '/shift-wishes':
              return _json(wishes.values.toList());
            case '/wish-settings':
              return _json(wishSettings);
          }
          return http.Response('not found', 404);
        }

        final failure = failWritesWith;
        if (failure != null) return http.Response('nope', failure);

        if (request.method == 'POST' && path == '/shift-wishes') {
          posts++;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final created = {'id': 'w${nextId++}', ...body};
          wishes[created['id'] as String] = created;
          return _json(created, status: 201);
        }
        if (request.method == 'DELETE' && path.startsWith('/shift-wishes/')) {
          deletes++;
          wishes.remove(path.split('/').last);
          return http.Response('', 204);
        }
        return http.Response('not found', 404);
      });

  http.Response _json(Object body, {int status = 200}) => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );
}

Future<(ShiftDataController, _FakeApi)> _loaded(
    {Map<String, dynamic>? wishSettings}) async {
  final api = _FakeApi();
  if (wishSettings != null) api.wishSettings = wishSettings;
  final data = ShiftDataController(
    const AppSettings(baseUrl: _base),
    httpClientFactory: api.client,
  );
  await data.refresh(_week.first, _week.last);
  data.selectEmployee('e1');
  return (data, api);
}

void main() {
  test('filling a week skips the days the shift does not run on', () async {
    final (data, api) = await _loaded();

    final result = await data.placeWishes(_week, 'early');

    expect(result.applied, 5, reason: 'Mon–Fri');
    expect(result.skipped, 2, reason: 'Sat + Sun are not Early days');
    expect(result.failure, isNull);
    expect(api.posts, 5);
    expect(data.wishesInRange(_week.first, _week.last).length, 5);
  });

  test('re-applying the same wish costs no requests', () async {
    final (data, api) = await _loaded();
    await data.placeWishes(_week, 'early');

    final again = await data.placeWishes(_week, 'early');

    expect(again.applied, 5);
    expect(api.posts, 5, reason: 'the days already wished for are left alone');
    expect(api.deletes, 0);
  });

  test('a failed write stops the run and reports what got through', () async {
    final (data, api) = await _loaded();
    api.failWritesWith = 500;

    final result = await data.placeWishes(_week, 'early');

    expect(result.applied, 0);
    expect(result.failure?.reason, FailureReason.request);
    expect(result.failure?.statusCode, 500);
  });

  test('withdrawing counts only the days that carried a wish', () async {
    final (data, api) = await _loaded();
    await data.placeWishes(_week, 'early');

    final result = await data.removeWishes(_week);

    expect(result.applied, 5);
    expect(api.deletes, 5, reason: 'the two shift-free days cost no request');
    expect(data.wishesInRange(_week.first, _week.last), isEmpty);
  });

  test('a date range window keeps the days it does not cover untouched',
      () async {
    // Open for Mon 1 – Wed 3 June; the rest of the week is out of reach.
    final (data, api) = await _loaded(wishSettings: const {
      'mode': 'date_range',
      'window_start': '2026-06-01',
      'window_end': '2026-06-03',
      'updated_at': '2026-05-01T00:00:00Z',
    });

    final result = await data.placeWishes(_week, 'early');

    expect(result.applied, 3, reason: 'Mon–Wed');
    expect(result.blocked, 4, reason: 'Thu–Sun fall outside the window');
    expect(result.skipped, 0, reason: 'the shift-free days are blocked first');
    expect(api.posts, 3);
  });

  test('a wish outside the window cannot be withdrawn either', () async {
    final (data, api) = await _loaded();
    await data.placeWishes(_week, 'early');
    // The window shrinks to Mon–Tue after the wishes were placed; the three
    // later ones are locked in for good.
    api.wishSettings = const {
      'mode': 'date_range',
      'window_start': '2026-06-01',
      'window_end': '2026-06-02',
      'updated_at': '2026-05-01T00:00:00Z',
    };
    await data.refresh(_week.first, _week.last);

    final result = await data.removeWishes(_week);

    expect(result.applied, 2, reason: 'Mon + Tue are still open');
    expect(result.blocked, 3, reason: 'Wed–Fri carry a wish but are locked');
    expect(api.deletes, 2);
    expect(data.wishesInRange(_week.first, _week.last).length, 3);
  });

  test('a deactivated window refuses every wish without asking the server',
      () async {
    final (data, api) = await _loaded(wishSettings: const {
      'mode': 'disabled',
      'updated_at': '2026-05-01T00:00:00Z',
    });

    final placed = await data.placeWishes(_week, 'early');
    final removed = await data.removeWishes(_week);

    expect(placed.failure?.reason, FailureReason.wishesClosed);
    expect(removed.failure?.reason, FailureReason.wishesClosed);
    expect(api.posts, 0);
    expect(api.deletes, 0);
    expect(data.wishesOpen, isFalse);
  });

  test('wishes cannot be placed before an employee is chosen', () async {
    final api = _FakeApi();
    final data = ShiftDataController(
      const AppSettings(baseUrl: _base),
      httpClientFactory: api.client,
    );
    await data.refresh(_week.first, _week.last);

    final result = await data.placeWishes(_week, 'early');

    expect(result.failure?.reason, FailureReason.noEmployeeSelected);
    expect(api.posts, 0);
  });
}
