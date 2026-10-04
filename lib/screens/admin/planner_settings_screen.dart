import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_helpers.dart';
import '../../models/admin_models.dart';
import 'admin_common.dart';

/// Five steps per soft weight, from off to very strong — the web UI's scales,
/// so a value set there shows as the same level here.
const weightScales = <String, List<int>>{
  'equality_weight': [0, 10000, 50000, 120000, 300000],
  'monthly_hours_target_weight': [0, 200, 1000, 3000, 8000],
  'weekly_hours_target_weight': [0, 200, 1000, 3000, 8000],
  'wish_weight': [0, 5000, 20000, 50000, 120000],
  'preference_weight': [0, 100, 300, 900, 2500],
  'skill_downgrade_weight': [0, 50, 200, 600, 1500],
  'fatigue_weight': [0, 30, 100, 300, 800],
  'shift_continuity_weight': [0, 150, 500, 1500, 4000],
  'shift_continuity_week_bonus': [0, 600, 2000, 6000, 15000],
};

const _priorityPresets = <String, PriorityWeights>{
  'ignore': PriorityWeights(high: 1000, medium: 1000, low: 1000),
  'soft': PriorityWeights(high: 3000, medium: 1000, low: 300),
  'balanced': PriorityWeights(high: 10000, medium: 1000, low: 100),
  'strict': PriorityWeights(high: 100000, medium: 1000, low: 10),
};

const _nightFatigue = <num>[1, 1.5, 2, 3];

const _solverEfforts = <String, (int, int)>{
  'quick': (30, 4),
  'balanced': (120, 8),
  'thorough': (300, 16),
};

const Map<String, dynamic> _balanced = {
  'night_shift_recovery_days': 2,
  'min_rest_hours': 11,
  'max_consecutive_days': 6,
  'max_working_days_per_week': 5,
  'equality_weight': 50000,
  'priority_weights': {'high': 10000, 'medium': 1000, 'low': 100},
  'monthly_hours_target_weight': 1000,
  'weekly_min_hours': null,
  'weekly_max_hours': null,
  'weekly_hours_target_weight': 1000,
  'preference_weight': 300,
  'wish_weight': 20000,
  'skill_downgrade_weight': 200,
  'fatigue_weight': 100,
  'night_shift_fatigue_multiplier': 2,
  'shift_continuity_weight': 500,
  'shift_continuity_week_bonus': 2000,
  'min_staffing_mode': 'soft',
  'personal_limits_mode': 'hard',
};

/// Use-case presets: each fills every planning value, never solver effort or
/// whether rotations are kept.
final Map<String, Map<String, dynamic>> useCaseTemplates = {
  'balanced': _balanced,
  'fairness': {
    ..._balanced,
    'equality_weight': 120000,
    'monthly_hours_target_weight': 3000,
    'wish_weight': 5000,
    'shift_continuity_weight': 150,
    'shift_continuity_week_bonus': 600,
    'fatigue_weight': 300,
    'priority_weights': {'high': 3000, 'medium': 1000, 'low': 300},
  },
  'wishes': {
    ..._balanced,
    'wish_weight': 120000,
    'preference_weight': 900,
    'equality_weight': 10000,
  },
  'coverage': {
    ..._balanced,
    'priority_weights': {'high': 100000, 'medium': 1000, 'low': 10},
    'equality_weight': 10000,
    'monthly_hours_target_weight': 200,
    'wish_weight': 5000,
    'preference_weight': 100,
    'skill_downgrade_weight': 50,
    'fatigue_weight': 30,
    'night_shift_recovery_days': 1,
    'min_rest_hours': 10,
    'max_consecutive_days': 7,
    'max_working_days_per_week': 6,
  },
  'stability': {
    ..._balanced,
    'shift_continuity_weight': 4000,
    'shift_continuity_week_bonus': 15000,
    'skill_downgrade_weight': 600,
  },
  'wellbeing': {
    ..._balanced,
    'fatigue_weight': 800,
    'night_shift_fatigue_multiplier': 3,
    'night_shift_recovery_days': 3,
    'min_rest_hours': 12,
    'max_consecutive_days': 5,
    'equality_weight': 120000,
    'wish_weight': 50000,
    'preference_weight': 900,
    'shift_continuity_weight': 1500,
    'shift_continuity_week_bonus': 6000,
    'weekly_max_hours': 45,
    'priority_weights': {'high': 3000, 'medium': 1000, 'low': 300},
  },
};

/// How the optimizer weighs coverage, fairness, rest and wishes for this
/// tenant. Presets for the common goals, five-step levels per weight, and the
/// raw numbers behind an "expert" switch.
class PlannerSettingsScreen extends StatefulWidget {
  const PlannerSettingsScreen({super.key});

  @override
  State<PlannerSettingsScreen> createState() => _PlannerSettingsScreenState();
}

class _PlannerSettingsScreenState extends State<PlannerSettingsScreen>
    with AdminApiState<PlannerSettingsScreen> {
  PlannerSettings? _saved;
  PlannerSettings? _draft;
  bool _loading = true;
  bool _saving = false;
  bool _expert = false;
  Object? _error;

  /// Bumped whenever values change from outside the number fields (a preset,
  /// a level, a reload), so those fields re-read their text; typing into one
  /// does not, which keeps its focus and cursor.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await api.plannerSettings();
      if (mounted) {
        setState(() {
          _saved = _draft = s;
          _generation++;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final s = await api.savePlannerSettings(_draft!);
      if (!mounted) return;
      setState(() {
        _saved = _draft = s;
        _generation++;
      });
      showAdminMessage(context, context.l10n.admSaved);
    } catch (e) {
      if (mounted) showAdminError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _set(String key, Object? value) => _apply({key: value});

  void _apply(Map<String, dynamic> changes) => setState(() {
    _draft = _draft!.copyWith(changes);
    _generation++;
  });

  bool get _dirty {
    final a = _saved?.toRequest();
    final b = _draft?.toRequest();
    if (a == null || b == null) return false;
    return a.toString() != b.toString();
  }

  String? get _activeTemplate {
    final d = _draft!.values;
    for (final entry in useCaseTemplates.entries) {
      final matches = entry.value.entries.every((kv) {
        final v = d[kv.key];
        if (kv.value is Map) {
          return PriorityWeights.fromJson(kv.value as Map<String, dynamic>) ==
              PriorityWeights.fromJson(v as Map<String, dynamic>?);
        }
        return v is num && kv.value is num ? v == kv.value : v == kv.value;
      });
      if (matches) return entry.key;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await confirmAction(
          context,
          title: l10n.admDiscardChanges,
          message: l10n.admDiscardChangesMessage,
          confirmLabel: l10n.admDiscard,
        );
        if (leave && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.admPlannerSettings),
          actions: [
            IconButton(
              tooltip: l10n.admExpertValues,
              isSelected: _expert,
              icon: const Icon(Icons.numbers),
              onPressed: () => setState(() => _expert = !_expert),
            ),
          ],
        ),
        bottomNavigationBar: _draft == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton.icon(
                    onPressed: _saving || !_dirty ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(l10n.save),
                  ),
                ),
              ),
        body: AdminLoadState(
          loading: _loading,
          error: _error,
          onRetry: _load,
          builder: () => _form(context, l10n),
        ),
      ),
    );
  }

  Widget _form(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final d = _draft!;
    final active = _activeTemplate;
    final bandOn = d.values['weekly_min_hours'] != null ||
        d.values['weekly_max_hours'] != null;
    final updated = d.updatedAt;

    String priorityPreset() {
      final w = d.priorityWeights;
      for (final e in _priorityPresets.entries) {
        if (e.value == w) return e.key;
      }
      return 'custom';
    }

    String effort() {
      final secs = d.integer('solver_time_limit_seconds');
      final workers = d.integer('solver_num_workers');
      for (final e in _solverEfforts.entries) {
        if (e.value.$1 == secs && e.value.$2 == workers) return e.key;
      }
      return 'custom';
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (updated != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              l10n.admLastUpdated(
                  DateFormat.yMMMd(context.dateLocale).add_Hm().format(updated.toLocal())),
              style: theme.textTheme.bodySmall,
            ),
          ),
        AdminSectionHeader(l10n.admPsUseCase, subtitle: l10n.admPsUseCaseHint),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final id in useCaseTemplates.keys)
                ChoiceChip(
                  label: Text(_templateLabel(l10n, id)),
                  selected: active == id,
                  onSelected: (_) => _apply(useCaseTemplates[id]!),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            active == null ? l10n.admPsCustomMix : _templateHint(l10n, active),
            style: theme.textTheme.bodySmall,
          ),
        ),

        AdminSectionHeader(l10n.admPsRest, subtitle: l10n.admPsRestHint),
        _intField(l10n.admPsNightRecovery, l10n.admPsNightRecoveryHint,
            'night_shift_recovery_days', 0, 7, (v) => l10n.admUnitDays(v)),
        _intField(l10n.admPsMinRest, l10n.admPsMinRestHint, 'min_rest_hours',
            0, 24, (v) => l10n.admUnitHours(v)),
        _intField(l10n.admPsMaxConsecutive, l10n.admPsMaxConsecutiveHint,
            'max_consecutive_days', 0, 14, (v) => v == 0 ? l10n.admOff : '$v'),
        _intField(l10n.admPsMaxPerWeek, l10n.admPsMaxPerWeekHint,
            'max_working_days_per_week', 0, 7, (v) => v == 0 ? l10n.admOff : '$v'),

        AdminSectionHeader(l10n.admPsFairness, subtitle: l10n.admPsFairnessHint),
        _weightField(l10n.admPsEquality, l10n.admPsEqualityHint, 'equality_weight'),
        _weightField(l10n.admPsMonthlyTarget, l10n.admPsMonthlyTargetHint,
            'monthly_hours_target_weight'),
        SwitchListTile(
          title: Text(l10n.admPsWeeklyBand),
          subtitle: Text(l10n.admPsWeeklyBandHint),
          value: bandOn,
          onChanged: (on) => _apply(on
              ? {'weekly_min_hours': 20, 'weekly_max_hours': 45}
              : {'weekly_min_hours': null, 'weekly_max_hours': null}),
        ),
        if (bandOn) ...[
          _nullableIntField(l10n.admPsWeeklyMin, 'weekly_min_hours', 0, 80),
          _nullableIntField(l10n.admPsWeeklyMax, 'weekly_max_hours', 0, 80),
          _weightField(l10n.admPsBandStrength, null, 'weekly_hours_target_weight'),
        ],

        AdminSectionHeader(l10n.admPsCoverage, subtitle: l10n.admPsCoverageHint),
        _dropdownTile<String>(
          title: l10n.admPsPriority,
          subtitle: l10n.admPsPriorityHint,
          value: priorityPreset(),
          items: {
            for (final id in _priorityPresets.keys) id: _priorityLabel(l10n, id),
            if (priorityPreset() == 'custom') 'custom': l10n.admCustom,
          },
          onChanged: (id) {
            final w = _priorityPresets[id];
            if (w != null) _set('priority_weights', w.toJson());
          },
        ),
        if (_expert) ...[
          _priorityWeightField(l10n.priorityHigh, 'high'),
          _priorityWeightField(l10n.priorityMedium, 'medium'),
          _priorityWeightField(l10n.priorityLow, 'low'),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.admPsMinStaffing, style: theme.textTheme.bodyLarge),
              Text(l10n.admPsMinStaffingHint, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 'soft', label: Text(l10n.admPsMinStaffingSoft)),
                  ButtonSegment(value: 'hard', label: Text(l10n.admPsMinStaffingHard)),
                ],
                selected: {d.minStaffingMode},
                onSelectionChanged: (s) => _set('min_staffing_mode', s.first),
              ),
              if (d.minStaffingMode == 'hard')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l10n.admPsMinStaffingHardWarning,
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.admPsPersonalLimits, style: theme.textTheme.bodyLarge),
              Text(l10n.admPsPersonalLimitsHint, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                      value: 'hard', label: Text(l10n.admPsPersonalLimitsHard)),
                  ButtonSegment(
                      value: 'soft', label: Text(l10n.admPsPersonalLimitsSoft)),
                ],
                selected: {d.personalLimitsMode},
                onSelectionChanged: (s) => _set('personal_limits_mode', s.first),
              ),
            ],
          ),
        ),
        SwitchListTile(
          title: Text(l10n.admPsKeepRotations),
          subtitle: Text(d.keepFixedAssignments
              ? l10n.admPsKeepRotationsHint
              : l10n.admPsKeepRotationsOff),
          value: d.keepFixedAssignments,
          onChanged: (v) => _set('keep_fixed_assignments', v),
        ),
        _weightField(l10n.admPsContinuity, l10n.admPsContinuityHint,
            'shift_continuity_weight'),
        _weightField(l10n.admPsWeekStreak, l10n.admPsWeekStreakHint,
            'shift_continuity_week_bonus'),

        AdminSectionHeader(l10n.admPsPreferences, subtitle: l10n.admPsPreferencesHint),
        _weightField(l10n.admPsWishes, l10n.admPsWishesHint, 'wish_weight'),
        _weightField(l10n.admPsPreferredOff, l10n.admPsPreferredOffHint,
            'preference_weight'),
        _weightField(l10n.admPsSkillDowngrade, l10n.admPsSkillDowngradeHint,
            'skill_downgrade_weight'),
        _weightField(l10n.admPsFatigue, l10n.admPsFatigueHint, 'fatigue_weight'),
        _dropdownTile<num>(
          title: l10n.admPsNightFatigue,
          subtitle: l10n.admPsNightFatigueHint,
          value: d.number('night_shift_fatigue_multiplier') ?? 2,
          items: {
            for (final v in _nightFatigue) v: _nightFatigueLabel(l10n, v),
            if (!_nightFatigue.contains(d.number('night_shift_fatigue_multiplier')))
              d.number('night_shift_fatigue_multiplier') ?? 2:
                  l10n.admCustomValue('${d.number('night_shift_fatigue_multiplier')}'),
          },
          onChanged: (v) => _set('night_shift_fatigue_multiplier', v),
        ),

        AdminSectionHeader(l10n.admPsSolver, subtitle: l10n.admPsSolverHint),
        _dropdownTile<String>(
          title: l10n.admPsEffort,
          subtitle: l10n.admPsEffortHint(
              d.integer('solver_time_limit_seconds'), d.integer('solver_num_workers')),
          value: effort(),
          items: {
            'quick': l10n.admPsEffortQuick,
            'balanced': l10n.admPsEffortBalanced,
            'thorough': l10n.admPsEffortThorough,
            if (effort() == 'custom') 'custom': l10n.admCustom,
          },
          onChanged: (id) {
            final e = _solverEfforts[id];
            if (e != null) {
              _apply({
                'solver_time_limit_seconds': e.$1,
                'solver_num_workers': e.$2,
              });
            }
          },
        ),
        if (_expert) ...[
          _numberField(l10n.admPsTimeLimit, 'solver_time_limit_seconds'),
          _numberField(l10n.admPsWorkers, 'solver_num_workers'),
        ],
      ],
    );
  }

  Widget _intField(String label, String hint, String key, int min, int max,
      String Function(int) format) {
    return IntStepper(
      label: label,
      hint: hint,
      value: _draft!.integer(key).clamp(min, max),
      min: min,
      max: max,
      format: format,
      onChanged: (v) => _set(key, v),
    );
  }

  Widget _nullableIntField(String label, String key, int min, int max) {
    final v = _draft!.number(key)?.toInt();
    return IntStepper(
      label: label,
      value: (v ?? 0).clamp(min, max),
      min: min,
      max: max,
      format: (x) => x == 0 ? '—' : context.l10n.admUnitHours(x),
      onChanged: (x) => _set(key, x == 0 ? null : x),
    );
  }

  Widget _dropdownTile<T>({
    required String title,
    String? subtitle,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: DropdownButton<T>(
        value: items.containsKey(value) ? value : null,
        underline: const SizedBox.shrink(),
        items: [
          for (final e in items.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  Widget _weightField(String label, String? hint, String key) {
    final l10n = context.l10n;
    final value = _draft!.integer(key);
    if (_expert) return _numberField(label, key, hint: hint);
    final scale = weightScales[key]!;
    final level = scale.indexOf(value);
    final labels = [
      l10n.admLevelOff,
      l10n.admLevelWeak,
      l10n.admLevelBalanced,
      l10n.admLevelStrong,
      l10n.admLevelMax,
    ];
    return _dropdownTile<int>(
      title: label,
      subtitle: hint,
      value: level,
      items: {
        for (var i = 0; i < scale.length; i++) i: labels[i],
        if (level < 0) -1: l10n.admCustomValue('$value'),
      },
      onChanged: (i) {
        if (i >= 0) _set(key, scale[i]);
      },
    );
  }

  Widget _numberField(String label, String key, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: TextFormField(
        key: ValueKey('$key-$_generation'),
        initialValue: '${_draft!.values[key] ?? ''}',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          helperText: hint,
          helperMaxLines: 3,
          border: const OutlineInputBorder(),
        ),
        onChanged: (v) {
          final n = num.tryParse(v.replaceAll(',', '.'));
          if (n != null) {
            setState(() =>
                _draft = _draft!.copyWith({key: n % 1 == 0 ? n.toInt() : n}));
          }
        },
      ),
    );
  }

  Widget _priorityWeightField(String label, String tier) {
    final w = _draft!.priorityWeights.toJson();
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 6, 16, 6),
      child: TextFormField(
        key: ValueKey('prio-$tier-$_generation'),
        initialValue: '${w[tier]}',
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (v) {
          final n = int.tryParse(v);
          if (n != null) {
            setState(() => _draft = _draft!.copyWith({
              'priority_weights': {..._draft!.priorityWeights.toJson(), tier: n},
            }));
          }
        },
      ),
    );
  }
}

String _templateLabel(AppLocalizations l10n, String id) => switch (id) {
  'fairness' => l10n.admTplFairness,
  'wishes' => l10n.admTplWishes,
  'coverage' => l10n.admTplCoverage,
  'stability' => l10n.admTplStability,
  'wellbeing' => l10n.admTplWellbeing,
  _ => l10n.admTplBalanced,
};

String _templateHint(AppLocalizations l10n, String id) => switch (id) {
  'fairness' => l10n.admTplFairnessHint,
  'wishes' => l10n.admTplWishesHint,
  'coverage' => l10n.admTplCoverageHint,
  'stability' => l10n.admTplStabilityHint,
  'wellbeing' => l10n.admTplWellbeingHint,
  _ => l10n.admTplBalancedHint,
};

String _priorityLabel(AppLocalizations l10n, String id) => switch (id) {
  'ignore' => l10n.admPrioIgnore,
  'soft' => l10n.admPrioSoft,
  'strict' => l10n.admPrioStrict,
  _ => l10n.admPrioBalanced,
};

String _nightFatigueLabel(AppLocalizations l10n, num v) => switch (v) {
  1 => l10n.admNightSame,
  1.5 => l10n.admNightSlight,
  3 => l10n.admNightStrong,
  _ => l10n.admNightNoticeable,
};
