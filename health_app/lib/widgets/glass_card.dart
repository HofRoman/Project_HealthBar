import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Glassmorphism-Karte mit optionalem Neon-Glow
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? glowColor;
  final double glowIntensity;
  final double borderRadius;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final bool hasBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.glowColor,
    this.glowIntensity = 0.25,
    this.borderRadius = AppTheme.radiusMid,
    this.onTap,
    this.gradient,
    this.width,
    this.height,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? AppTheme.glassWhite : null,
            borderRadius: BorderRadius.circular(borderRadius),
            border: hasBorder
                ? Border.all(color: AppTheme.glassBorder, width: 1)
                : null,
          ),
          child: child,
        ),
      ),
    );

    if (glowColor != null) {
      card = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: AppTheme.glow(glowColor!, intensity: glowIntensity),
        ),
        child: card,
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

/// Neon-Trennlinie
class NeonDivider extends StatelessWidget {
  final Color color;
  const NeonDivider({super.key, this.color = AppTheme.neon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            color.withOpacity(0.5),
            color,
            color.withOpacity(0.5),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

/// Neon-Badge
class NeonBadge extends StatelessWidget {
  final String label;
  final Color color;

  const NeonBadge({super.key, required this.label, this.color = AppTheme.neon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.6)),
        color: color.withOpacity(0.12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Pulsierender Glow-Punkt (Online-Indikator)
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  const PulseDot({super.key, this.color = AppTheme.neonGreen, this.size = 10});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_pulse.value * 0.8),
              blurRadius: 8 * _pulse.value,
              spreadRadius: 2 * _pulse.value,
            ),
          ],
        ),
      ),
    );
  }
}

/// Gradient-Text
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;

  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient = AppTheme.heroGradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Text(text, style: style),
    );
  }
}

/// Fortschrittsbalken mit Neon-Glow
class NeonProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const NeonProgressBar({
    super.key,
    required this.value,
    this.color = AppTheme.neon,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(
            height: height,
            color: color.withOpacity(0.12),
          ),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.7), color],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
