import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'bmi_screen.dart';
import 'water_screen.dart';
import 'activity_screen.dart';
import 'sleep_screen.dart';
import 'nutrition_screen.dart';

class TrackingHubScreen extends StatefulWidget {
  const TrackingHubScreen({super.key});

  @override
  State<TrackingHubScreen> createState() => _TrackingHubScreenState();
}

class _TrackingHubScreenState extends State<TrackingHubScreen> {
  final _db = DatabaseHelper();
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final water = await _db.getWaterToday();
    final activities = await _db.getActivitiesToday();
    final bmiEntries = await _db.getBmiEntries();
    final sleepEntries = await _db.getSleepEntries();
    final nutrition = await _db.getNutritionToday();

    setState(() {
      _data = {
        'waterMl': water.fold(0, (s, e) => s + (e['amount_ml'] as int)),
        'calories': activities.fold(0, (s, e) => s + (e['calories_burned'] as int)) +
            nutrition.fold(0, (s, e) => s + (e['calories'] as int)),
        'steps': activities.fold(0, (s, e) => s + (e['steps'] as int)),
        'bmi': bmiEntries.isNotEmpty ? bmiEntries.first['bmi'] as double : null,
        'sleep': sleepEntries.isNotEmpty
            ? sleepEntries.first['duration_hours'] as double
            : 0.0,
        'actMin': activities.fold(
            0, (s, e) => s + (e['duration_minutes'] as int)),
      };
    });
  }

  void _go(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final w = _data['waterMl'] as int? ?? 0;
    final cal = _data['calories'] as int? ?? 0;
    final steps = _data['steps'] as int? ?? 0;
    final bmi = _data['bmi'] as double?;
    final sleep = _data['sleep'] as double? ?? 0;
    final actMin = _data['actMin'] as int? ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.neon,
        backgroundColor: AppTheme.bgCard,
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    20, MediaQuery.of(context).padding.top + 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GradientText('Tracking',
                            style: AppTheme.headline1,
                            gradient: AppTheme.neonGradient(AppTheme.colorActivity)),
                        const Spacer(),
                        Text(
                          DateFormat('dd.MM.yyyy', 'de_DE').format(DateTime.now()),
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Deine heutigen Gesundheitsdaten',
                        style: AppTheme.caption),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Heute Übersicht ────────────────────────
                  const Text('Heute im Überblick', style: AppTheme.headline3),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _TrackTile(
                        label: 'Wasser',
                        value: '${(w / 1000).toStringAsFixed(1)}L',
                        unit: 'Ziel: 2.5L',
                        icon: Icons.water_drop,
                        color: AppTheme.colorWater,
                        progress: w / 2500,
                        onTap: () => _go(const WaterScreen()),
                      ),
                      _TrackTile(
                        label: 'Kalorien',
                        value: '$cal',
                        unit: 'kcal / 2000',
                        icon: Icons.local_fire_department,
                        color: AppTheme.colorActivity,
                        progress: cal / 2000,
                        onTap: () => _go(const ActivityScreen()),
                      ),
                      _TrackTile(
                        label: 'Schritte',
                        value: NumberFormat('#,###').format(steps),
                        unit: 'Ziel: 10.000',
                        icon: Icons.directions_walk,
                        color: AppTheme.colorScore,
                        progress: steps / 10000,
                        onTap: () => _go(const ActivityScreen()),
                      ),
                      _TrackTile(
                        label: 'Schlaf',
                        value: sleep > 0
                            ? '${sleep.toStringAsFixed(1)}h'
                            : '—',
                        unit: 'Ziel: 7-9h',
                        icon: Icons.bedtime,
                        color: AppTheme.colorSleep,
                        progress: sleep / 8,
                        onTap: () => _go(const SleepScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── BMI-Banner ─────────────────────────────
                  if (bmi != null)
                    _BmiCard(bmi: bmi, onTap: () => _go(const BmiScreen()))
                  else
                    _BmiPromptCard(onTap: () => _go(const BmiScreen())),
                  const SizedBox(height: 20),

                  // ── Module ─────────────────────────────────
                  const Text('Module', style: AppTheme.headline3),
                  const SizedBox(height: 12),
                  ...[
                    ('BMI Rechner', 'Gewicht & Körpergröße',
                        Icons.monitor_weight, AppTheme.colorBmi, const BmiScreen()),
                    ('Wassertracker', 'Tägliche Wasseraufnahme',
                        Icons.water_drop, AppTheme.colorWater, const WaterScreen()),
                    ('Aktivität', 'Sport & Bewegung erfassen',
                        Icons.fitness_center, AppTheme.colorActivity, const ActivityScreen()),
                    ('Schlaf', 'Schlafdauer & Qualität',
                        Icons.bedtime, AppTheme.colorSleep, const SleepScreen()),
                    ('Ernährung', 'Kalorien & Nährstoffe',
                        Icons.restaurant, AppTheme.colorFood, const NutritionScreen()),
                  ].map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TrackModuleRow(
                          title: m.$1,
                          subtitle: m.$2,
                          icon: m.$3,
                          color: m.$4,
                          onTap: () => _go(m.$5),
                        ),
                      )),
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

class _TrackTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final double progress;
  final VoidCallback onTap;

  const _TrackTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: color,
      glowIntensity: 0.15,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 5),
              Text(label,
                  style: AppTheme.caption.copyWith(color: color)),
            ],
          ),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 4),
          NeonProgressBar(
              value: progress.clamp(0.0, 1.0), color: color, height: 4),
          const SizedBox(height: 4),
          Text(unit, style: AppTheme.caption),
        ],
      ),
    );
  }
}

class _BmiCard extends StatelessWidget {
  final double bmi;
  final VoidCallback onTap;

  const _BmiCard({required this.bmi, required this.onTap});

  Color get _color {
    if (bmi < 18.5) return AppTheme.neonBlue;
    if (bmi < 25.0) return AppTheme.neonGreen;
    if (bmi < 30.0) return AppTheme.colorActivity;
    return AppTheme.colorFood;
  }

  String get _cat {
    if (bmi < 18.5) return 'Untergewicht';
    if (bmi < 25.0) return 'Normalgewicht';
    if (bmi < 30.0) return 'Übergewicht';
    return 'Adipositas';
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: _color,
      glowIntensity: 0.2,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _color, width: 2),
              color: _color.withOpacity(0.1),
            ),
            child: Center(
              child: Text(
                bmi.toStringAsFixed(1),
                style: TextStyle(
                    color: _color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dein BMI', style: AppTheme.caption),
              Text(_cat,
                  style: TextStyle(
                      color: _color,
                      fontWeight: FontWeight.w800,
                      fontSize: 20)),
              Text('Tippe für Details', style: AppTheme.caption),
            ],
          ),
          const Spacer(),
          Icon(Icons.chevron_right, color: _color),
        ],
      ),
    );
  }
}

class _BmiPromptCard extends StatelessWidget {
  final VoidCallback onTap;
  const _BmiPromptCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: AppTheme.colorBmi,
      glowIntensity: 0.15,
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.monitor_weight,
              color: AppTheme.colorBmi, size: 36),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BMI noch nicht berechnet',
                    style: AppTheme.bodyBold),
                Text('Tippe hier → BMI berechnen',
                    style: AppTheme.caption),
              ],
            ),
          ),
          const Icon(Icons.add_circle_outline,
              color: AppTheme.colorBmi),
        ],
      ),
    );
  }
}

class _TrackModuleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TrackModuleRow({
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
      glowIntensity: 0.08,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.bodyBold),
                Text(subtitle, style: AppTheme.caption),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: color, size: 18),
        ],
      ),
    );
  }
}
