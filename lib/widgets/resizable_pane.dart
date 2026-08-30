import 'package:flutter/material.dart';

/// A pane of a vertically stacked layout with a drag handle along its bottom
/// edge, which reads as the separator towards the pane below.
///
/// Dragging the handle reports how much this pane should grow — positive means
/// taller — which keeps the caller free of any handle-position arithmetic.
/// Double tapping it calls [onReset]. A pane without [onResize] renders no
/// handle at all, so a seam between two panes never carries two of them.
class ResizablePane extends StatefulWidget {
  /// Fixed height of the pane; when null the pane takes whatever height its
  /// parent gives it (e.g. wrapped in an [Expanded]).
  final double? height;

  final Widget child;

  /// Signed height delta for this pane, in logical pixels. Null hides the
  /// handle and makes the pane a plain, clipped box.
  final ValueChanged<double>? onResize;

  /// Called when the handle is double tapped; hidden from the tooltip if null.
  final VoidCallback? onReset;

  /// The handle's tooltip. Supplied ready to display so this widget needs no
  /// access to the translations.
  final String tooltip;

  const ResizablePane({
    super.key,
    required this.child,
    required this.tooltip,
    this.onResize,
    this.height,
    this.onReset,
  });

  @override
  State<ResizablePane> createState() => _ResizablePaneState();
}

class _ResizablePaneState extends State<ResizablePane> {
  bool _hovered = false;
  bool _dragging = false;

  static const double _barHeight = 16;
  static const Duration _fade = Duration(milliseconds: 120);

  @override
  Widget build(BuildContext context) {
    // The child is clipped so a pane dragged smaller than its content never
    // paints over its neighbours.
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: ClipRect(child: widget.child)),
        if (widget.onResize != null) _handleBar(context),
      ],
    );

    return widget.height == null
        ? column
        : SizedBox(height: widget.height, child: column);
  }

  Widget _handleBar(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = _hovered || _dragging;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => setState(() => _dragging = true),
        onVerticalDragUpdate: (d) => widget.onResize!(d.delta.dy),
        onVerticalDragEnd: (_) => setState(() => _dragging = false),
        onVerticalDragCancel: () => setState(() => _dragging = false),
        onDoubleTap: widget.onReset,
        child: Tooltip(
          message: widget.tooltip,
          waitDuration: const Duration(milliseconds: 600),
          child: SizedBox(
            height: _barHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Hairline seam, tinted while the handle is in play.
                AnimatedContainer(
                  duration: _fade,
                  height: 1,
                  width: double.infinity,
                  color: active
                      ? scheme.primary.withValues(alpha: 0.35)
                      : theme.dividerColor,
                ),
                // The grip sits on its own patch of background so the seam
                // appears to run into it rather than through it.
                ColoredBox(
                  color: scheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: AnimatedContainer(
                      duration: _fade,
                      curve: Curves.easeOut,
                      width: active ? 56 : 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: active ? scheme.primary : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
