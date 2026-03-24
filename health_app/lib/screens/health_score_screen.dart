import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../database/database_helper.dart';
import '../services/gemini_service.dart';
import 'settings_screen.dart';

class HealthScoreScreen extends StatefulWidget {
  const HealthScoreScreen({super.key});

  @override
  State<HealthScoreScreen> createState() => _HealthScoreScreenState();
}

class _HealthScoreScreenState extends State<HealthScoreScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseHelper();

  bool _isLoading = false;
  bool _isAnalyzing = false;
  String? _result;
  String? _error;
  bool _hasApiKey = false;

  // Geladene Daten
  double? _bmi;
  int _waterMl = 0;
  int _sleepHours = 0;
  int _activityMinutes = 0;
  int _calories = 0;
  int? _score;

  late AnimationController _animController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _checkApiKey();
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkApiKey() async {
    final has = await GeminiService.hasApiKey();
    setState(() => _hasApiKey = has);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final bmiEntries = await _db.getBmiEntries();
    final water = await _db.getWaterToday();
    final sleep = await _db.getSleepEntries();
    final activities = await _db.getActivitiesToday();

    setState(() {
      _isLoading = false;
      _bmi = bmiEntries.isNotEmpty ? bmiEntries.first['bmi'] as double : null;
      _waterMl = water.fold(0, (s, e) => s + (e['amount_ml'] as int));
      _sleepHours = sleep.isNotEmpty
          ? (sleep.first['duration_hours'] as double).round()
          : 0;
      _activityMinutes = activities.fold(
          0, (s, e) => s + (e['duration_minutes'] as int));
      _calories = activities.fold(
          0, (s, e) => s + (e['calories_burned'] as int));
    });
  }

  Future<void> _calculateScore() async {
    if (!_hasApiKey) {
      _showNoKeyDialog();
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _result = null;
      _error = null;
      _score = null;
    });

    final response = await GeminiService.calculateHealthScore(
      bmi: _bmi,
      waterMl: _waterMl,
      sleepHours: _sleepHours,
      activityMinutes: _activityMinutes,
      calories: _calories,
    );

    if (response.isSuccess && response.text != null) {
      // Score aus Antwort extrahieren
      final scoreMatch =
          RegExp(r'SCORE:\s*(\d+)').firstMatch(response.text!);
      final extractedScore =
          scoreMatch != null ? int.tryParse(scoreMatch.group(1)!) : null;

      setState(() {
        _isAnalyzing = false;
        _result = response.text;
        _score = extractedScore;
      });

      if (extractedScore != null) {
        _scoreAnimation = Tween<double>(
          begin: 0,
          end: extractedScore / 100,
        ).animate(
          CurvedAnimation(
              parent: _animController, curve: Curves.easeOutCubic),
        );
        _animController.forward(from: 0);
      }
    } else {
      setState(() {
        _isAnalyzing = false;
        _error = response.error;
      });
    }
  }

  void _showNoKeyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API-Key benötigt'),
        content: const Text(
          'Für den KI-Gesundheits-Score wird ein kostenloser '
          'Google Gemini API-Key benötigt.\n\n'
          'Holen: aistudio.google.com/app/apikey',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()))
                  .then((_) => _checkApiKey());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047)),
            child: const Text('Einrichten',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFF8BC34A);
    if (score >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _scoreLabel(int score) {
    if (score >= 80) return 'Ausgezeichnet!';
    if (score >= 60) return 'Gut';
    if (score >= 40) return 'Okay';
    return 'Verbesserungsbedarf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('KI Gesundheits-Score'),
        backgroundColor: const Color(0xFF43A047),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ).then((_) => _checkApiKey()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Score-Anzeige
                  if (_score != null)
                    _ScoreDisplay(
                      score: _score!,
                      animation: _scoreAnimation,
                      controller: _animController,
                    )
                  else
                    _ScorePlaceholder(
                      isAnalyzing: _isAnalyzing,
                      onTap: _calculateScore,
                    ),

                  const SizedBox(height: 16),

                  // Aktuelle Daten
                  _DataSummaryCard(
                    bmi: _bmi,
                    waterMl: _waterMl,
                    sleepHours: _sleepHours,
                    activityMinutes: _activityMinutes,
                    calories: _calories,
                  ),

                  const SizedBox(height: 16),

                  // Analyse-Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _calculateScore,
                      icon: _isAnalyzing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_graph),
                      label: Text(
                        _isAnalyzing
                            ? 'KI berechnet Score...'
                            : _score != null
                                ? 'Score neu berechnen'
                                : 'Gesundheits-Score berechnen',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF43A047),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // Fehler
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ],

                  // KI-Analyse
                  if (_result != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF43A047)
                                        .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.auto_graph,
                                      color: Color(0xFF43A047), size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Text('KI-Gesundheitsanalyse',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 20),
                            MarkdownBody(
                              data: _result!,
                              styleSheet: MarkdownStyleSheet(
                                h2: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF43A047)),
                                p: const TextStyle(
                                    fontSize: 14, height: 1.5),
                                listBullet:
                                    const TextStyle(fontSize: 14),
                                strong: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

// ── Widgets ─────────────────────────────────────────────────────

class _ScoreDisplay extends StatelessWidget {
  final int score;
  final Animation<double> animation;
  final AnimationController controller;

  const _ScoreDisplay({
    required this.score,
    required this.animation,
    required this.controller,
  });

  Color get _color {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFF8BC34A);
    if (score >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String get _label {
    if (score >= 80) return 'Ausgezeichnet!';
    if (score >= 60) return 'Gut';
    if (score >= 40) return 'Okay';
    return 'Verbesserungsbedarf';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: controller,
              builder: (ctx, _) => SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: animation.value,
                      backgroundColor: Colors.grey[200],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_color),
                      strokeWidth: 12,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(animation.value * score).round()}',
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.bold,
                              color: _color,
                            ),
                          ),
                          Text(
                            'von 100',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _color,
              ),
            ),
            Text(
              'Dein heutiger Gesundheits-Score',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScorePlaceholder extends StatelessWidget {
  final bool isAnalyzing;
  final VoidCallback onTap;

  const _ScorePlaceholder(
      {required this.isAnalyzing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.auto_graph,
              size: 80,
              color: isAnalyzing ? const Color(0xFF43A047) : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isAnalyzing
                  ? 'KI berechnet deinen Score...'
                  : 'Noch kein Score berechnet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isAnalyzing) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF43A047)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DataSummaryCard extends StatelessWidget {
  final double? bmi;
  final int waterMl;
  final int sleepHours;
  final int activityMinutes;
  final int calories;

  const _DataSummaryCard({
    required this.bmi,
    required this.waterMl,
    required this.sleepHours,
    required this.activityMinutes,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daten für die Analyse',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _DataRow(Icons.monitor_weight, 'BMI',
                bmi?.toStringAsFixed(1) ?? 'Nicht gemessen',
                const Color(0xFF2E7D5B)),
            _DataRow(Icons.water_drop, 'Wasser heute',
                '$waterMl ml', const Color(0xFF2196F3)),
            _DataRow(Icons.bedtime, 'Schlaf letzte Nacht',
                '$sleepHours Stunden', const Color(0xFF9C27B0)),
            _DataRow(Icons.fitness_center, 'Bewegung heute',
                '$activityMinutes Minuten', const Color(0xFFFF6B35)),
            _DataRow(Icons.local_fire_department, 'Kalorien heute',
                '$calories kcal', const Color(0xFFF44336)),
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DataRow(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
