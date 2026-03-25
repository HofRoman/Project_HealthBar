import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper();
  int _waterMl = 0;
  int _calories = 0;
  int _steps = 0;
  double _sleep = 0;
  int _actMin = 0;
  double? _bmi;
  bool _hasApiKey = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final water     = await _db.getWaterToday();
    final acts      = await _db.getActivitiesToday();
    final bmis      = await _db.getBmiEntries();
    final sleeps    = await _db.getSleepEntries();
    final nutrition = await _db.getNutritionToday();
    final hasKey    = await GeminiService.hasApiKey();

    if (!mounted) return;
    setState(() {
      _waterMl  = water.fold(0, (s, e) => s + (e['amount_ml'] as int));
      _calories = acts.fold(0, (s, e) => s + (e['calories_burned'] as int))
                + nutrition.fold(0, (s, e) => s + (e['calories'] as int));
      _steps    = acts.fold(0, (s, e) => s + (e['steps'] as int));
      _sleep    = sleeps.isNotEmpty
          ? sleeps.first['duration_hours'] as double : 0;
      _actMin   = acts.fold(0, (s, e) => s + (e['duration_minutes'] as int));
      _bmi      = bmis.isNotEmpty ? bmis.first['bmi'] as double : null;
      _hasApiKey = hasKey;
    });
  }

  void _go(Widget screen) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => screen),
  ).then((_) => _load());

  int get _score {
    int s = 0;
    if (_waterMl >= 2500) s += 25;
    else s += ((_waterMl / 2500) * 25).round();
    if (_sleep >= 7) s += 25;
    else if (_sleep > 0) s += ((_sleep / 7) * 20).round();
    if (_actMin >= 30) s += 25;
    else s += ((_actMin / 30) * 25).round();
    if (_bmi != null) {
      if (_bmi! >= 18.5 && _bmi! < 25) s += 25;
      else if (_bmi! >= 17 && _bmi! < 30) s += 15;
      else s += 5;
    }
    return s.clamp(0, 100);
  }

  Color _scoreColor(int s) {
    if (s >= 80) return AppTheme.iosGreen;
    if (s >= 60) return AppTheme.iosBlue;
    if (s >= 40) return AppTheme.iosOrange;
    return AppTheme.iosRed;
  }

  String _scoreLabel(int s) {
    if (s >= 80) return 'Sehr gut';
    if (s >= 60) return 'Gut';
    if (s >= 40) return 'OK';
    return 'Verbesserungswürdig';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final top = MediaQuery.of(context).padding.top;
    final score = _score;

    String greeting = now.hour < 12 ? 'Guten Morgen'
        : now.hour < 17 ? 'Guten Tag' : 'Guten Abend';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.iosBlue,
        backgroundColor: AppTheme.bgCard,
        child: CustomScrollView(
          slivers: [
            // ── Large Title Header ──────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, top + 16, 20, 0),
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(greeting,
                          style: AppTheme.caption),
                      const SizedBox(height: 2),
                      const Text('HealthBar',
                          style: AppTheme.headline1),
                    ],
                  )),
                  GestureDetector(
                    onTap: () => _go(const SettingsScreen()),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.glassFill,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppTheme.glassBorder, width: 0.5),
                      ),
                      child: const Icon(Icons.settings_outlined,
                          size: 18, color: AppTheme.textSecondary),
                    ),
                  ),
                ]),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Score + KI-Button ───────────────────────
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Score Ring
                    Expanded(child: GlassCard(
                      child: Column(children: [
                        SizedBox(
                          width: 96, height: 96,
                          child: Stack(fit: StackFit.expand, children: [
                            CircularProgressIndicator(
                              value: score / 100,
                              backgroundColor:
                                  _scoreColor(score).withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation(
                                  _scoreColor(score)),
                              strokeWidth: 7,
                              strokeCap: StrokeCap.round,
                            ),
                            Center(child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$score', style: TextStyle(
                                  color: _scoreColor(score),
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                )),
                                Text('/ 100', style: AppTheme.caption
                                    .copyWith(fontSize: 10)),
                              ],
                            )),
                          ]),
                        ),
                        const SizedBox(height: 10),
                        Text(_scoreLabel(score),
                            style: TextStyle(
                              color: _scoreColor(score),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            )),
                        Text('Gesundheitsscore',
                            style: AppTheme.caption),
                      ]),
                    )),
                    const SizedBox(width: 12),
                    // KI-Arzt Button
                    GestureDetector(
                      onTap: () => _go(const AiChatScreen()),
                      child: GlassCard(
                        glowColor: AppTheme.iosIndigo,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: AppTheme.iosIndigo.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.smart_toy_outlined,
                                  color: AppTheme.iosIndigo, size: 26),
                            ),
                            const SizedBox(height: 10),
                            const Text('KI-Arzt',
                                style: AppTheme.bodyBold),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PulseDot(
                                  size: 6,
                                  color: _hasApiKey
                                      ? AppTheme.iosGreen
                                      : AppTheme.textMuted,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _hasApiKey ? 'Online' : 'Setup',
                                  style: AppTheme.caption.copyWith(
                                    color: _hasApiKey
                                        ? AppTheme.iosGreen
                                        : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // ── Heute — 4 Metriken ──────────────────────
                  Text(
                    DateFormat('EEEE, d. MMMM', 'de_DE').format(now),
                    style: AppTheme.caption,
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.55,
                    children: [
                      _MetricTile(
                        icon: Icons.water_drop_outlined,
                        label: 'Wasser',
                        value: '${(_waterMl / 1000).toStringAsFixed(1)} L',
                        goal: '2.5 L Ziel',
                        progress: _waterMl / 2500,
                        color: AppTheme.iosTeal,
                      ),
                      _MetricTile(
                        icon: Icons.bedtime_outlined,
                        label: 'Schlaf',
                        value: _sleep > 0
                            ? '${_sleep.toStringAsFixed(1)} h'
                            : '—',
                        goal: '7–9 h Ziel',
                        progress: _sleep / 8,
                        color: AppTheme.iosPurple,
                      ),
                      _MetricTile(
                        icon: Icons.directions_walk_outlined,
                        label: 'Schritte',
                        value: NumberFormat('#,###').format(_steps),
                        goal: '10.000 Ziel',
                        progress: _steps / 10000,
                        color: AppTheme.iosGreen,
                      ),
                      _MetricTile(
                        icon: Icons.local_fire_department_outlined,
                        label: 'Kalorien',
                        value: '$_calories kcal',
                        goal: '2.000 Ziel',
                        progress: _calories / 2000,
                        color: AppTheme.iosOrange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── KI Aktionen ─────────────────────────────
                  const Text('KI & Werkzeuge',
                      style: AppTheme.headline3),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.8,
                    children: [
                      _ActionTile(
                        icon: Icons.face_retouching_natural,
                        label: 'Gesichtsscan',
                        color: AppTheme.iosTeal,
                        onTap: () => _go(const FaceScanScreen()),
                      ),
                      _ActionTile(
                        icon: Icons.science_outlined,
                        label: 'Recherche',
                        color: AppTheme.iosYellow,
                        onTap: () => _go(const ResearchScreen()),
                      ),
                      _ActionTile(
                        icon: Icons.summarize_outlined,
                        label: 'KI-Bericht',
                        color: AppTheme.iosTeal,
                        onTap: () => _go(const HealthReportScreen()),
                      ),
                      _ActionTile(
                        icon: Icons.emergency_outlined,
                        label: 'Erste Hilfe',
                        color: AppTheme.iosRed,
                        onTap: () => _go(const FirstAidScreen()),
                      ),
                    ],
                  ),

                  // ── Kein API-Key Hinweis ─────────────────────
                  if (!_hasApiKey) ...[
                    const SizedBox(height: 16),
                    GlassCard(
                      glowColor: AppTheme.iosOrange,
                      onTap: () => _go(const SettingsScreen()),
                      child: Row(children: [
                        const Icon(Icons.key_outlined,
                            color: AppTheme.iosOrange, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('KI einrichten',
                                style: AppTheme.bodyBold),
                            Text(
                              'Kostenlosen Gemini API-Key hinzufügen',
                              style: AppTheme.caption,
                            ),
                          ],
                        )),
                        const Icon(Icons.chevron_right,
                            color: AppTheme.textMuted, size: 18),
                      ]),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label, value, goal;
  final double progress;
  final Color color;

  const _MetricTile({
    required this.icon, required this.label, required this.value,
    required this.goal, required this.progress, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 5),
            Text(label,
                style: AppTheme.caption.copyWith(color: color)),
          ]),
          const Spacer(),
          Text(value, style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: color,
          )),
          const SizedBox(height: 5),
          NeonProgressBar(
              value: progress.clamp(0.0, 1.0), color: color, height: 3),
          const SizedBox(height: 4),
          Text(goal, style: AppTheme.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Text(label, style: AppTheme.bodyBold.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}
