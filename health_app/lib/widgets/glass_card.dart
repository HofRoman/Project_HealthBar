import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// iOS 26 Liquid Glass Card
/// Frosted glass mit BackdropFilter — wie native iOS UIKit
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? glowColor;     // Wird als Icon-Akzentfarbe genutzt (kein Glow)
  final double glowIntensity; // Unused, kept for API compatibility
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final LinearGradient? gradient;
  final double? borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.glowColor,
    this.glowIntensity = 0.1,
    this.onTap,
    this.padding,
    this.gradient,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? AppTheme.radiusLarge.toDouble();

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: gradient == null ? AppTheme.glassFill : null,
            gradient: gradient ?? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.07),
                Colors.white.withOpacity(0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(r),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(r),
          splashColor: (glowColor ?? AppTheme.iosBlue).withOpacity(0.08),
          highlightColor: Colors.white.withOpacity(0.03),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// iOS-Separator — haarfein
class NeonDivider extends StatelessWidget {
  final Color color;
  const NeonDivider({super.key, this.color = AppTheme.separator});

  @override
  Widget build(BuildContext context) =>
      Container(height: 0.5, color: color);
}

/// iOS-Style Badge
class NeonBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const NeonBadge(
    this.label, {
    super.key,
    this.color = AppTheme.iosBlue,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? Colors.white : color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Status-Indikator
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  final bool pulse;

  const PulseDot({
    super.key,
    this.color = AppTheme.iosGreen,
    this.size = 8,
    this.pulse = true,
  });

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!widget.pulse) return _dot(1.0);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => _dot(_anim.value),
    );
  }

  Widget _dot(double opacity) => Container(
    width: widget.size, height: widget.size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: widget.color.withOpacity(opacity),
    ),
  );
}

/// Gradient-Text
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;

  const GradientText(this.text, {super.key, required this.style, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style),
    );
  }
}

/// iOS-Style Fortschrittsbalken
class NeonProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  final bool showBackground;

  const NeonProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 4,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        backgroundColor:
            showBackground ? color.withOpacity(0.15) : Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(color),
        minHeight: height,
      ),
    );
  }
}

/// Daten-Zeile (Label + Wert)
class DataRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  const DataRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: AppTheme.textMuted),
          const SizedBox(width: 8),
        ],
        Expanded(child: Text(label, style: AppTheme.caption)),
        Text(value, style: AppTheme.monoValue.copyWith(
            color: valueColor ?? AppTheme.textPrimary)),
      ]),
    );
  }
}
