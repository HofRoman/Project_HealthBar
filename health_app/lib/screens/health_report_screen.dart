import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/vitals_entry.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class HealthReportScreen extends StatefulWidget {
  const HealthReportScreen({super.key});

  @override
  State<HealthReportScreen> createState() => _HealthReportScreenState();
}

class _HealthReportScreenState extends State<HealthReportScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseHelper();
  bool _loading = false;
  String _report = '';
  String _reportDate = '';
  List<String> _sources = [];

  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;

  int _step = 0;
  static const _steps = [
    'Gesundheitsdaten werden gesammelt...',
    'Vitalzeichen analysiert...',
    'KI erstellt deinen Bericht...',
    'Wissenschaftliche Quellen geladen...',
    'Bericht wird formatiert...',
  ];

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _scanAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  Future<String> _buildHealthSummary() async {
    final water = await _db.getWaterToday();
    final acts = await _db.getActivitiesToday();
    final bmis = await _db.getBmiEntries();
    final sleeps = await _db.getSleepEntries();
    final nutrition = await _db.getNutritionToday();
    final vitals = await _db.getVitalsEntries(limit: 5);
    final meds = await _db.getMedications(activeOnly: true);

    final waterMl = water.fold(0, (s, e) => s + (e['amount_ml'] as int));
    final calories = nutrition.fold(0, (s, e) => s + (e['calories'] as int));
    final steps = acts.fold(0, (s, e) => s + (e['steps'] as int));
    final actMin = acts.fold(0, (s, e) => s + (e['duration_minutes'] as int));
    final bmi = bmis.isNotEmpty ? bmis.first['bmi'] : null;
    final weight = bmis.isNotEmpty ? bmis.first['weight'] : null;
    final height = bmis.isNotEmpty ? bmis.first['height'] : null;
    final sleep7 = sleeps.take(7).fold(0.0,
        (s, e) => s + (e['duration_hours'] as num).toDouble()) /
        (sleeps.take(7).length.clamp(1, 7));

    final vitalsEntries = vitals.map(VitalsEntry.fromMap).toList();
    final lastVitals = vitalsEntries.isNotEmpty ? vitalsEntries.first : null;

    final buf = StringBuffer();
    buf.writeln('PATIENTENDATEN (${DateFormat('dd.MM.yyyy').format(DateTime.now())}):');
    buf.writeln();
    buf.writeln('== KÖRPERDATEN ==');
    if (bmi != null) {
      buf.writeln('BMI: ${(bmi as num).toStringAsFixed(1)}');
      buf.writeln('Gewicht: ${weight}kg, Größe: ${height}cm');
    }
    buf.writeln();
    buf.writeln('== HEUTE ==');
    buf.writeln('Wasser: ${waterMl}ml (Ziel: 2500ml)');
    buf.writeln('Kalorien: ${calories}kcal (Ziel: 2000kcal)');
    buf.writeln('Schritte: $steps (Ziel: 10000)');
    buf.writeln('Aktivität: ${actMin}min');
    buf.writeln();
    buf.writeln('== SCHLAF (7-Tage-Ø) ==');
    buf.writeln('Durchschnitt: ${sleep7.toStringAsFixed(1)}h/Nacht');
    if (sleeps.isNotEmpty) {
      buf.writeln('Letzte Nacht: ${(sleeps.first['duration_hours'] as num).toStringAsFixed(1)}h');
      buf.writeln('Qualität: ${sleeps.first['quality']}/5');
    }
    buf.writeln();
    buf.writeln('== VITALZEICHEN ==');
    if (lastVitals != null) {
      if (lastVitals.systolic != null) {
        buf.writeln('Blutdruck: ${lastVitals.bpFormatted} (${lastVitals.bpCategory})');
      }
      if (lastVitals.heartRate != null) {
        buf.writeln('Puls: ${lastVitals.heartRate} bpm (${lastVitals.hrCategory})');
      }
      if (lastVitals.spo2 != null) {
        buf.writeln('SpO₂: ${lastVitals.spo2}%');
      }
      if (lastVitals.temperature != null) {
        buf.writeln('Temperatur: ${lastVitals.temperature!.toStringAsFixed(1)}°C');
      }
    } else {
      buf.writeln('Keine Vitalzeichen erfasst');
    }
    buf.writeln();
    buf.writeln('== MEDIKAMENTE ==');
    if (meds.isEmpty) {
      buf.writeln('Keine Medikamente eingetragen');
    } else {
      for (final m in meds) {
        buf.writeln('• ${m['name']} ${m['dosage']} — ${m['frequency']}, ${m['time_of_day']}');
      }
    }

    return buf.toString();
  }

  Future<void> _generateReport() async {
    final hasKey = await GeminiService.hasApiKey();
    if (!hasKey) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bitte zuerst API-Schlüssel in Einstellungen eingeben'),
          backgroundColor: AppTheme.colorEmergency,
        ));
      }
      return;
    }

    setState(() { _loading = true; _report = ''; _step = 0; });

    // Schritt-Animation
    for (int i = 1; i < _steps.length - 1; i++) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() => _step = i);
    }

    final summary = await _buildHealthSummary();

    final prompt = '''
Du bist ein erfahrener Arzt und erstellst einen professionellen, personalisierten Gesundheitsbericht.

$summary

Erstelle einen detaillierten Gesundheitsbericht auf Deutsch mit folgender Struktur:

## 🏥 Gesamtbewertung
Kurze Zusammenfassung des Gesundheitszustands (1-2 Sätze mit Bewertung 1-10)

## 📊 Analyse der Einzelwerte
Bewerte jeden verfügbaren Messwert einzeln mit ✅ Gut / ⚠️ Verbesserungswürdig / ❌ Kritisch

## 💡 Top 5 Empfehlungen
Konkrete, priorisierte Maßnahmen basierend auf den Daten

## 🧬 Risikobewertung
Potenzielle Gesundheitsrisiken basierend auf den aktuellen Werten und wissenschaftlicher Evidenz

## 📈 Trend-Analyse
Prognose und Entwicklung wenn aktuelle Gewohnheiten beibehalten werden

## 🎯 30-Tage-Plan
Konkrete tägliche/wöchentliche Ziele für die nächsten 30 Tage

**Wichtiger Hinweis:** Füge am Ende einen medizinischen Disclaimer hinzu.

Nutze aktuelle wissenschaftliche Erkenntnisse (WHO-Leitlinien, Cochrane Reviews etc.) für deine Empfehlungen.
    ''';

    if (mounted) setState(() => _step = _steps.length - 1);

    final result = await GeminiService().chat(
      prompt,
      useSearch: true,
    );

    if (mounted) {
      setState(() {
        _loading = false;
        _report = result['text'] ?? 'Fehler beim Erstellen des Berichts';
        _sources = List<String>.from(result['sources'] ?? []);
        _reportDate = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
        _step = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.colorReport.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.summarize,
                color: AppTheme.colorReport, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('KI Gesundheitsbericht'),
        ]),
        actions: [
          if (_report.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy, color: AppTheme.colorReport),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _report));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Bericht kopiert!'),
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(children: [
          if (!_loading && _report.isEmpty) _buildIntro(),
          if (_loading) _buildLoading(),
          if (!_loading && _report.isNotEmpty) _buildReport(),
        ]),
      ),
    );
  }

  Widget _buildIntro() {
    return Column(children: [
      // Hero Card
      GlassCard(
        glowColor: AppTheme.colorReport,
        glowIntensity: 0.25,
        child: Column(children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.colorReport.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.colorReport.withOpacity(0.4), width: 2),
            ),
            child: const Icon(Icons.health_and_safety,
                size: 40, color: AppTheme.colorReport),
          ),
          const SizedBox(height: 16),
          GradientText(
            'Dein KI-Gesundheitsbericht',
            style: AppTheme.headline2,
            gradient: AppTheme.neonGradient(AppTheme.colorReport),
          ),
          const SizedBox(height: 8),
          const Text(
            'Die KI analysiert ALLE deine erfassten Gesundheitsdaten und erstellt einen personalisierten Bericht mit wissenschaftlich fundierten Empfehlungen.',
            style: AppTheme.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const NeonDivider(),
          const SizedBox(height: 14),
          _FeatureRow(Icons.monitor_heart, 'Vitalzeichen & Messungen',
              AppTheme.colorVitals),
          const SizedBox(height: 8),
          _FeatureRow(Icons.bedtime, 'Schlafanalyse', AppTheme.colorSleep),
          const SizedBox(height: 8),
          _FeatureRow(Icons.fitness_center, 'Aktivität & Ernährung',
              AppTheme.colorActivity),
          const SizedBox(height: 8),
          _FeatureRow(Icons.medication, 'Medikamente',
              AppTheme.colorMeds),
          const SizedBox(height: 8),
          _FeatureRow(Icons.science, 'Aktuelle Studien (Google Search)',
              AppTheme.colorResearch),
        ]),
      ),
      const SizedBox(height: 16),

      // Hinweise
      GlassCard(
        glowColor: const Color(0xFFFFB300),
        glowIntensity: 0.12,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFFFB300), size: 22),
          const SizedBox(width: 10),
          const Expanded(child: Text(
            'Dieser Bericht ersetzt keine ärztliche Beratung. Konsultiere bei gesundheitlichen Problemen immer einen Arzt.',
            style: AppTheme.body,
          )),
        ]),
      ),
      const SizedBox(height: 20),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _generateReport,
          icon: const Icon(Icons.auto_awesome, size: 20),
          label: const Text('KI-Bericht erstellen'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.colorReport,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusMid)),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ]);
  }

  Widget _buildLoading() {
    return GlassCard(
      glowColor: AppTheme.colorReport,
      glowIntensity: 0.2,
      child: Column(children: [
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _scanAnim,
          builder: (_, __) => Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100, height: 100,
                child: CircularProgressIndicator(
                  value: null,
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.colorReport.withOpacity(0.4)),
                ),
              ),
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.colorReport.withOpacity(0.1),
                  boxShadow: AppTheme.glow(AppTheme.colorReport,
                      intensity: 0.3 * _scanAnim.value),
                ),
                child: const Icon(Icons.psychology,
                    size: 36, color: AppTheme.colorReport),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('KI erstellt deinen Bericht...',
            style: AppTheme.headline3),
        const SizedBox(height: 20),
        // Step-Anzeige
        ...List.generate(_steps.length, (i) {
          final done = i < _step;
          final current = i == _step;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? AppTheme.neonGreen.withOpacity(0.2)
                      : current
                          ? AppTheme.colorReport.withOpacity(0.2)
                          : AppTheme.glassWhite,
                  border: Border.all(
                    color: done
                        ? AppTheme.neonGreen
                        : current
                            ? AppTheme.colorReport
                            : AppTheme.glassBorder,
                  ),
                ),
                child: Icon(
                  done ? Icons.check : Icons.circle,
                  size: 12,
                  color: done
                      ? AppTheme.neonGreen
                      : current
                          ? AppTheme.colorReport
                          : AppTheme.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _steps[i],
                style: TextStyle(
                  color: done
                      ? AppTheme.neonGreen
                      : current
                          ? AppTheme.colorReport
                          : AppTheme.textMuted,
                  fontSize: 13,
                  fontWeight: current
                      ? FontWeight.w700
                      : FontWeight.normal,
                ),
              ),
            ]),
          );
        }),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _buildReport() {
    return Column(children: [
      // Report-Header
      GlassCard(
        glowColor: AppTheme.colorReport,
        glowIntensity: 0.2,
        child: Row(children: [
          const Icon(Icons.health_and_safety,
              color: AppTheme.colorReport, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dein Gesundheitsbericht', style: AppTheme.bodyBold),
              Text('Erstellt: $_reportDate', style: AppTheme.caption),
              if (_sources.isNotEmpty)
                Text('${_sources.length} Quellen gefunden',
                    style: AppTheme.caption.copyWith(
                        color: AppTheme.colorReport)),
            ],
          )),
          NeonBadge('KI + Search', color: AppTheme.colorReport),
        ]),
      ),
      const SizedBox(height: 12),

      // Bericht-Inhalt
      GlassCard(
        glowColor: AppTheme.colorReport,
        glowIntensity: 0.08,
        child: MarkdownBody(
          data: _report,
          styleSheet: MarkdownStyleSheet(
            h1: const TextStyle(
                color: AppTheme.colorReport,
                fontSize: 20,
                fontWeight: FontWeight.w800),
            h2: const TextStyle(
                color: AppTheme.colorReport,
                fontSize: 16,
                fontWeight: FontWeight.w700),
            h3: const TextStyle(
                color: AppTheme.neon,
                fontSize: 14,
                fontWeight: FontWeight.w600),
            p: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 14, height: 1.6),
            strong: const TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
            listBullet: const TextStyle(color: AppTheme.neon),
            blockquotePadding: const EdgeInsets.all(12),
            blockquoteDecoration: BoxDecoration(
              color: AppTheme.colorReport.withOpacity(0.08),
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusSmall),
              border: const Border(
                left: BorderSide(color: AppTheme.colorReport, width: 3),
              ),
            ),
          ),
        ),
      ),

      // Quellen
      if (_sources.isNotEmpty) ...[
        const SizedBox(height: 12),
        GlassCard(
          glowColor: AppTheme.colorResearch,
          glowIntensity: 0.1,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.science_outlined,
                  color: AppTheme.colorResearch, size: 16),
              const SizedBox(width: 6),
              const Text('Wissenschaftliche Quellen',
                  style: AppTheme.bodyBold),
              const Spacer(),
              NeonBadge('${_sources.length}',
                  color: AppTheme.colorResearch),
            ]),
            const SizedBox(height: 10),
            ..._sources.take(5).map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('•  ',
                    style: TextStyle(color: AppTheme.colorResearch)),
                Expanded(child: Text(s,
                    style: AppTheme.caption.copyWith(
                        color: AppTheme.colorResearch))),
              ]),
            )),
          ]),
        ),
      ],

      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: _generateReport,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Neu erstellen'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.colorReport,
            side: const BorderSide(color: AppTheme.colorReport),
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusMid)),
          ),
        )),
        const SizedBox(width: 10),
        Expanded(child: ElevatedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _report));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Bericht in Zwischenablage kopiert!'),
              behavior: SnackBarBehavior.floating,
            ));
          },
          icon: const Icon(Icons.share, size: 16),
          label: const Text('Kopieren'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.colorReport,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusMid)),
          ),
        )),
      ]),
    ]);
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FeatureRow(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 16),
    ),
    const SizedBox(width: 10),
    Text(label, style: AppTheme.body.copyWith(
        color: AppTheme.textPrimary, fontSize: 13)),
    const Spacer(),
    const Icon(Icons.check_circle, color: AppTheme.neonGreen, size: 16),
  ]);
}
