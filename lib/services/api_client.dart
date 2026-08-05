import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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

/// Thin REST client for the Hospital Shift Management API.
///
/// Builds requests from the current [AppSettings] (base URL + auth). Auth uses
/// the bearer token when present, otherwise HTTP basic auth if a username is
/// set; requests are sent unauthenticated when neither is configured.
class ShiftApiClient {
  final AppSettings settings;

  /// OIDC access token from the login flow; takes precedence over the manual
  /// bearer token / basic auth in settings when present.
  final String? accessToken;

  final http.Client _http;

  ShiftApiClient(this.settings, {this.accessToken, http.Client? client})
      : _http = client ?? createHttpClient();

  static final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = settings.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$path').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
  }

  Map<String, String> get _headers {
    final headers = <String, String>{'Accept': 'application/json'};
    final oidc = accessToken?.trim() ?? '';
    if (oidc.isNotEmpty) {
      headers['Authorization'] = 'Bearer $oidc';
      // The backend authenticates off this header (see docs/auth.md); the
      // gateway normally injects it from the session.
      headers['X-Access-Token'] = oidc;
    } else if (settings.bearerToken.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${settings.bearerToken.trim()}';
      headers['X-Access-Token'] = settings.bearerToken.trim();
    } else if (settings.username.trim().isNotEmpty) {
      final creds =
          base64Encode(utf8.encode('${settings.username}:${settings.password}'));
      headers['Authorization'] = 'Basic $creds';
    }
    return headers;
  }

  Future<dynamic> _get(String path, [Map<String, String>? query]) async {
    final http.Response res;
    final headers = _headers;
    final auth = headers['Authorization'];
    debugPrint('[api] GET $path  Authorization=${auth == null ? "MISSING" : "${auth.split(' ').first} len=${auth.length}"}');
    try {
      res = await _http
          .get(_uri(path, query), headers: headers)
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw ApiException('Network error: $e');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      debugPrint('[api] GET $path -> ${res.statusCode}. '
          'www-authenticate=${res.headers['www-authenticate']} '
          'body=${res.body.length > 300 ? res.body.substring(0, 300) : res.body}');
      throw ApiException(
        res.reasonPhrase ?? 'Request failed',
        statusCode: res.statusCode,
      );
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
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
    return _asList(data)
        .map((e) => Workstation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Confirmed shift plans for one employee in `[from, to]`.
  Future<List<ConfirmedShiftPlan>> employeeConfirmedShiftPlans(
    String employeeId,
    DateTime from,
    DateTime to,
  ) async {
    final data = await _get(
      '/employees/$employeeId/confirmed-shift-plans',
      {'from_date': _dateFmt.format(from), 'to_date': _dateFmt.format(to)},
    );
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
    final list = data is Map<String, dynamic> ? _asList(data['data']) : _asList(data);
    return list
        .map((e) => ConfirmedShiftPlan.fromJson(e as Map<String, dynamic>))
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
