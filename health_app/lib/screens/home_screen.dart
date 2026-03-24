import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import 'bmi_screen.dart';
import 'water_screen.dart';
import 'activity_screen.dart';
import 'sleep_screen.dart';
import 'nutrition_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper();

  int _waterToday = 0;
  int _caloriesToday = 0;
  int _stepsToday = 0;
  double? _lastBmi;
  double _sleepLast = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final water = await _db.getWaterToday();
    final activities = await _db.getActivitiesToday();
    final bmiEntries = await _db.getBmiEntries();
    final sleepEntries = await _db.getSleepEntries();
    final nutrition = await _db.getNutritionToday();

    final totalWater = water.fold(0, (sum, e) => sum + (e['amount_ml'] as int));
    final totalCal = activities.fold(0, (sum, e) => sum + (e['calories_burned'] as int));
    final totalSteps = activities.fold(0, (sum, e) => sum + (e['steps'] as int));
    final totalCalFood = nutrition.fold(0, (sum, e) => sum + (e['calories'] as int));

    setState(() {
      _waterToday = totalWater;
      _caloriesToday = totalCal + totalCalFood;
      _stepsToday = totalSteps;
      _lastBmi = bmiEntries.isNotEmpty ? bmiEntries.first['bmi'] as double : null;
      _sleepLast = sleepEntries.isNotEmpty ? sleepEntries.first['duration_hours'] as double : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d. MMMM yyyy', 'de_DE').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF2E7D5B),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'HealthBar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2E7D5B), Color(0xFF1B5E3B)],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 48),
                        child: Text(
                          today,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text(
                    'Heute im Überblick',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Quick Stats Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _StatCard(
                        title: 'Wasser',
                        value: '${(_waterToday / 1000).toStringAsFixed(1)} L',
                        subtitle: 'Ziel: 2.5 L',
                        icon: Icons.water_drop,
                        color: const Color(0xFF2196F3),
                        progress: (_waterToday / 2500).clamp(0.0, 1.0),
                      ),
                      _StatCard(
                        title: 'Kalorien',
                        value: '$_caloriesToday kcal',
                        subtitle: 'Verbrannt + Gegessen',
                        icon: Icons.local_fire_department,
                        color: const Color(0xFFFF6B35),
                        progress: (_caloriesToday / 2000).clamp(0.0, 1.0),
                      ),
                      _StatCard(
                        title: 'Schritte',
                        value: NumberFormat('#,###').format(_stepsToday),
                        subtitle: 'Ziel: 10.000',
                        icon: Icons.directions_walk,
                        color: const Color(0xFF4CAF50),
                        progress: (_stepsToday / 10000).clamp(0.0, 1.0),
                      ),
                      _StatCard(
                        title: 'Schlaf',
                        value: _sleepLast > 0
                            ? '${_sleepLast.toStringAsFixed(1)} h'
                            : '–',
                        subtitle: 'Letzte Nacht',
                        icon: Icons.bedtime,
                        color: const Color(0xFF9C27B0),
                        progress: (_sleepLast / 8).clamp(0.0, 1.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // BMI Banner
                  if (_lastBmi != null)
                    _BmiBanner(bmi: _lastBmi!)
                  else
                    _BmiPrompt(onTap: () => _navigate(context, const BmiScreen())),
                  const SizedBox(height: 24),
                  const Text(
                    'Module',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Navigation Cards
                  ..._buildModuleCards(context),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildModuleCards(BuildContext context) {
    final modules = [
      _ModuleInfo('BMI Rechner', 'Gewicht & Körpergröße tracken',
          Icons.monitor_weight, const Color(0xFF2E7D5B), const BmiScreen()),
      _ModuleInfo('Wassertracker', 'Tägliche Wasseraufnahme',
          Icons.water_drop, const Color(0xFF2196F3), const WaterScreen()),
      _ModuleInfo('Aktivität', 'Sport & Bewegung erfassen',
          Icons.fitness_center, const Color(0xFFFF6B35), const ActivityScreen()),
      _ModuleInfo('Schlaf', 'Schlafdauer & Qualität',
          Icons.bedtime, const Color(0xFF9C27B0), const SleepScreen()),
      _ModuleInfo('Ernährung', 'Kalorien & Nährstoffe',
          Icons.restaurant, const Color(0xFFF44336), const NutritionScreen()),
    ];

    return modules.map((m) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _ModuleCard(
        info: m,
        onTap: () => _navigate(context, m.screen),
      ),
    )).toList();
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _loadDashboard());
  }
}

// ── Hilfsdaten ───────────────────────────────────────────

class _ModuleInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;
  _ModuleInfo(this.title, this.subtitle, this.icon, this.color, this.screen);
}

// ── Widgets ──────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double progress;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(color: Colors.grey[400], fontSize: 10)),
        ],
      ),
    );
  }
}

class _BmiBanner extends StatelessWidget {
  final double bmi;
  const _BmiBanner({required this.bmi});

  Color get _color {
    if (bmi < 18.5) return const Color(0xFFFF9800);
    if (bmi < 25.0) return const Color(0xFF4CAF50);
    if (bmi < 30.0) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String get _category {
    if (bmi < 18.5) return 'Untergewicht';
    if (bmi < 25.0) return 'Normalgewicht';
    if (bmi < 30.0) return 'Übergewicht';
    return 'Adipositas';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                bmi.toStringAsFixed(1),
                style: TextStyle(
                  color: _color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dein BMI',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              Text(_category,
                  style: TextStyle(
                      color: _color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              Text('Letzter Eintrag',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BmiPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _BmiPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D5B).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF2E7D5B).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.monitor_weight,
                color: Color(0xFF2E7D5B), size: 32),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BMI noch nicht berechnet',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D5B))),
                  Text('Tippe hier um deinen BMI zu berechnen',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Color(0xFF2E7D5B), size: 16),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final _ModuleInfo info;
  final VoidCallback onTap;
  const _ModuleCard({required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: info.color.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: info.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(info.icon, color: info.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A1A2E))),
                  Text(info.subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
