import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/api_config.dart';
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
  bool _hasKey = false;
  bool _usingBuiltIn = false;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _keyCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final stored = await _getStoredKey();
    final builtIn = ApiConfig.isConfigured;
    setState(() {
      _hasKey = stored != null || builtIn;
      _usingBuiltIn = (stored == null || stored.isEmpty) && builtIn;
      if (stored != null && stored.isNotEmpty) _keyCtrl.text = stored;
    });
  }

  Future<String?> _getStoredKey() async {
    final prefs = await _prefs;
    return prefs.getString('gemini_api_key');
  }

  Future get _prefs async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();
    return prefs;
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
      _isSaving = false;
      _hasKey = true;
      _usingBuiltIn = false;
      _msg = 'API-Key gespeichert.';
      _msgOk = true;
    });
  }

  Future<void> _test() async {
    final k = _keyCtrl.text.trim();
    final key = k.isNotEmpty ? k : (ApiConfig.isConfigured ? ApiConfig.geminiApiKey : null);
    if (key == null) {
      setState(() { _msg = 'Kein API-Key vorhanden.'; _msgOk = false; });
      return;
    }
    setState(() { _isTesting = true; _msg = null; });
    if (k.isNotEmpty) await GeminiService.saveApiKey(k);
    final r = await GeminiService.chat('Antworte nur: OK');
    setState(() {
      _isTesting = false;
      _msgOk = r.isSuccess;
      _msg = r.isSuccess
          ? 'Verbindung erfolgreich — Gemini 2.0 Flash aktiv.'
          : r.error;
      if (r.isSuccess) { _hasKey = true; }
    });
  }

  Future<void> _clearKey() async {
    await GeminiService.saveApiKey('');
    _keyCtrl.clear();
    setState(() {
      _usingBuiltIn = ApiConfig.isConfigured;
      _hasKey = ApiConfig.isConfigured;
      _msg = 'Gespeicherter Key entfernt.';
      _msgOk = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Status-Karte ─────────────────────────────────────
          GlassCard(
            glowColor: _hasKey ? AppTheme.success : AppTheme.warning,
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: (_hasKey ? AppTheme.success : AppTheme.warning)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  _hasKey ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                  color: _hasKey ? AppTheme.success : AppTheme.warning,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasKey ? 'KI-Assistent aktiv' : 'Kein API-Key',
                    style: AppTheme.bodyBold.copyWith(
                      color: _hasKey ? AppTheme.success : AppTheme.warning,
                    ),
                  ),
                  Text(
                    _usingBuiltIn
                        ? 'Eingebetteter Schlüssel wird verwendet'
                        : _hasKey
                            ? 'Benutzerdefinierter Key aktiv'
                            : 'Key erforderlich für KI-Funktionen',
                    style: AppTheme.caption,
                  ),
                ],
              )),
              Row(children: [
                PulseDot(
                  color: _hasKey ? AppTheme.success : AppTheme.warning,
                  size: 8,
                ),
                const SizedBox(width: 6),
                Text(
                  _hasKey ? 'Online' : 'Offline',
                  style: AppTheme.caption.copyWith(
                    color: _hasKey ? AppTheme.success : AppTheme.warning,
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 24),

          // ── API Key Bereich ───────────────────────────────────
          Row(children: [
            const Text('Google Gemini API-Key', style: AppTheme.headline3),
            const Spacer(),
            NeonBadge('Kostenlos', color: AppTheme.success),
          ]),
          const SizedBox(height: 12),

          // Eingebetteter Key Hinweis
          if (ApiConfig.isConfigured)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                glowColor: AppTheme.primary,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppTheme.primary, size: 16),
                    const SizedBox(width: 10),
                    const Expanded(child: Text(
                      'Ein Schlüssel ist bereits in der App hinterlegt. '
                      'Du kannst optional einen eigenen Key eingeben.',
                      style: AppTheme.body,
                    )),
                  ],
                ),
              ),
            ),

          GlassCard(
            child: Column(children: [
              TextField(
                controller: _keyCtrl,
                obscureText: _obscure,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    color: AppTheme.textPrimary,
                    fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'API-Key',
                  hintText: ApiConfig.isConfigured
                      ? '(Eingebetteter Key aktiv — optional überschreiben)'
                      : 'AIzaSy...',
                  prefixIcon: const Icon(Icons.key,
                      color: AppTheme.primary, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                      color: AppTheme.textSecondary, size: 18,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: (_isTesting || _isSaving) ? null : _test,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.primary))
                      : const Icon(Icons.wifi_tethering, size: 16),
                  label: Text(_isTesting ? 'Teste...' : 'Testen'),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton.icon(
                  onPressed: (_isSaving || _isTesting) ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 16),
                  label: Text(_isSaving ? 'Speichert...' : 'Speichern'),
                )),
              ]),
              if (_keyCtrl.text.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearKey,
                  icon: const Icon(Icons.delete_outline,
                      color: AppTheme.danger, size: 16),
                  label: const Text('Key entfernen',
                      style: TextStyle(color: AppTheme.danger, fontSize: 12)),
                ),
            ]),
          ),

          // Feedback
          if (_msg != null) ...[
            const SizedBox(height: 12),
            GlassCard(
              glowColor: _msgOk ? AppTheme.success : AppTheme.danger,
              child: Row(children: [
                Icon(
                  _msgOk ? Icons.check_circle_outline : Icons.error_outline,
                  color: _msgOk ? AppTheme.success : AppTheme.danger,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(_msg!,
                    style: TextStyle(
                      color: _msgOk ? AppTheme.success : AppTheme.danger,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ))),
              ]),
            ),
          ],

          const SizedBox(height: 28),

          // ── Key holen ─────────────────────────────────────────
          const Text('Kostenlosen Key erhalten', style: AppTheme.headline3),
          const SizedBox(height: 12),
          GlassCard(
            glowColor: AppTheme.primary,
            child: Column(children: [
              ..._steps.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withOpacity(0.12),
                        border: Border.all(
                            color: AppTheme.primary.withOpacity(0.4)),
                      ),
                      child: Center(child: Text(
                        '${e.key + 1}',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.value.$1, style: AppTheme.bodyBold),
                        Text(e.value.$2, style: AppTheme.caption),
                      ],
                    )),
                  ],
                ),
              )),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(const ClipboardData(
                      text: 'https://aistudio.google.com/app/apikey'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link in Zwischenablage kopiert'),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.link, color: AppTheme.primary, size: 15),
                    SizedBox(width: 8),
                    Expanded(child: Text(
                      'aistudio.google.com/app/apikey',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    )),
                    Icon(Icons.copy_outlined,
                        color: AppTheme.primary, size: 14),
                  ]),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // ── App-Info ──────────────────────────────────────────
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Über HealthBar', style: AppTheme.bodyBold),
                const SizedBox(height: 8),
                const NeonDivider(),
                const SizedBox(height: 8),
                _InfoRow('KI-Modell', 'Google Gemini 2.0 Flash'),
                _InfoRow('Version', '3.0.0'),
                _InfoRow('Plattformen',
                    'Android · iOS · Windows · macOS · Linux'),
                _InfoRow('Datenbank', 'SQLite (lokal, privat)'),
                _InfoRow('Datenschutz',
                    'Alle Daten bleiben auf deinem Gerät'),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  static const _steps = [
    ('Google AI Studio öffnen',
        'aistudio.google.com/app/apikey — Link oben antippen'),
    ('Mit Google-Konto anmelden',
        'Ein kostenloses Gmail-Konto reicht aus'),
    ('"Create API key" klicken',
        'Schlüssel wird sofort erstellt'),
    ('Key kopieren & oben einfügen',
        'Dann auf "Testen" drücken'),
  ];
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(children: [
      SizedBox(
        width: 110,
        child: Text(label, style: AppTheme.caption),
      ),
      Expanded(child: Text(value, style: AppTheme.bodyBold.copyWith(
          fontSize: 12))),
    ]),
  );
}
