import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/admin_models.dart';
import '../models/models.dart';
import 'app_settings.dart';
import 'http_client_factory.dart';

/// Thrown when an API call fails.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Supplies a currently-valid OIDC access token, renewing it from the refresh
/// token when the current one has run out. `forceRefresh` asks for a renewal
/// even when the cached token still looks valid, which is what the client does
/// after a 401. Returns null when the session cannot be continued.
typedef AccessTokenProvider = Future<String?> Function({bool forceRefresh});

/// Thin REST client for the Hospital Shift Management API.
///
/// Builds requests from the current [AppSettings] (base URL + auth). Auth uses
/// the bearer token when present, otherwise HTTP basic auth if a username is
/// set; requests are sent unauthenticated when neither is configured.
class ShiftApiClient {
  final AppSettings settings;

  /// OIDC access token from the login flow; takes precedence over the manual
  /// bearer token / basic auth in settings when present. Only used when no
  /// [tokenProvider] is given.
  final String? accessToken;

  /// Asked for the access token before every request, so a token that expired
  /// while the app was open is renewed instead of being sent stale.
  final AccessTokenProvider? tokenProvider;

  final http.Client _http;

  ShiftApiClient(
    this.settings, {
    this.accessToken,
    this.tokenProvider,
    http.Client? client,
  }) : _http = client ?? createHttpClient();

  static final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = settings.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse(
      '$base$path',
    ).replace(queryParameters: (query == null || query.isEmpty) ? null : query);
  }

  Future<String?> _resolveToken({required bool forceRefresh}) async {
    final provider = tokenProvider;
    if (provider == null) return accessToken;
    return provider(forceRefresh: forceRefresh);
  }

  Future<Map<String, String>> _buildHeaders({bool forceRefresh = false}) async {
    final headers = <String, String>{'Accept': 'application/json'};
    final oidc = (await _resolveToken(forceRefresh: forceRefresh))?.trim() ?? '';
    if (oidc.isNotEmpty) {
      headers['Authorization'] = 'Bearer $oidc';
      // The backend authenticates off this header (see docs/auth.md); the
      // gateway normally injects it from the session.
      headers['X-Access-Token'] = oidc;
    } else if (settings.bearerToken.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${settings.bearerToken.trim()}';
      headers['X-Access-Token'] = settings.bearerToken.trim();
    } else if (settings.username.trim().isNotEmpty) {
      final creds = base64Encode(
        utf8.encode('${settings.username}:${settings.password}'),
      );
      headers['Authorization'] = 'Basic $creds';
    }
    return headers;
  }

  /// Runs [attempt] with fresh auth headers, and once more with a renewed
  /// access token when the server answers 401.
  ///
  /// An expired access token is an ordinary event in a long-lived session, not
  /// a reason to send the user back to sign in: the second attempt carries the
  /// token the refresh produced. When the renewal yields nothing new — no
  /// refresh token, or the server refused it — the 401 stands and the auth
  /// layer has already ended the session.
  Future<http.Response> _withAuthRetry(
    Future<http.Response> Function(Map<String, String> headers) attempt,
  ) async {
    final headers = await _buildHeaders();
    final res = await attempt(headers);
    if (res.statusCode != 401 || tokenProvider == null) return res;

    debugPrint('[api] 401 -> renewing the access token and retrying once');
    final renewed = await _buildHeaders(forceRefresh: true);
    if (renewed['Authorization'] == headers['Authorization']) return res;
    return attempt(renewed);
  }

  Future<dynamic> _get(String path, [Map<String, String>? query]) async {
    final http.Response res;
    try {
      res = await _withAuthRetry((headers) {
        final auth = headers['Authorization'];
        debugPrint(
          '[api] GET $path  Authorization=${auth == null ? "MISSING" : "${auth.split(' ').first} len=${auth.length}"}',
        );
        return _http
            .get(_uri(path, query), headers: headers)
            .timeout(const Duration(seconds: 15));
      });
    } catch (e) {
      throw ApiException('Network error: $e');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      debugPrint(
        '[api] GET $path -> ${res.statusCode}. '
        'www-authenticate=${res.headers['www-authenticate']} '
        'body=${res.body.length > 300 ? res.body.substring(0, 300) : res.body}',
      );
      throw ApiException(
        res.reasonPhrase ?? 'Request failed',
        statusCode: res.statusCode,
      );
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  /// Sends a body-carrying or bodyless write request and decodes the response.
  Future<dynamic> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
    Map<String, String>? query,
  ]) async {
    final http.Response res;
    try {
      // A sent request cannot be re-sent, so each attempt builds its own.
      res = await _withAuthRetry((headers) async {
        final request = http.Request(method, _uri(path, query))
          ..headers.addAll(headers);
        if (body != null) {
          request.headers['Content-Type'] = 'application/json';
          request.body = jsonEncode(body);
        }
        final streamed = await _http
            .send(request)
            .timeout(const Duration(seconds: 15));
        return http.Response.fromStream(streamed);
      });
    } catch (e) {
      throw ApiException('Network error: $e');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      debugPrint(
        '[api] $method $path -> ${res.statusCode} '
        'body=${res.body.length > 300 ? res.body.substring(0, 300) : res.body}',
      );
      throw ApiException(
        _errorText(res) ?? res.reasonPhrase ?? 'Request failed',
        statusCode: res.statusCode,
      );
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  /// GET [path] under the API base and decode the JSON body. For the
  /// management screens, whose endpoints live in `admin_api.dart`.
  Future<dynamic> getJson(String path, [Map<String, String>? query]) =>
      _get(path, query);

  /// POST/PUT/PATCH/DELETE [path] with an optional JSON body and query.
  Future<dynamic> sendJson(
    String method,
    String path, [
    Map<String, dynamic>? body,
    Map<String, String>? query,
  ]) => _send(method, path, body, query);

  /// The assistant (agent) service, which the gateway serves at `/agent`
  /// beside the API's `/api/v1`. Null when the base URL does not end in
  /// `/api/v1`, since the agent's address cannot be derived then.
  Uri? agentUri(String path) {
    final base = settings.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (!base.endsWith('/api/v1')) return null;
    final root = base.substring(0, base.length - '/api/v1'.length);
    return Uri.parse('$root/agent$path');
  }

  /// POST a JSON body to the assistant service; see [agentUri]. Plan checks
  /// take a while, so the timeout is generous.
  Future<dynamic> postAgent(String path, Map<String, dynamic> body) async {
    final uri = agentUri(path);
    if (uri == null) {
      throw ApiException('Assistant address unknown for this API base URL');
    }
    final http.Response res;
    try {
      res = await _withAuthRetry((headers) async {
        return _http
            .post(
              uri,
              headers: {...headers, 'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(minutes: 5));
      });
    } catch (e) {
      throw ApiException('Network error: $e');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        _errorText(res) ?? res.reasonPhrase ?? 'Request failed',
        statusCode: res.statusCode,
      );
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  /// The `error`/`message` the backend puts in a failed response's JSON body,
  /// which says far more than the status line ("Workstation is closed on …").
  static String? _errorText(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        final text = body['error'] ?? body['message'] ?? body['detail'];
        if (text is String && text.trim().isNotEmpty) return text.trim();
      }
    } catch (_) {}
    return null;
  }

  /// Lightweight connectivity/auth check used by the settings screen.
  Future<void> ping() async {
    await _get('/shifts');
  }

  /// All shifts defined in the system.
  Future<List<Shift>> listShifts() async {
    final data = await _get('/shifts');
    final list = _asList(data);
    return list.map((e) => Shift.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// First page of employees.
  Future<List<Employee>> listEmployees({int limit = 100}) async {
    final data = await _get('/employees', {'limit': '$limit'});
    final list = _asList(data);
    return list
        .map((e) => Employee.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Employee> getEmployee(String employeeId) async {
    final data = await _get('/employees/$employeeId');
    return Employee.fromJson(data as Map<String, dynamic>);
  }

  /// All workstations.
  Future<List<Workstation>> listWorkstations() async {
    final data = await _get('/workstations');
    return _asList(
      data,
    ).map((e) => Workstation.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Confirmed shift plans for one employee in `[from, to]`.
  Future<List<ConfirmedShiftPlan>> employeeConfirmedShiftPlans(
    String employeeId,
    DateTime from,
    DateTime to,
  ) async {
    final data = await _get('/employees/$employeeId/confirmed-shift-plans', {
      'from_date': _dateFmt.format(from),
      'to_date': _dateFmt.format(to),
    });
    return _asList(data)
        .map((e) => ConfirmedShiftPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Confirmed shift plans across all employees in `[from, to]`.
  Future<List<ConfirmedShiftPlan>> confirmedShiftPlans(
    DateTime from,
    DateTime to,
  ) async {
    final data = await _get('/confirmed-shift-plans', {
      'from_date': _dateFmt.format(from),
      'to_date': _dateFmt.format(to),
      'limit': '500',
    });
    // This endpoint returns a paginated envelope: { data, total, limit, offset }.
    final list = data is Map<String, dynamic>
        ? _asList(data['data'])
        : _asList(data);
    return list
        .map((e) => ConfirmedShiftPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// The tenant's shift-wish window: whether, and for which dates, employees
  /// may place wishes. Readable by every role — the UI needs it to decide
  /// whether to offer the wish picker at all.
  Future<WishSettings> getWishSettings() async {
    final data = await _get('/wish-settings');
    return WishSettings.fromJson(data as Map<String, dynamic>);
  }

  /// Public holidays of the configured state in `[from, to]`.
  ///
  /// Years the backend has not stored yet are fetched from its holiday API on
  /// the way, so the first call for a new year can be slow. A deployment with
  /// holidays switched off answers with `enabled: false` and no days.
  Future<HolidayCalendar> holidays(DateTime from, DateTime to) async {
    final data = await _get('/holidays', {
      'from': _dateFmt.format(from),
      'to': _dateFmt.format(to),
    });
    return data is Map<String, dynamic>
        ? HolidayCalendar.fromJson(data)
        : HolidayCalendar.none;
  }

  /// Version, commit and build date of the backend being talked to. Useful
  /// when a bug report has to name which deployment produced it.
  Future<BackendInfo> info() async {
    final data = await _get('/info');
    return data is Map<String, dynamic>
        ? BackendInfo.fromJson(data)
        : const BackendInfo();
  }

  /// Shift wishes in `[from, to]`, optionally for a single employee.
  Future<List<ShiftWish>> listShiftWishes(
    DateTime from,
    DateTime to, {
    String? employeeId,
  }) async {
    final data = await _get('/shift-wishes', {
      'employee_id': ?employeeId,
      'from_date': _dateFmt.format(from),
      'to_date': _dateFmt.format(to),
    });
    return _asList(
      data,
    ).map((e) => ShiftWish.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Places a wish. Fails with status 409 when the employee already wishes for
  /// something on [date] — delete that wish first to replace it.
  Future<ShiftWish> createShiftWish({
    required String employeeId,
    required String shiftId,
    required DateTime date,
  }) async {
    final data = await _send('POST', '/shift-wishes', {
      'employee_id': employeeId,
      'shift_id': shiftId,
      'wish_date': _dateFmt.format(date),
    });
    return ShiftWish.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteShiftWish(String wishId) async {
    await _send('DELETE', '/shift-wishes/$wishId');
  }

  /// Who works each day in `[from, to]` and how many, split per shift —
  /// `GET /analysis/staffing-per-day`.
  Future<List<DailyStaffing>> staffingPerDay(DateTime from, DateTime to) async {
    final data = await _get('/analysis/staffing-per-day', {
      'from_date': _dateFmt.format(from),
      'to_date': _dateFmt.format(to),
    });
    return _asList(
      data,
    ).map((e) => DailyStaffing.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Planned hours per day per workstation in `[from, to]`.
  Future<List<WorkstationDailyHours>> plannedHoursPerWorkstation(
    DateTime from,
    DateTime to,
  ) async {
    final data = await _get('/analysis/planned-hours-per-day-per-workstation', {
      'from_date': _dateFmt.format(from),
      'to_date': _dateFmt.format(to),
    });
    return _asList(data)
        .map((e) => WorkstationDailyHours.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Planned head count per day per workstation in `[from, to]`.
  Future<List<WorkstationDailyEmployees>> plannedEmployeesPerWorkstation(
    DateTime from,
    DateTime to,
  ) async {
    final data = await _get(
      '/analysis/planned-employees-per-day-per-workstation',
      {'from_date': _dateFmt.format(from), 'to_date': _dateFmt.format(to)},
    );
    return _asList(data)
        .map(
          (e) => WorkstationDailyEmployees.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return data['data'] as List;
    }
    return const [];
  }

  void close() => _http.close();
}
