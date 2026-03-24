import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/gemini_service.dart';
import 'settings_screen.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final _controller = TextEditingController();
  final List<String> _symptoms = [];
  final _additionalInfoController = TextEditingController();

  bool _isAnalyzing = false;
  String? _result;
  String? _error;
  bool _hasApiKey = false;

  // Vordefinierte Symptome zum Schnellauswählen
  static const _commonSymptoms = [
    'Kopfschmerzen', 'Fieber', 'Müdigkeit', 'Schwindel',
    'Übelkeit', 'Husten', 'Halsschmerzen', 'Bauchschmerzen',
    'Rückenschmerzen', 'Atemnot', 'Herzrasen', 'Schlafprobleme',
    'Appetitlosigkeit', 'Durchfall', 'Gelenkschmerzen', 'Hautausschlag',
    'Taubheitsgefühl', 'Sehstörungen', 'Ohrenschmerzen', 'Brustschmerzen',
  ];

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  @override
  void dispose() {
    _controller.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _checkApiKey() async {
    final has = await GeminiService.hasApiKey();
    setState(() => _hasApiKey = has);
  }

  void _addSymptom(String symptom) {
    final s = symptom.trim();
    if (s.isEmpty || _symptoms.contains(s)) return;
    setState(() {
      _symptoms.add(s);
      _result = null;
    });
  }

  void _removeSymptom(String symptom) {
    setState(() {
      _symptoms.remove(symptom);
      _result = null;
    });
  }

  Future<void> _analyze() async {
    if (_symptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte mindestens ein Symptom hinzufügen.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_hasApiKey) {
      _showNoKeyDialog();
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _result = null;
      _error = null;
    });

    final additional = _additionalInfoController.text.trim().isNotEmpty
        ? _additionalInfoController.text.trim()
        : null;

    final response = await GeminiService.checkSymptoms(
      _symptoms,
      additionalInfo: additional,
    );

    setState(() {
      _isAnalyzing = false;
      if (response.isSuccess) {
        _result = response.text;
      } else {
        _error = response.error;
      }
    });
  }

  void _showNoKeyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API-Key benötigt'),
        content: const Text(
          'Für den Symptom-Checker wird ein kostenloser Gemini API-Key benötigt.\n\n'
          'Kostenlos holen: aistudio.google.com/app/apikey',
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
                backgroundColor: const Color(0xFFE91E63)),
            child: const Text('Einrichten',
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
        title: const Text('Symptom-Checker'),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_symptoms.isNotEmpty || _result != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _symptoms.clear();
                  _result = null;
                  _error = null;
                  _additionalInfoController.clear();
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Eingabe-Bereich
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Deine Symptome',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    // Eingabe-Feld
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'Symptom eingeben...',
                              prefixIcon: const Icon(Icons.add_circle_outline,
                                  color: Color(0xFFE91E63)),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE91E63), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            onSubmitted: _addSymptom,
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            _addSymptom(_controller.text);
                            _controller.clear();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E63),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                          ),
                          child: const Text('+ Hinzu'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Ausgewählte Symptome
                    if (_symptoms.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _symptoms
                            .map((s) => _SymptomChip(
                                  label: s,
                                  onDelete: () => _removeSymptom(s),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Zusatzinfo
                    TextField(
                      controller: _additionalInfoController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText:
                            'Zusatzinfo (optional): Alter, Vorerkrankungen, seit wann...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Häufige Symptome
            const Text('Häufige Symptome',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonSymptoms.map((s) {
                final selected = _symptoms.contains(s);
                return GestureDetector(
                  onTap: () =>
                      selected ? _removeSymptom(s) : _addSymptom(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFE91E63)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFE91E63)
                            : Colors.grey.shade300,
                      ),
                      boxShadow: [
                        if (!selected)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.grey[700],
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Analyse-Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _analyze,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  _isAnalyzing
                      ? 'KI analysiert (Deep Research)...'
                      : 'KI-Analyse starten (${_symptoms.length} Symptome)',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _symptoms.isEmpty
                      ? Colors.grey
                      : const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Ladeindikator
            if (_isAnalyzing) ...[
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFE91E63))),
                      const SizedBox(height: 16),
                      const Text('Deep Research läuft...',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        'Die KI durchsucht medizinisches Wissen\nund erstellt eine detaillierte Analyse.',
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Fehler
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(_error!,
                            style:
                                const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            ],

            // Ergebnis
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
                              color: const Color(0xFFE91E63).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.medical_information,
                                color: Color(0xFFE91E63), size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Medizinische Deep Research',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      MarkdownBody(
                        data: _result!,
                        styleSheet: MarkdownStyleSheet(
                          h2: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE91E63)),
                          p: const TextStyle(
                              fontSize: 14, height: 1.5),
                          listBullet:
                              const TextStyle(fontSize: 14),
                          strong: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber,
                                color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'WICHTIG: Diese Analyse ist kein Ersatz für einen '
                                'Arztbesuch. Bei ernsthaften Symptomen sofort medizinische Hilfe suchen!',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
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

class _SymptomChip extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;

  const _SymptomChip({required this.label, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE91E63),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}
