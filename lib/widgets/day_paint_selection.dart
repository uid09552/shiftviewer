import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Turns a long press that drags across day cells into a multi-day selection.
///
/// Long pressing arms the selection with the day under the finger, moving from
/// there paints every day the finger passes over, and lifting hands them to
/// [onCommit]. A long press without any movement commits exactly one day, so
/// the familiar "long press a date to wish for it" gesture still works — it is
/// just the shortest possible drag.
///
/// The gesture starts from a long press rather than a plain drag on purpose:
/// that lets a grid live inside a scroll view without the two fighting over
/// the pan.
///
/// Cells opt in by wrapping themselves in a [PaintableDay], which also draws
/// the highlight while the finger is on them.
class DayPaintArea extends StatefulWidget {
  final Widget child;

  /// The painted days, once the finger lifts. Never empty.
  final ValueChanged<Set<DateTime>> onCommit;

  const DayPaintArea({
    super.key,
    required this.child,
    required this.onCommit,
  });

  @override
  State<DayPaintArea> createState() => _DayPaintAreaState();
}

class _DayPaintAreaState extends State<DayPaintArea> {
  final Set<DateTime> _painted = {};

  /// The day drawn under [globalPosition], found by hit testing for the
  /// [PaintableDay] marker rather than by measuring the grid, so the cells stay
  /// free to lay themselves out however they like.
  DateTime? _dayAt(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final result = BoxHitTestResult();
    box.hitTest(result, position: box.globalToLocal(globalPosition));
    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderMetaData && target.metaData is DateTime) {
        return target.metaData as DateTime;
      }
    }
    return null;
  }

  void _paint(Offset globalPosition) {
    final day = _dayAt(globalPosition);
    if (day == null || _painted.contains(day)) return;
    // One tick per day, so painting a week can be felt without looking.
    HapticFeedback.selectionClick();
    setState(() => _painted.add(day));
  }

  void _commit() {
    if (_painted.isEmpty) return;
    final days = Set<DateTime>.of(_painted);
    setState(_painted.clear);
    widget.onCommit(days);
  }

  void _cancel() {
    if (_painted.isEmpty) return;
    setState(_painted.clear);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onLongPressStart: (d) => _paint(d.globalPosition),
      onLongPressMoveUpdate: (d) => _paint(d.globalPosition),
      onLongPressEnd: (_) => _commit(),
      onLongPressCancel: _cancel,
      child: _PaintedDays(days: Set.of(_painted), child: widget.child),
    );
  }
}

/// The live selection, handed down so each cell can highlight itself without
/// the grid above it having to rebuild.
class _PaintedDays extends InheritedWidget {
  final Set<DateTime> days;

  const _PaintedDays({required this.days, required super.child});

  static Set<DateTime> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PaintedDays>()?.days ??
      const {};

  @override
  bool updateShouldNotify(_PaintedDays oldWidget) =>
      !setEquals(oldWidget.days, days);
}

/// Marks [child] as the cell for [day] so an enclosing [DayPaintArea] can pick
/// it up, and tints it while it is part of the selection being painted.
///
/// [day] must be normalised with `dateKey` — the selection is a set of dates.
class PaintableDay extends StatelessWidget {
  final DateTime day;
  final Widget child;

  /// Corners of the highlight; match the cell's own shape.
  final BorderRadius borderRadius;

  const PaintableDay({
    super.key,
    required this.day,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final painted = _PaintedDays.of(context).contains(day);

    return MetaData(
      metaData: day,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          child,
          if (painted)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.22),
                    borderRadius: borderRadius,
                    border: Border.all(color: scheme.primary, width: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
