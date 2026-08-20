import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Single button component used across the app.
///
/// - Dark filled surface (no neon outline).
/// - Antique gold label.
/// - Subtle scale-down while pressed for a tactile, ritual feel.
class MysticButton extends StatefulWidget {
  const MysticButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool expand;

  @override
  State<MysticButton> createState() => _MysticButtonState();
}

class _MysticButtonState extends State<MysticButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(2),
      side: BorderSide(
        color: enabled
            ? AppColors.gold.withValues(alpha: _pressed ? 0.9 : 0.6)
            : AppColors.gold.withValues(alpha: 0.2),
        width: 1,
      ),
    );

    final child = Material(
      color: enabled
          ? AppColors.midnight.withValues(alpha: 0.7)
          : AppColors.cosmos.withValues(alpha: 0.5),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onPressed,
        onHighlightChanged: enabled ? _setPressed : null,
        splashColor: AppColors.gold.withValues(alpha: 0.12),
        highlightColor: AppColors.gold.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: AppText.button().copyWith(
              color: enabled
                  ? AppColors.goldWhisper
                  : AppColors.goldWhisper.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.expand
            ? SizedBox(width: double.infinity, child: child)
            : child,
      ),
    );
  }
}
