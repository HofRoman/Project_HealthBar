import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'ai_chat_screen.dart';
import 'face_scan_screen.dart';
import 'research_screen.dart';
import 'health_report_screen.dart';
import 'first_aid_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseHelper();

  int _waterMl = 0;
  int _calories = 0;
  int _steps = 0;
  double? _bmi;
  double _sleep = 0;
  int _actMin = 0;
  bool _hasApiKey = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _load();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final water = await _db.getWaterToday();
    final acts = await _db.getActivitiesToday();
    final bmis = await _db.getBmiEntries();
    final sleeps = await _db.getSleepEntries();
    final nutrition = await _db.getNutritionToday();
    final has = await GeminiService.hasApiKey();

    setState(() {
      _waterMl = water.fold(0, (s, e) => s + (e['amount_ml'] as int));
      _calories = acts.fold(0, (s, e) => s + (e['calories_burned'] as int)) +
          nutrition.fold(0, (s, e) => s + (e['calories'] as int));
      _steps = acts.fold(0, (s, e) => s + (e['steps'] as int));
      _bmi = bmis.isNotEmpty ? bmis.first['bmi'] as double : null;
      _sleep = sleeps.isNotEmpty
          ? sleeps.first['duration_hours'] as double
          : 0;
      _actMin = acts.fold(0, (s, e) => s + (e['duration_minutes'] as int));
      _hasApiKey = has;
    });
  }

  void _go(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => screen,
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: a,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    ).then((_) => _load());
  }

  // Gesundheits-Score lokal berechnen (für Anzeige ohne API)
  int get _localScore {
    int score = 0;
    if (_waterMl >= 2500) score += 25;
    else score += ((_waterMl / 2500) * 25).round();
    if (_sleep >= 7 && _sleep <= 9) score += 25;
    else if (_sleep > 0) score += ((_sleep.clamp(0, 9) / 9) * 20).round();
    if (_actMin >= 30) score += 25;
    else score += ((_actMin / 30) * 25).round();
    if (_bmi != null) {
      if (_bmi! >= 18.5 && _bmi! < 25) score += 25;
      else if (_bmi! >= 17 && _bmi! < 30) score += 15;
      else score += 5;
    }
    return score.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Guten Morgen'
        : now.hour < 17
            ? 'Guten Tag'
            : 'Guten Abend';

    final score = _localScore;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.neon,
        backgroundColor: AppTheme.bgCard,
        child: CustomScrollView(
          slivers: [
            // ── Hero Header ──────────────────────────────────
            SliverToBoxAdapter(
              child: _HeroHeader(
                greeting: greeting,
                score: score,
                hasApiKey: _hasApiKey,
                pulseAnim: _pulseAnim,
                onAiTap: () => _go(const AiChatScreen()),
                onSettingsTap: () => _go(const SettingsScreen()),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Vitaldaten-Ring ─────────────────────────
                  _VitalRingRow(
                    waterMl: _waterMl,
                    calories: _calories,
                    steps: _steps,
                    sleep: _sleep,
                  ),
                  const SizedBox(height: 20),

                  // ── KI Schnellzugriff ────────────────────────
                  _SectionHeader(
                    label: 'KI-POWERED',
                    title: 'Schnellzugriff',
                    color: AppTheme.colorAI,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _QuickAiCard(
                          title: 'KI-Arzt fragen',
                          subtitle: 'Stelle jede medizinische Frage',
                          icon: Icons.smart_toy_rounded,
                          color: AppTheme.colorAI,
                          onTap: () => _go(const AiChatScreen()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _QuickAiCard(
                          title: 'Gesicht\nscannen',
                          subtitle: 'KI-Analyse',
                          icon: Icons.face_retouching_natural,
                          color: AppTheme.colorFace,
                          onTap: () => _go(const FaceScanScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GlassCard(
                    glowColor: AppTheme.colorResearch,
                    glowIntensity: 0.2,
                    onTap: () => _go(const ResearchScreen()),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.colorResearch.withOpacity(0.15),
                        AppTheme.colorResearch.withOpacity(0.04),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.colorResearch.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.science_rounded,
                              color: AppTheme.colorResearch, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Medizin Deep Research',
                                  style: AppTheme.bodyBold),
                              Text(
                                  'KI sucht aktiv nach aktuellen Studien & Leitlinien',
                                  style: AppTheme.caption),
                            ],
                          ),
                        ),
                        NeonBadge(
                            label: 'GOOGLE\nSEARCH',
                            color: AppTheme.colorResearch),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right,
                            color: AppTheme.colorResearch),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: GlassCard(
                      glowColor: AppTheme.colorReport,
                      glowIntensity: 0.2,
                      onTap: () => _go(const HealthReportScreen()),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.colorReport.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.summarize,
                                color: AppTheme.colorReport, size: 18),
                          ),
                          const SizedBox(height: 8),
                          const Text('KI-Bericht', style: AppTheme.bodyBold),
                          const Text('Komplette Analyse', style: AppTheme.caption),
                        ],
                      ),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: GlassCard(
                      glowColor: AppTheme.colorEmergency,
                      glowIntensity: 0.2,
                      onTap: () => _go(const FirstAidScreen()),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.colorEmergency.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.emergency,
                                color: AppTheme.colorEmergency, size: 18),
                          ),
                          const SizedBox(height: 8),
                          const Text('Erste Hilfe', style: AppTheme.bodyBold),
                          const Text('Notfall-Guide + KI', style: AppTheme.caption),
                        ],
                      ),
                    )),
                  ]),
                  const SizedBox(height: 20),

                  // ── Heute detailliert ─────────────────────────
                  _SectionHeader(
                    label: 'HEUTE',
                    title: DateFormat('EEEE, d. MMMM', 'de_DE').format(now),
                    color: AppTheme.neon,
                  ),
                  const SizedBox(height: 12),
                  _DetailedStats(
                    waterMl: _waterMl,
                    calories: _calories,
                    steps: _steps,
                    sleep: _sleep,
                    actMin: _actMin,
                    bmi: _bmi,
                  ),

                  const SizedBox(height: 20),

                  // ── Gesundheits-Tipps ─────────────────────────
                  _HealthTip(score: score),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final String greeting;
  final int score;
  final bool hasApiKey;
  final Animation<double> pulseAnim;
  final VoidCallback onAiTap;
  final VoidCallback onSettingsTap;

  const _HeroHeader({
    required this.greeting,
    required this.score,
    required this.hasApiKey,
    required this.pulseAnim,
    required this.onAiTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF050B18), Color(0xFF0A1628), Color(0xFF050B18)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting,
                        style: AppTheme.caption
                            .copyWith(color: AppTheme.neon, letterSpacing: 2)),
                    const SizedBox(height: 4),
                    const GradientText(
                      'HealthBar',
                      style: AppTheme.headline1,
                      gradient: AppTheme.heroGradient,
                    ),
                  ],
                ),
              ),
              // Einstellungen
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: AppTheme.textSecondary),
                onPressed: onSettingsTap,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Score-Karte + KI-Button
          Row(
            children: [
              // Score-Ring
              Expanded(
                child: GlassCard(
                  glowColor: _scoreColor(score),
                  glowIntensity: 0.25,
                  child: Row(
                    children: [
                      // Kreis
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: score / 100,
                              backgroundColor:
                                  _scoreColor(score).withOpacity(0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  _scoreColor(score)),
                              strokeWidth: 6,
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('$score',
                                      style: TextStyle(
                                          color: _scoreColor(score),
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900)),
                                  Text('/ 100',
                                      style: AppTheme.caption.copyWith(
                                          fontSize: 9)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gesundheits-\nScore heute',
                              style: AppTheme.caption),
                          const SizedBox(height: 4),
                          Text(
                            _scoreLabel(score),
                            style: TextStyle(
                              color: _scoreColor(score),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // KI-Button
              GestureDetector(
                onTap: onAiTap,
                child: AnimatedBuilder(
                  animation: pulseAnim,
                  builder: (_, __) => Container(
                    width: 80,
                    height: 94,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMid),
                      color: AppTheme.colorAI.withOpacity(0.1),
                      border: Border.all(
                          color: AppTheme.colorAI.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.colorAI
                              .withOpacity(0.2 * pulseAnim.value),
                          blurRadius: 20 * pulseAnim.value,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.smart_toy_rounded,
                            color: AppTheme.colorAI,
                            size: 28 * (pulseAnim.value * 0.05 + 0.95)),
                        const SizedBox(height: 6),
                        Text('KI-Arzt',
                            style: TextStyle(
                              color: AppTheme.colorAI,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            )),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (hasApiKey)
                              PulseDot(size: 6, color: AppTheme.neonGreen)
                            else
                              const Icon(Icons.circle,
                                  size: 6, color: AppTheme.textMuted),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int s) {
    if (s >= 80) return AppTheme.neonGreen;
    if (s >= 60) return AppTheme.neon;
    if (s >= 40) return const Color(0xFFFFB300);
    return AppTheme.colorFood;
  }

  String _scoreLabel(int s) {
    if (s >= 80) return 'Ausgezeichnet';
    if (s >= 60) return 'Gut';
    if (s >= 40) return 'Okay';
    return 'Verbesserung';
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.label,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NeonBadge(label: label, color: color),
        const SizedBox(width: 10),
        Text(title, style: AppTheme.headline3),
      ],
    );
  }
}

class _VitalRingRow extends StatelessWidget {
  final int waterMl;
  final int calories;
  final int steps;
  final double sleep;

  const _VitalRingRow({
    required this.waterMl,
    required this.calories,
    required this.steps,
    required this.sleep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _VitalRing(
          value: waterMl / 2500,
          label: 'Wasser',
          display: '${(waterMl / 1000).toStringAsFixed(1)}L',
          color: AppTheme.colorWater,
          icon: Icons.water_drop,
        ),
        _VitalRing(
          value: calories / 2000,
          label: 'Kcal',
          display: '$calories',
          color: AppTheme.colorActivity,
          icon: Icons.local_fire_department,
        ),
        _VitalRing(
          value: steps / 10000,
          label: 'Schritte',
          display: steps >= 1000
              ? '${(steps / 1000).toStringAsFixed(1)}k'
              : '$steps',
          color: AppTheme.colorScore,
          icon: Icons.directions_walk,
        ),
        _VitalRing(
          value: sleep / 8,
          label: 'Schlaf',
          display: sleep > 0 ? '${sleep.toStringAsFixed(1)}h' : '—',
          color: AppTheme.colorSleep,
          icon: Icons.bedtime,
        ),
      ],
    );
  }
}

class _VitalRing extends StatelessWidget {
  final double value;
  final String label;
  final String display;
  final Color color;
  final IconData icon;

  const _VitalRing({
    required this.value,
    required this.label,
    required this.display,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: clamped,
                  backgroundColor: color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 5,
                ),
                Center(
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(display,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 13)),
          Text(label, style: AppTheme.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class _QuickAiCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAiCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: color,
      glowIntensity: 0.2,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(title,
              style: AppTheme.bodyBold.copyWith(height: 1.3)),
          const SizedBox(height: 3),
          Text(subtitle, style: AppTheme.caption, maxLines: 2),
        ],
      ),
    );
  }
}

class _DetailedStats extends StatelessWidget {
  final int waterMl;
  final int calories;
  final int steps;
  final double sleep;
  final int actMin;
  final double? bmi;

  const _DetailedStats({
    required this.waterMl,
    required this.calories,
    required this.steps,
    required this.sleep,
    required this.actMin,
    required this.bmi,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          _StatRow(Icons.water_drop, 'Wasser',
              '${waterMl}ml', '/ 2500ml', AppTheme.colorWater, waterMl / 2500),
          const SizedBox(height: 10),
          _StatRow(Icons.local_fire_department, 'Kalorien',
              '${calories}kcal', '/ 2000kcal', AppTheme.colorActivity, calories / 2000),
          const SizedBox(height: 10),
          _StatRow(Icons.directions_walk, 'Schritte',
              NumberFormat('#,###').format(steps),
              '/ 10.000', AppTheme.colorScore, steps / 10000),
          const SizedBox(height: 10),
          _StatRow(Icons.bedtime, 'Schlaf',
              sleep > 0 ? '${sleep.toStringAsFixed(1)}h' : '—',
              '/ 8h', AppTheme.colorSleep, sleep / 8),
          const SizedBox(height: 10),
          _StatRow(Icons.fitness_center, 'Sport',
              '${actMin}min', '/ 30min', AppTheme.colorActivity, actMin / 30),
          if (bmi != null) ...[
            const SizedBox(height: 10),
            _StatRow(Icons.monitor_weight, 'BMI',
                bmi!.toStringAsFixed(1), _bmiCat(bmi!),
                _bmiColor(bmi!), (bmi! / 30).clamp(0, 1)),
          ],
        ],
      ),
    );
  }

  String _bmiCat(double b) {
    if (b < 18.5) return 'Untergewicht';
    if (b < 25) return 'Normal';
    if (b < 30) return 'Übergewicht';
    return 'Adipositas';
  }

  Color _bmiColor(double b) {
    if (b < 18.5) return AppTheme.neonBlue;
    if (b < 25) return AppTheme.neonGreen;
    if (b < 30) return const Color(0xFFFFB300);
    return AppTheme.colorFood;
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String target;
  final Color color;
  final double progress;

  const _StatRow(this.icon, this.label, this.value, this.target, this.color,
      this.progress);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(label, style: AppTheme.caption),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const SizedBox(width: 4),
            Text(target, style: AppTheme.caption.copyWith(fontSize: 10)),
          ],
        ),
        const SizedBox(height: 5),
        NeonProgressBar(
            value: progress.clamp(0.0, 1.0), color: color, height: 4),
      ],
    );
  }
}

class _HealthTip extends StatelessWidget {
  final int score;
  const _HealthTip({required this.score});

  static const _tips = [
    ('💧', 'Wasser trinken', 'Trinke ein Glas Wasser – Hydratation verbessert Konzentration um bis zu 20%.'),
    ('🚶', 'Kurze Bewegungspause', 'Bereits 10 Minuten Gehen senkt Blutzucker und verbessert die Stimmung.'),
    ('😴', 'Schlaf ist Medizin', '7-9h Schlaf reduziert das Herzerkrankungsrisiko um 30% (Harvard Medical School).'),
    ('🥗', 'Ballaststoffe', 'Ballaststoffreiche Ernährung reduziert Darmkrebsrisiko um bis zu 17% (WHO).'),
    ('🧘', 'Stressreduktion', '5 Minuten tiefes Atmen aktiviert das parasympathische Nervensystem.'),
    ('☀️', 'Vitamin D', 'Täglich 20 min Sonnenlicht unterstützt Immunsystem und Knochengesundheit.'),
  ];

  @override
  Widget build(BuildContext context) {
    final tip = _tips[DateTime.now().hour % _tips.length];
    return GlassCard(
      glowColor: AppTheme.neon,
      glowIntensity: 0.15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeonBadge(label: 'TIPP', color: AppTheme.neon),
              const SizedBox(width: 8),
              const Text('Wissenschaftlicher Gesundheitstipp',
                  style: AppTheme.caption),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tip.$1, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tip.$2, style: AppTheme.bodyBold),
                    const SizedBox(height: 4),
                    Text(tip.$3, style: AppTheme.body),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
