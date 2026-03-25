import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'settings_screen.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final _ctrl = TextEditingController();
  final _addInfoCtrl = TextEditingController();
  final List<String> _symptoms = [];
  bool _isAnalyzing = false;
  String? _result;
  String? _error;
  bool _hasApiKey = false;

  static const _common = [
    'Kopfschmerzen', 'Fieber', 'Müdigkeit', 'Schwindel', 'Übelkeit',
    'Husten', 'Halsschmerzen', 'Bauchschmerzen', 'Rückenschmerzen',
    'Atemnot', 'Herzrasen', 'Schlafprobleme', 'Appetitlosigkeit',
    'Durchfall', 'Gelenkschmerzen', 'Hautausschlag', 'Brustschmerzen',
    'Taubheitsgefühl', 'Sehstörungen', 'Ohrenschmerzen',
  ];

  @override
  void initState() { super.initState(); _check(); }

  @override
  void dispose() { _ctrl.dispose(); _addInfoCtrl.dispose(); super.dispose(); }

  Future<void> _check() async {
    final has = await GeminiService.hasApiKey();
    setState(() => _hasApiKey = has);
  }

  void _add(String s) {
    final t = s.trim();
    if (t.isEmpty || _symptoms.contains(t)) return;
    setState(() { _symptoms.add(t); _result = null; });
  }

  void _remove(String s) => setState(() { _symptoms.remove(s); _result = null; });

  Future<void> _analyze() async {
    if (_symptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mindestens ein Symptom hinzufügen'),
          backgroundColor: AppTheme.bgCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
        ),
      );
      return;
    }
    if (!_hasApiKey) { _showNoKey(); return; }

    setState(() { _isAnalyzing = true; _result = null; _error = null; });
    final r = await GeminiService.checkSymptoms(
      _symptoms,
      additionalInfo: _addInfoCtrl.text.trim().isNotEmpty
          ? _addInfoCtrl.text.trim()
          : null,
    );
    setState(() {
      _isAnalyzing = false;
      if (r.isSuccess) _result = r.text; else _error = r.error;
    });
  }

  void _showNoKey() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: const Text('API-Key benötigt', style: AppTheme.headline3),
        content: const Text(
            'Für Deep Research wird ein kostenloser Gemini Key benötigt.',
            style: AppTheme.body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen',
                  style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()))
                  .then((_) => _check());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colorSymptom,
                foregroundColor: Colors.white),
            child: const Text('Einrichten'),
          ),
        ],
      ),
    );
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
                color: AppTheme.colorSymptom.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.medical_information,
                  color: AppTheme.colorSymptom, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Symptom-Checker'),
          ],
        ),
        actions: [
          if (_symptoms.isNotEmpty || _result != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
              onPressed: () => setState(() {
                _symptoms.clear(); _result = null;
                _error = null; _addInfoCtrl.clear();
              }),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Eingabe
            GlassCard(
              glowColor: AppTheme.colorSymptom,
              glowIntensity: 0.1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Symptome eingeben', style: AppTheme.bodyBold),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          style: AppTheme.body
                              .copyWith(color: AppTheme.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Symptom eingeben...',
                            prefixIcon: Icon(Icons.add,
                                color: AppTheme.colorSymptom, size: 18),
                          ),
                          onSubmitted: (v) {
                            _add(v); _ctrl.clear();
                          },
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () { _add(_ctrl.text); _ctrl.clear(); },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.colorSymptom,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSmall)),
                        ),
                        child: const Text('+ Add'),
                      ),
                    ],
                  ),
                  if (_symptoms.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _symptoms
                          .map((s) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.colorSymptom.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppTheme.colorSymptom
                                          .withOpacity(0.5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(s,
                                        style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => _remove(s),
                                      child: const Icon(Icons.close,
                                          size: 14,
                                          color: AppTheme.colorSymptom),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addInfoCtrl,
                    maxLines: 2,
                    style:
                        AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText:
                          'Zusatzinfo (optional): Alter, Dauer, Vorerkrankungen...',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Häufige Symptome
            const Text('Häufige Symptome', style: AppTheme.headline3),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _common.map((s) {
                final sel = _symptoms.contains(s);
                return GestureDetector(
                  onTap: () => sel ? _remove(s) : _add(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.colorSymptom
                          : AppTheme.glassWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel
                            ? AppTheme.colorSymptom
                            : AppTheme.glassBorder,
                      ),
                    ),
                    child: Text(s,
                        style: TextStyle(
                          color: sel
                              ? Colors.white
                              : AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: sel
                              ? FontWeight.w700
                              : FontWeight.normal,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Analyse-Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _analyze,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.biotech, size: 18),
                label: Text(_isAnalyzing
                    ? 'Deep Research läuft...'
                    : 'KI-Analyse (${_symptoms.length} Symptome)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _symptoms.isEmpty
                      ? AppTheme.textMuted
                      : AppTheme.colorSymptom,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMid)),
                ),
              ),
            ),

            // Lade-State
            if (_isAnalyzing) ...[
              const SizedBox(height: 16),
              GlassCard(
                glowColor: AppTheme.colorSymptom,
                glowIntensity: 0.25,
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.colorSymptom)),
                    const SizedBox(height: 14),
                    const Text('Deep Research läuft...',
                        style: AppTheme.bodyBold),
                    const SizedBox(height: 6),
                    Text(
                      'KI durchsucht PubMed, WHO, Cochrane\nund kompiliert medizinische Ergebnisse',
                      style: AppTheme.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            // Fehler
            if (_error != null) ...[
              const SizedBox(height: 16),
              GlassCard(
                glowColor: AppTheme.colorFood,
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.colorFood),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: AppTheme.colorFood))),
                ]),
              ),
            ],

            // Ergebnis
            if (_result != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  NeonBadge(
                      label: 'DEEP RESEARCH',
                      color: AppTheme.colorSymptom),
                  const SizedBox(width: 8),
                  const Icon(Icons.search,
                      size: 14, color: AppTheme.colorResearch),
                  const SizedBox(width: 4),
                  Text('Google Search aktiv',
                      style: AppTheme.caption.copyWith(
                          color: AppTheme.colorResearch)),
                ],
              ),
              const SizedBox(height: 10),
              GlassCard(
                glowColor: AppTheme.colorSymptom,
                glowIntensity: 0.12,
                padding: const EdgeInsets.all(18),
                child: MarkdownBody(
                  data: _result!,
                  styleSheet: MarkdownStyleSheet(
                    h2: AppTheme.headline3.copyWith(
                        color: AppTheme.colorSymptom),
                    h3: AppTheme.bodyBold
                        .copyWith(color: AppTheme.neonBlue),
                    p: AppTheme.body.copyWith(
                        color: AppTheme.textPrimary, height: 1.6),
                    strong: AppTheme.bodyBold,
                    listBullet: AppTheme.body
                        .copyWith(color: AppTheme.textPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GlassCard(
                hasBorder: false,
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  const Icon(Icons.warning_amber,
                      color: AppTheme.colorActivity, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Diese KI-Analyse ersetzt keinen Arztbesuch. '
                      'Bei ernsthaften Symptomen sofort medizinische Hilfe!',
                      style: AppTheme.caption.copyWith(
                          color: AppTheme.colorActivity),
                    ),
                  ),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
