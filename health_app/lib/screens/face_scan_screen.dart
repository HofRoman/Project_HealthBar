import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'settings_screen.dart';

class FaceScanScreen extends StatefulWidget {
  const FaceScanScreen({super.key});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  bool _isAnalyzing = false;
  String? _result;
  String? _error;
  bool _hasApiKey = false;
  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;

  // Was die KI analysiert
  static const _checks = [
    ('👁️', 'Augenlider', 'Schwellung, Rötung, Ptosis'),
    ('🎨', 'Hautfarbe', 'Blässe, Gelbsucht, Rötung'),
    ('⚡', 'Asymmetrie', 'Schlaganfall-Früherkennung'),
    ('💧', 'Ödeme', 'Gesichtsschwellung'),
    ('🔍', 'Augenweiß', 'Ikterus-Zeichen'),
  ];

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(_scanCtrl);
    _check();
  }

  @override
  void dispose() { _scanCtrl.dispose(); super.dispose(); }

  Future<void> _check() async {
    final has = await GeminiService.hasApiKey();
    setState(() => _hasApiKey = has);
  }

  Future<void> _pick(ImageSource src) async {
    final picked = await _picker.pickImage(
        source: src, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _result = null;
      _error = null;
    });
  }

  Future<void> _analyze() async {
    if (_imageBytes == null) return;
    if (!_hasApiKey) {
      _showNoKey();
      return;
    }
    setState(() { _isAnalyzing = true; _result = null; _error = null; });
    final r = await GeminiService.analyzeFace(_imageBytes!);
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
            'Gemini Vision API Key benötigt (kostenlos).',
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
                backgroundColor: AppTheme.colorFace,
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
                color: AppTheme.colorFace.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.face_retouching_natural,
                  color: AppTheme.colorFace, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('KI-Gesichtsscan'),
                Text('Gemini Vision • Medizinische Analyse',
                    style: AppTheme.caption),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          children: [
            // Was die KI analysiert
            GlassCard(
              glowColor: AppTheme.colorFace,
              glowIntensity: 0.1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      NeonBadge(label: 'KI VISION', color: AppTheme.colorFace),
                      const SizedBox(width: 8),
                      const Text('Analysiert wird:', style: AppTheme.bodyBold),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _checks
                        .map((c) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.colorFace.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppTheme.colorFace.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(c.$1,
                                      style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 5),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(c.$2,
                                          style: const TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700)),
                                      Text(c.$3,
                                          style: AppTheme.caption
                                              .copyWith(fontSize: 10)),
                                    ],
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Bild-Vorschau
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: _isAnalyzing
                      ? AppTheme.colorFace
                      : AppTheme.glassBorder,
                ),
                boxShadow: _isAnalyzing
                    ? AppTheme.glow(AppTheme.colorFace, intensity: 0.3)
                    : null,
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_imageBytes != null)
                    Image.memory(_imageBytes!, fit: BoxFit.cover)
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.face,
                            size: 72,
                            color: AppTheme.colorFace.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text('Foto aufnehmen oder auswählen',
                            style: AppTheme.bodyBold),
                        const SizedBox(height: 4),
                        const Text(
                            'KI analysiert sichtbare Gesundheitszeichen',
                            style: AppTheme.caption),
                      ],
                    ),
                  // Scan-Linie
                  if (_isAnalyzing)
                    AnimatedBuilder(
                      animation: _scanAnim,
                      builder: (_, __) => Positioned(
                        top: 260 * _scanAnim.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.colorFace,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Aufnahme-Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Kamera'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.colorFace,
                      side: BorderSide(
                          color: AppTheme.colorFace.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Galerie'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.neonBlue,
                      side: BorderSide(
                          color: AppTheme.neonBlue.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall)),
                    ),
                  ),
                ),
              ],
            ),
            if (_imageBytes != null) ...[
              const SizedBox(height: 10),
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
                      ? 'Vision KI analysiert...'
                      : 'KI-Analyse starten'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colorFace,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMid)),
                  ),
                ),
              ),
            ],

            // Analysiert-Indikator
            if (_isAnalyzing) ...[
              const SizedBox(height: 16),
              GlassCard(
                glowColor: AppTheme.colorFace,
                glowIntensity: 0.3,
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.colorFace)),
                    const SizedBox(height: 14),
                    const Text('Gemini Vision analysiert...',
                        style: AppTheme.bodyBold),
                    const SizedBox(height: 6),
                    Text(
                      'Augenlider • Hautfarbe • Asymmetrie\nRötungen • Ödeme • Skleren',
                      style: AppTheme.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            // Fehler
            if (_error != null) ...[
              const SizedBox(height: 14),
              GlassCard(
                glowColor: AppTheme.colorFood,
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppTheme.colorFood),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(_error!,
                          style: const TextStyle(color: AppTheme.colorFood))),
                ]),
              ),
            ],

            // Ergebnis
            if (_result != null) ...[
              const SizedBox(height: 16),
              GlassCard(
                glowColor: AppTheme.colorFace,
                glowIntensity: 0.15,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.colorFace.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.biotech,
                              color: AppTheme.colorFace, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Text('Analyse-Ergebnis',
                            style: AppTheme.headline3),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const NeonDivider(color: AppTheme.colorFace),
                    const SizedBox(height: 14),
                    MarkdownBody(
                      data: _result!,
                      styleSheet: MarkdownStyleSheet(
                        h2: AppTheme.headline3
                            .copyWith(color: AppTheme.colorFace),
                        h3: AppTheme.bodyBold
                            .copyWith(color: AppTheme.neonBlue),
                        p: AppTheme.body.copyWith(
                            color: AppTheme.textPrimary, height: 1.6),
                        strong: AppTheme.bodyBold,
                        listBullet: AppTheme.body
                            .copyWith(color: AppTheme.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.colorActivity.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                            color:
                                AppTheme.colorActivity.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.local_hospital,
                              color: AppTheme.colorActivity, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '⚕️ Diese KI-Analyse ersetzt keine ärztliche Untersuchung.',
                              style: TextStyle(
                                  color: AppTheme.colorActivity,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
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
