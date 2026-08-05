import 'package:flutter/material.dart';

/// Data models mirroring the Hospital Shift Management API
/// (see backend/api/openapi.yaml). Only the fields the viewer needs are
/// modelled; unknown fields are ignored on decode.

/// Parses a `#RRGGBB` hex string into a [Color]. Falls back to grey.
Color parseHexColor(String? hex) {
  if (hex == null) return const Color(0xFF9E9E9E);
  var value = hex.replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? const Color(0xFF9E9E9E) : Color(parsed);
}

class WeekdayTime {
  final int weekday; // 0 = Monday ... 6 = Sunday
  final String startTime;
  final String endTime;
  final int minEmployees;
  final int? maxEmployees;

  const WeekdayTime({
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.minEmployees,
    this.maxEmployees,
  });

  factory WeekdayTime.fromJson(Map<String, dynamic> json) => WeekdayTime(
        weekday: (json['weekday'] as num?)?.toInt() ?? 0,
        startTime: json['start_time'] as String? ?? '',
        endTime: json['end_time'] as String? ?? '',
        minEmployees: (json['min_employees'] as num?)?.toInt() ?? 0,
        maxEmployees: (json['max_employees'] as num?)?.toInt(),
      );
}

class Shift {
  final String id;
  final String name;
  final String shortName;
  final String color;
  final int order;
  final List<WeekdayTime> weekdayTimes;

  const Shift({
    required this.id,
    required this.name,
    required this.shortName,
    required this.color,
    required this.order,
    required this.weekdayTimes,
  });

  Color get displayColor => parseHexColor(color);

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        shortName: json['short_name'] as String? ?? '',
        color: json['color'] as String? ?? '#9E9E9E',
        order: (json['order'] as num?)?.toInt() ?? 0,
        weekdayTimes: (json['weekday_times'] as List<dynamic>? ?? [])
            .map((e) => WeekdayTime.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Times configured for a given [DateTime]'s weekday, if any.
  WeekdayTime? timesFor(DateTime date) {
    final wd = date.weekday - 1; // DateTime: Mon=1..Sun=7 -> 0..6
    for (final t in weekdayTimes) {
      if (t.weekday == wd) return t;
    }
    return null;
  }
}

class Employee {
  final String id;
  final String name;
  final String email;
  final double monthlyWorkingHours;
  final List<Shift> availableShifts;
  final List<Capability> capabilities;

  const Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.monthlyWorkingHours,
    this.availableShifts = const [],
    this.capabilities = const [],
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        monthlyWorkingHours:
            (json['monthly_working_hours'] as num?)?.toDouble() ?? 0,
        availableShifts: (json['available_shifts'] as List<dynamic>? ?? [])
            .map((e) => Shift.fromJson(e as Map<String, dynamic>))
            .toList(),
        capabilities: (json['capabilities'] as List<dynamic>? ?? [])
            .map((e) => Capability.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Capability {
  final String id;
  final String name;

  const Capability({required this.id, required this.name});

  factory Capability.fromJson(Map<String, dynamic> json) => Capability(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
}

class Workstation {
  final String id;
  final String name;
  final bool available;
  final String? activeShiftId;

  const Workstation({
    required this.id,
    required this.name,
    required this.available,
    this.activeShiftId,
  });

  factory Workstation.fromJson(Map<String, dynamic> json) => Workstation(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        available: json['available'] as bool? ?? true,
        activeShiftId: json['active_shift_id'] as String?,
      );
}

/// A confirmed shift plan entry — the actual roster for an employee on a date.
class ConfirmedShiftPlan {
  final String id;
  final String employeeId;
  final String? shiftId;
  final String? workstationId;
  final DateTime date;
  final bool isPresent;
  final String? absenceType;
  final String creationType;

  const ConfirmedShiftPlan({
    required this.id,
    required this.employeeId,
    required this.shiftId,
    required this.workstationId,
    required this.date,
    required this.isPresent,
    required this.absenceType,
    required this.creationType,
  });

  factory ConfirmedShiftPlan.fromJson(Map<String, dynamic> json) =>
      ConfirmedShiftPlan(
        id: json['id'] as String? ?? '',
        employeeId: json['employee_id'] as String? ?? '',
        shiftId: json['shift_id'] as String?,
        workstationId: json['workstation_id'] as String?,
        date: DateTime.parse(json['date'] as String),
        isPresent: json['is_present'] as bool? ?? true,
        absenceType: json['absence_type'] as String?,
        creationType: json['creation_type'] as String? ?? 'manual',
      );
}
