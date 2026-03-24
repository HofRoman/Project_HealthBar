import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/gemini_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _keyController = TextEditingController();
  bool _obscureKey = true;
  bool _isSaving = false;
  bool _isTesting = false;
  String? _status;
  bool _statusIsSuccess = false;
  String? _savedKey;

  @override
  void initState() {
    super.initState();
    _loadSavedKey();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedKey() async {
    final key = await GeminiService.getSavedApiKey();
    setState(() {
      _savedKey = key;
      if (key != null && key.isNotEmpty) {
        _keyController.text = key;
      }
    });
  }

  Future<void> _saveKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _status = 'Bitte einen API-Key eingeben.';
        _statusIsSuccess = false;
      });
      return;
    }

    setState(() => _isSaving = true);
    await GeminiService.saveApiKey(key);
    setState(() {
      _isSaving = false;
      _savedKey = key;
      _status = 'API-Key gespeichert!';
      _statusIsSuccess = true;
    });
  }

  Future<void> _testKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _status = 'Bitte zuerst einen Key eingeben.';
        _statusIsSuccess = false;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _status = null;
    });

    await GeminiService.saveApiKey(key);
    final response = await GeminiService.chat(
      'Antworte nur mit: "Verbindung erfolgreich!"',
    );

    setState(() {
      _isTesting = false;
      if (response.isSuccess) {
        _status = '✅ Verbindung erfolgreich! Die KI ist bereit.';
        _statusIsSuccess = true;
        _savedKey = key;
      } else {
        _status = '❌ Fehler: ${response.error}';
        _statusIsSuccess = false;
      }
    });
  }

  void _clearKey() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API-Key löschen?'),
        content:
            const Text('Alle KI-Funktionen werden deaktiviert.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () async {
              await GeminiService.saveApiKey('');
              setState(() {
                _keyController.clear();
                _savedKey = null;
                _status = 'API-Key gelöscht.';
                _statusIsSuccess = false;
              });
              if (context.mounted) Navigator.pop(ctx);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Einstellungen'),
        backgroundColor: const Color(0xFF455A64),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KI-Status
            _StatusCard(hasKey: _savedKey != null && _savedKey!.isNotEmpty),

            const SizedBox(height: 20),

            // API-Key Abschnitt
            const Text(
              'Google Gemini API-Key',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Erklärungs-Karte
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              color: const Color(0xFFE8F5E9),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Color(0xFF2E7D32), size: 20),
                        SizedBox(width: 8),
                        Text('Komplett KOSTENLOS!',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Gemini 1.5 Flash: 15 Anfragen/Min, 1 Mio. Tokens/Tag gratis\n'
                      '• Keine Kreditkarte nötig\n'
                      '• Keine Kosten, kein Abo',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF1B5E20)),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(const ClipboardData(
                          text: 'https://aistudio.google.com/app/apikey',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Link kopiert! Im Browser öffnen.'),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_new,
                                color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'aistudio.google.com/app/apikey',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Link antippen zum Kopieren, dann im Browser öffnen',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF388E3C)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Eingabefeld
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _keyController,
                      obscureText: _obscureKey,
                      style: const TextStyle(fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        labelText: 'API-Key eingeben',
                        hintText: 'AIzaSy...',
                        prefixIcon: const Icon(Icons.key,
                            color: Color(0xFF455A64)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureKey
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(
                              () => _obscureKey = !_obscureKey),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF455A64), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                (_isTesting || _isSaving) ? null : _testKey,
                            icon: _isTesting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.wifi_tethering),
                            label: Text(
                                _isTesting ? 'Teste...' : 'Testen'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF455A64),
                              side: const BorderSide(
                                  color: Color(0xFF455A64)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                (_isSaving || _isTesting) ? null : _saveKey,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                                _isSaving ? 'Speichert...' : 'Speichern'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF455A64),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_savedKey != null && _savedKey!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: _clearKey,
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 18),
                          label: const Text('API-Key löschen',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Status-Nachricht
            if (_status != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusIsSuccess
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _statusIsSuccess
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFF44336),
                  ),
                ),
                child: Text(
                  _status!,
                  style: TextStyle(
                    color: _statusIsSuccess
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFD32F2F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Anleitung
            const Text('Schritt-für-Schritt Anleitung',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _StepCard(
              step: 1,
              title: 'Google AI Studio öffnen',
              desc: 'Gehe zu aistudio.google.com/app/apikey '
                  '(Link oben kopieren, im Browser öffnen)',
            ),
            _StepCard(
              step: 2,
              title: 'Mit Google anmelden',
              desc:
                  'Kostenloses Google-Konto verwenden (Gmail, etc.)',
            ),
            _StepCard(
              step: 3,
              title: '"Create API key" klicken',
              desc: 'Den generierten Key kopieren',
            ),
            _StepCard(
              step: 4,
              title: 'Key hier einfügen & speichern',
              desc: 'Auf "Testen" klicken um die Verbindung zu prüfen',
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool hasKey;
  const _StatusCard({required this.hasKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasKey
              ? [const Color(0xFF2E7D32), const Color(0xFF43A047)]
              : [const Color(0xFF616161), const Color(0xFF757575)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            hasKey ? Icons.check_circle : Icons.cancel,
            color: Colors.white,
            size: 36,
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasKey ? 'KI aktiv' : 'KI inaktiv',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                hasKey
                    ? 'Google Gemini 1.5 Flash verbunden'
                    : 'API-Key eingeben um KI-Features zu aktivieren',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int step;
  final String title;
  final String desc;

  const _StepCard(
      {required this.step, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF455A64),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(desc,
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
