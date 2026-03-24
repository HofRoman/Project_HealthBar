import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../database/database_helper.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'settings_screen.dart';

class HealthScoreScreen extends StatefulWidget {
  const HealthScoreScreen({super.key});

  @override
  State<HealthScoreScreen> createState() => _HealthScoreScreenState();
}

class _HealthScoreScreenState extends State<HealthScoreScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseHelper();
  bool _isLoading = false, _isAnalyzing = false;
  String? _result, _error;
  bool _hasApiKey = false;
  double? _bmi;
  int _waterMl = 0, _sleepH = 0, _actMin = 0, _calories = 0;
  int? _score;

  late AnimationController _animCtrl;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _scoreAnim = const AlwaysStoppedAnimation(0);
    _checkApiKey();
    _loadData();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  Future<void> _checkApiKey() async {
    final has = await GeminiService.hasApiKey();
    setState(() => _hasApiKey = has);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final bmis = await _db.getBmiEntries();
    final water = await _db.getWaterToday();
    final sleeps = await _db.getSleepEntries();
    final acts = await _db.getActivitiesToday();
    setState(() {
      _isLoading = false;
      _bmi = bmis.isNotEmpty ? bmis.first['bmi'] as double : null;
      _waterMl = water.fold(0, (s, e) => s + (e['amount_ml'] as int));
      _sleepH = sleeps.isNotEmpty
          ? (sleeps.first['duration_hours'] as double).round()
          : 0;
      _actMin = acts.fold(0, (s, e) => s + (e['duration_minutes'] as int));
      _calories = acts.fold(0, (s, e) => s + (e['calories_burned'] as int));
    });
  }

  Future<void> _calculate() async {
    if (!_hasApiKey) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
          title: const Text('API-Key benötigt', style: AppTheme.headline3),
          content: const Text(
              'Gemini API benötigt für KI-Score.',
              style: AppTheme.body),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Abbrechen',
                    style: TextStyle(color: AppTheme.textSecondary))),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ).then((_) => _checkApiKey());
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.colorScore,
                  foregroundColor: AppTheme.bg),
              child: const Text('Einrichten'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() { _isAnalyzing = true; _result = null; _error = null; _score = null; });
    final r = await GeminiService.calculateHealthScore(
      bmi: _bmi,
      waterMl: _waterMl,
      sleepHours: _sleepH,
      activityMinutes: _actMin,
      calories: _calories,
    );
    if (r.isSuccess && r.text != null) {
      final m = RegExp(r'SCORE:\s*(\d+)').firstMatch(r.text!);
      final extracted = m != null ? int.tryParse(m.group(1)!) : null;
      setState(() {
        _isAnalyzing = false;
        _result = r.text;
        _score = extracted;
      });
      if (extracted != null) {
        _scoreAnim = Tween<double>(begin: 0, end: extracted / 100).animate(
          CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
        );
        _animCtrl.forward(from: 0);
      }
    } else {
      setState(() { _isAnalyzing = false; _error = r.error; });
    }
  }

  Color _scoreColor(int s) {
    if (s >= 80) return AppTheme.neonGreen;
    if (s >= 60) return AppTheme.neon;
    if (s >= 40) return const Color(0xFFFFB300);
    return AppTheme.colorFood;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.colorScore.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_graph,
                  color: AppTheme.colorScore, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Gesundheits-Score'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neon)))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                children: [
                  // Score-Anzeige
                  _score != null
                      ? _ScoreRing(
                          score: _score!,
                          animation: _scoreAnim,
                          controller: _animCtrl)
                      : _ScorePlaceholder(isAnalyzing: _isAnalyzing),
                  const SizedBox(height: 16),

                  // Datenzusammenfassung
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Heutige Daten für die KI',
                            style: AppTheme.bodyBold),
                        const SizedBox(height: 10),
                        const NeonDivider(),
                        const SizedBox(height: 10),
                        _DataRow(Icons.monitor_weight, 'BMI',
                            _bmi?.toStringAsFixed(1) ?? '—',
                            AppTheme.colorBmi),
                        _DataRow(Icons.water_drop, 'Wasser',
                            '${_waterMl}ml', AppTheme.colorWater),
                        _DataRow(Icons.bedtime, 'Schlaf',
                            '${_sleepH}h', AppTheme.colorSleep),
                        _DataRow(Icons.fitness_center, 'Bewegung',
                            '${_actMin}min', AppTheme.colorActivity),
                        _DataRow(Icons.local_fire_department, 'Kalorien',
                            '${_calories}kcal', AppTheme.colorFood),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _calculate,
                      icon: _isAnalyzing
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  color: AppTheme.bg, strokeWidth: 2))
                          : const Icon(Icons.auto_graph, size: 18),
                      label: Text(_isAnalyzing
                          ? 'KI berechnet Score...'
                          : _score != null
                              ? 'Score neu berechnen'
                              : 'KI-Score berechnen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.colorScore,
                        foregroundColor: AppTheme.bg,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMid)),
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    GlassCard(
                      glowColor: AppTheme.colorFood,
                      child: Text(_error!,
                          style: const TextStyle(color: AppTheme.colorFood)),
                    ),
                  ],

                  if (_result != null) ...[
                    const SizedBox(height: 16),
                    GlassCard(
                      glowColor: AppTheme.colorScore,
                      glowIntensity: 0.15,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              NeonBadge(
                                  label: 'KI-ANALYSE',
                                  color: AppTheme.colorScore),
                              const SizedBox(width: 8),
                              const Icon(Icons.search,
                                  size: 14,
                                  color: AppTheme.colorResearch),
                              const SizedBox(width: 4),
                              Text('Google Search',
                                  style: AppTheme.caption.copyWith(
                                      color: AppTheme.colorResearch)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          MarkdownBody(
                            data: _result!,
                            styleSheet: MarkdownStyleSheet(
                              h2: AppTheme.headline3.copyWith(
                                  color: AppTheme.colorScore),
                              p: AppTheme.body.copyWith(
                                  color: AppTheme.textPrimary,
                                  height: 1.6),
                              strong: AppTheme.bodyBold,
                              listBullet: AppTheme.body
                                  .copyWith(color: AppTheme.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int score;
  final Animation<double> animation;
  final AnimationController controller;
  const _ScoreRing(
      {required this.score,
      required this.animation,
      required this.controller});

  Color get _c {
    if (score >= 80) return AppTheme.neonGreen;
    if (score >= 60) return AppTheme.neon;
    if (score >= 40) return const Color(0xFFFFB300);
    return AppTheme.colorFood;
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: _c,
      glowIntensity: 0.3,
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) => SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: animation.value,
                    backgroundColor: _c.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(_c),
                    strokeWidth: 10,
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(animation.value * score).round()}',
                          style: TextStyle(
                              color: _c,
                              fontSize: 52,
                              fontWeight: FontWeight.w900),
                        ),
                        Text('von 100',
                            style: AppTheme.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            score >= 80
                ? 'Ausgezeichnet!'
                : score >= 60
                    ? 'Gut'
                    : score >= 40
                        ? 'Okay'
                        : 'Verbesserung',
            style: TextStyle(
                color: _c, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text('Dein KI-Gesundheits-Score',
              style: AppTheme.caption),
        ],
      ),
    );
  }
}

class _ScorePlaceholder extends StatelessWidget {
  final bool isAnalyzing;
  const _ScorePlaceholder({required this.isAnalyzing});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.auto_graph,
                size: 72,
                color: isAnalyzing
                    ? AppTheme.colorScore
                    : AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              isAnalyzing
                  ? 'KI berechnet deinen Score...'
                  : 'Noch kein Score berechnet',
              style: AppTheme.bodyBold,
            ),
            if (isAnalyzing) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.colorScore),
                backgroundColor: AppTheme.glassWhite,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _DataRow(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Text(label, style: AppTheme.body),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ],
      ),
    );
  }
}
