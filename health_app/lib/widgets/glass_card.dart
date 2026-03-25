import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Professionelle Karte — seriöses klinisches Design
/// Dezente Tiefe statt Neon-Glow
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? glowColor;      // Akzentfarbe für linken Rand-Streifen
  final double glowIntensity;  // Kept for API compatibility
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
    final r = borderRadius ?? AppTheme.radiusMid.toDouble();
    final hasAccent = glowColor != null;

    Widget card = Container(
      decoration: BoxDecoration(
        color: gradient == null ? AppTheme.bgCard : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: AppTheme.glassBorder, width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linker Akzent-Streifen (diskret, 3px)
            if (hasAccent)
              Container(
                width: 3,
                color: glowColor!.withOpacity(0.65),
              ),
            Expanded(
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(r),
          splashColor: (glowColor ?? AppTheme.primary).withOpacity(0.06),
          highlightColor: (glowColor ?? AppTheme.primary).withOpacity(0.04),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Dezenter horizontaler Trennstrich
class NeonDivider extends StatelessWidget {
  final Color color;
  const NeonDivider({super.key, this.color = AppTheme.glassBorder});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: color);
  }
}

/// Status-Badge — professionell, klar
class NeonBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const NeonBadge(
    this.label, {
    super.key,
    this.color = AppTheme.primary,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: filled ? Colors.white : color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Status-Punkt (aktiv / inaktiv)
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  final bool pulse;

  const PulseDot({
    super.key,
    this.color = AppTheme.success,
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
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.45, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
    width: widget.size,
    height: widget.size,
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

  const GradientText(
    this.text, {
    super.key,
    required this.style,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}

/// Professioneller Fortschrittsbalken
class NeonProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  final bool showBackground;

  const NeonProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 5,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        backgroundColor:
            showBackground ? color.withOpacity(0.12) : Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(color),
        minHeight: height,
      ),
    );
  }
}

/// Daten-Zeile — Label links, Wert rechts
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 6),
        ],
        Expanded(child: Text(label, style: AppTheme.caption)),
        Text(
          value,
          style: AppTheme.monoValue.copyWith(
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ]),
    );
  }
}
