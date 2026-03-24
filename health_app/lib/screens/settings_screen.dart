import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _keyCtrl = TextEditingController();
  bool _obscure = true;
  bool _isSaving = false;
  bool _isTesting = false;
  String? _msg;
  bool _msgOk = false;
  String? _savedKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final k = await GeminiService.getSavedApiKey();
    setState(() {
      _savedKey = k;
      if (k != null && k.isNotEmpty) _keyCtrl.text = k;
    });
  }

  Future<void> _save() async {
    final k = _keyCtrl.text.trim();
    if (k.isEmpty) {
      setState(() { _msg = 'Bitte einen API-Key eingeben.'; _msgOk = false; });
      return;
    }
    setState(() => _isSaving = true);
    await GeminiService.saveApiKey(k);
    setState(() {
      _isSaving = false; _savedKey = k;
      _msg = '✅ API-Key gespeichert!'; _msgOk = true;
    });
  }

  Future<void> _test() async {
    final k = _keyCtrl.text.trim();
    if (k.isEmpty) { setState(() { _msg = 'Bitte Key eingeben.'; _msgOk = false; }); return; }

    setState(() { _isTesting = true; _msg = null; });
    await GeminiService.saveApiKey(k);
    final r = await GeminiService.chat('Antworte nur: "✅ Verbindung erfolgreich"');

    setState(() {
      _isTesting = false;
      if (r.isSuccess) {
        _msg = '✅ Verbindung erfolgreich! Gemini 2.0 Flash ist aktiv.';
        _msgOk = true;
        _savedKey = k;
      } else {
        _msg = '❌ ${r.error}';
        _msgOk = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = _savedKey != null && _savedKey!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Einstellungen'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: const NeonDivider(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status ────────────────────────────────────────
            GlassCard(
              glowColor: hasKey ? AppTheme.neonGreen : AppTheme.textMuted,
              glowIntensity: hasKey ? 0.25 : 0.05,
              gradient: LinearGradient(
                colors: [
                  (hasKey ? AppTheme.neonGreen : AppTheme.textMuted)
                      .withOpacity(0.15),
                  (hasKey ? AppTheme.neonGreen : AppTheme.textMuted)
                      .withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Row(
                children: [
                  PulseDot(
                    color: hasKey ? AppTheme.neonGreen : AppTheme.textMuted,
                    size: 12,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasKey ? 'KI aktiv' : 'KI inaktiv',
                        style: TextStyle(
                          color: hasKey
                              ? AppTheme.neonGreen
                              : AppTheme.textSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        hasKey
                            ? 'Google Gemini 2.0 Flash verbunden'
                            : 'API-Key benötigt',
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Kostenlos Badge ───────────────────────────────
            const Text('Google Gemini API-Key',
                style: AppTheme.headline3),
            const SizedBox(height: 4),
            Row(
              children: [
                NeonBadge(label: '100% KOSTENLOS', color: AppTheme.neonGreen),
                const SizedBox(width: 8),
                NeonBadge(
                    label: 'KEINE KREDITKARTE', color: AppTheme.colorWater),
              ],
            ),
            const SizedBox(height: 14),

            // ── Erklärungs-Karte ──────────────────────────────
            GlassCard(
              glowColor: AppTheme.neonGreen,
              glowIntensity: 0.1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: AppTheme.neonGreen, size: 18),
                      SizedBox(width: 8),
                      Text('Was du bekommst (kostenlos):',
                          style: AppTheme.bodyBold),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...[
                    ('⚡', 'Gemini 2.0 Flash',
                        '15 Anfragen/Min, 1 Mio. Tokens/Tag'),
                    ('🔍', 'Google Search Grounding',
                        'KI sucht selbst nach Studien & Quellen'),
                    ('👁️', 'Vision/Bildanalyse',
                        'Gesichtsscan & Bild-Diagnose'),
                    ('🧠', 'Medizin-KI',
                        'Komplettes medizinisches Fachwissen'),
                  ].map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(item.$1,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.$2, style: AppTheme.bodyBold),
                                Text(item.$3, style: AppTheme.caption),
                              ],
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(
                          text: 'https://aistudio.google.com/app/apikey'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Link kopiert → Im Browser öffnen'),
                          backgroundColor: AppTheme.bgCard,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSmall)),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.neonGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                            color: AppTheme.neonGreen.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.open_in_new,
                              color: AppTheme.neonGreen, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'aistudio.google.com/app/apikey',
                            style: TextStyle(
                              color: AppTheme.neonGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.copy,
                              color: AppTheme.neonGreen, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Key Eingabe ───────────────────────────────────
            GlassCard(
              child: Column(
                children: [
                  TextField(
                    controller: _keyCtrl,
                    obscureText: _obscure,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        color: AppTheme.textPrimary,
                        fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'API-Key',
                      hintText: 'AIzaSy...',
                      prefixIcon: const Icon(Icons.key,
                          color: AppTheme.neon, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              (_isTesting || _isSaving) ? null : _test,
                          icon: _isTesting
                              ? const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.neon))
                              : const Icon(Icons.wifi_tethering,
                                  size: 16),
                          label: Text(
                              _isTesting ? 'Teste...' : 'Verbindung testen'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.neon,
                            side: const BorderSide(color: AppTheme.neon),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSmall)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              (_isSaving || _isTesting) ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppTheme.bg))
                              : const Icon(Icons.save_rounded, size: 16),
                          label: Text(
                              _isSaving ? 'Speichert...' : 'Speichern'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neon,
                            foregroundColor: AppTheme.bg,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSmall)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hasKey) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () async {
                          await GeminiService.saveApiKey('');
                          setState(() {
                            _keyCtrl.clear();
                            _savedKey = null;
                            _msg = 'API-Key gelöscht.';
                            _msgOk = false;
                          });
                        },
                        icon: const Icon(Icons.delete_outline,
                            color: AppTheme.colorFood, size: 16),
                        label: const Text('Key löschen',
                            style: TextStyle(color: AppTheme.colorFood)),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Status-Meldung
            if (_msg != null) ...[
              const SizedBox(height: 12),
              GlassCard(
                glowColor: _msgOk ? AppTheme.neonGreen : AppTheme.colorFood,
                glowIntensity: 0.2,
                child: Row(
                  children: [
                    Icon(
                      _msgOk ? Icons.check_circle : Icons.error_outline,
                      color: _msgOk ? AppTheme.neonGreen : AppTheme.colorFood,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_msg!,
                          style: TextStyle(
                            color: _msgOk
                                ? AppTheme.neonGreen
                                : AppTheme.colorFood,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          )),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── Anleitung ──────────────────────────────────────
            const Text('Schritt-für-Schritt', style: AppTheme.headline3),
            const SizedBox(height: 12),
            ...List.generate(
              _steps.length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.neon.withOpacity(0.15),
                        border: Border.all(
                            color: AppTheme.neon.withOpacity(0.4)),
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                color: AppTheme.neon,
                                fontWeight: FontWeight.w800,
                                fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_steps[i].$1, style: AppTheme.bodyBold),
                          Text(_steps[i].$2, style: AppTheme.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _steps = [
    ('Google AI Studio öffnen',
        'aistudio.google.com/app/apikey (Link oben kopieren)'),
    ('Mit Google-Konto anmelden', 'Kostenloses Gmail-Konto reicht aus'),
    ('"Create API key" klicken', 'Key wird sofort erstellt'),
    ('Key kopieren & hier einfügen', 'Dann "Verbindung testen" drücken'),
  ];
}
