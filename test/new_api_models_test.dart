// The models backing the new backend endpoints (holidays, personal limits,
// the wish-schedule and backend info) decode correctly and round-trip what
// they send back.

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftviewer/models/admin_models.dart';
import 'package:shiftviewer/models/models.dart';

void main() {
  group('HolidayCalendar', () {
    test('decodes holidays and keys them by day', () {
      final calendar = HolidayCalendar.fromJson({
        'state': 'by',
        'enabled': true,
        'holidays': [
          {'date': '2026-01-01', 'name': 'Neujahr', 'state': 'by'},
          {'date': '2026-12-25', 'name': 'Weihnachten'},
        ],
      });
      expect(calendar.enabled, isTrue);
      expect(calendar.holidays, hasLength(2));
      final byDate = calendar.byDate;
      expect(byDate[DateTime(2026, 1, 1)]?.name, 'Neujahr');
      expect(byDate[DateTime(2026, 12, 25)]?.name, 'Weihnachten');
      expect(byDate[DateTime(2026, 6, 1)], isNull);
    });

    test('a non-map response or a disabled deployment yields none', () {
      expect(HolidayCalendar.none.enabled, isFalse);
      expect(HolidayCalendar.none.holidays, isEmpty);
    });
  });

  group('WishSchedule', () {
    test('round-trips through toRequest, server fields left out', () {
      const schedule = WishSchedule(
        enabled: true,
        unit: ScheduleUnit.weeks,
        interval: 2,
        weekday: 4,
        time: '09:30:00',
        openDays: 5,
      );
      final req = schedule.toRequest();
      expect(req['enabled'], isTrue);
      expect(req['unit'], 'weeks');
      expect(req['interval'], 2);
      expect(req['weekday'], 4);
      expect(req['time'], '09:30:00');
      expect(req['open_days'], 5);
      expect(req.containsKey('next_change_at'), isFalse);
    });

    test('decodes the server-reported next-change fields', () {
      final schedule = WishSchedule.fromJson({
        'enabled': true,
        'unit': 'months',
        'interval': 1,
        'weekday': 0,
        'day_of_month': 15,
        'time': '08:00:00',
        'open_days': 7,
        'next_change_at': '2026-11-15T08:00:00Z',
        'next_change_opens': false,
      });
      expect(schedule.unit, ScheduleUnit.months);
      expect(schedule.dayOfMonth, 15);
      expect(schedule.nextChangeAt, isNotNull);
      expect(schedule.nextChangeOpens, isFalse);
    });

    test('an interval carried across units is clamped to the new max', () {
      const weekly = WishSchedule(unit: ScheduleUnit.weeks, interval: 52);
      final monthly = weekly.copyWith(unit: ScheduleUnit.months);
      expect(monthly.interval, 24); // months' max, not weeks' 52
    });
  });

  group('WishSettings.schedule', () {
    test('is null when the deployment never reported one', () {
      final s = WishSettings.fromJson({'mode': 'enabled'});
      expect(s.schedule, isNull);
    });

    test('is parsed when present', () {
      final s = WishSettings.fromJson({
        'mode': 'enabled',
        'schedule': {
          'enabled': false,
          'unit': 'days',
          'interval': 10,
          'weekday': 0,
          'day_of_month': 1,
          'time': '08:00:00',
          'open_days': 3,
        },
      });
      expect(s.schedule?.interval, 10);
    });
  });

  group('PersonalLimits', () {
    test('an employee with nothing saved decodes as empty', () {
      final limits = PersonalLimits.emptyFor('e1');
      expect(limits.isEmpty, isTrue);
      expect(limits.toRequest(), {
        'max_nights_per_month': null,
        'max_weekends_per_month': null,
        'no_night_shifts': false,
        'preferred_days_off': <int>[],
      });
    });

    test('toRequest sends explicit nulls to clear a limit', () {
      final limits = PersonalLimits(
        employeeId: 'e1',
        maxNightsPerMonth: 4,
        preferredDaysOff: const [5, 6],
      ).copyWith(clearMaxNights: true);
      expect(limits.maxNightsPerMonth, isNull);
      expect(limits.toRequest()['max_nights_per_month'], isNull);
      expect(limits.toRequest()['preferred_days_off'], [5, 6]);
      expect(limits.isEmpty, isFalse);
    });

    test('preferred days off are sorted and deduplicated on save', () {
      final limits = PersonalLimits.emptyFor('e1')
          .copyWith(preferredDaysOff: [6, 0, 6, 3]);
      expect(limits.toRequest()['preferred_days_off'], [0, 3, 6]);
    });

    test('out-of-range weekdays from the server are dropped', () {
      final limits = PersonalLimits.fromJson({
        'employee_id': 'e1',
        'no_night_shifts': true,
        'preferred_days_off': [0, 6, 9, -1],
      });
      expect(limits.preferredDaysOff, [0, 6]);
      expect(limits.noNightShifts, isTrue);
    });
  });

  group('BackendInfo', () {
    test('shortens a long commit to seven characters', () {
      final info = BackendInfo.fromJson({
        'name': 'shift-backend',
        'version': '1.4.0',
        'commit': 'fbbbe68c0ffee1234567890',
        'build_date': '2026-09-15T08:00:00Z',
      });
      expect(info.shortCommit, 'fbbbe68');
      expect(info.buildDate, isNotNull);
    });

    test('an empty commit stays empty', () {
      expect(const BackendInfo().shortCommit, '');
    });
  });

  group('ShiftAssignment', () {
    test('a null shift_id decodes as a fixed day off', () {
      final a = ShiftAssignment.fromJson({
        'id': 'a1',
        'employee_id': 'e1',
        'shift_id': null,
        'date': '2026-06-09',
      });
      expect(a.isDayOff, isTrue);
    });
  });
}
