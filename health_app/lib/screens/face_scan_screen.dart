import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/gemini_service.dart';
import 'settings_screen.dart';

class FaceScanScreen extends StatefulWidget {
  const FaceScanScreen({super.key});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  final _picker = ImagePicker();

  Uint8List? _imageBytes;
  String? _imagePath;
  bool _isAnalyzing = false;
  String? _analysisResult;
  String? _errorMessage;
  bool _hasApiKey = false;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    final has = await GeminiService.hasApiKey();
    setState(() => _hasApiKey = has);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imagePath = picked.path;
        _analysisResult = null;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Fehler beim Laden des Bildes: $e');
    }
  }

  Future<void> _analyze() async {
    if (_imageBytes == null) return;
    if (!_hasApiKey) {
      _showNoKeyDialog();
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
      _errorMessage = null;
    });

    final response = await GeminiService.analyzeFace(_imageBytes!);

    setState(() {
      _isAnalyzing = false;
      if (response.isSuccess) {
        _analysisResult = response.text;
      } else {
        _errorMessage = response.error;
      }
    });
  }

  void _showNoKeyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API-Key benötigt'),
        content: const Text(
          'Für den KI-Gesichtsscan wird ein kostenloser Google Gemini API-Key benötigt.\n\n'
          'Kostenlos holen unter:\naistudio.google.com/app/apikey',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) => _checkApiKey());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B)),
            child: const Text('Einstellungen',
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
        title: const Text('KI-Gesichtsscan'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ).then((_) => _checkApiKey()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Erklärungskarte
            _InfoBanner(),
            const SizedBox(height: 16),

            // Bild-Vorschau
            _ImagePreview(
              imageBytes: _imageBytes,
              imagePath: _imagePath,
            ),
            const SizedBox(height: 16),

            // Aufnahme-Buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Kamera',
                    icon: Icons.camera_alt,
                    color: const Color(0xFF00897B),
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: 'Galerie',
                    icon: Icons.photo_library,
                    color: const Color(0xFF0288D1),
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Analyse-Button
            if (_imageBytes != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _analyze,
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.biotech),
                  label: Text(
                    _isAnalyzing
                        ? 'KI analysiert...'
                        : 'KI-Analyse starten',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
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
              const SizedBox(height: 24),
              const _AnalyzingIndicator(),
            ],

            // Fehler
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _ErrorCard(message: _errorMessage!),
            ],

            // KI-Ergebnis
            if (_analysisResult != null) ...[
              const SizedBox(height: 16),
              _ResultCard(result: _analysisResult!),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ─────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF00897B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF00897B).withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF00897B), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Die KI analysiert dein Gesicht auf sichtbare Gesundheitszeichen: '
              'Augenschwellungen, Hautfarbe, Asymmetrie und mehr.',
              style: TextStyle(fontSize: 12, color: Color(0xFF004D40)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? imagePath;

  const _ImagePreview({this.imageBytes, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.hardEdge,
      child: imageBytes != null
          ? Image.memory(
              imageBytes!,
              fit: BoxFit.cover,
              width: double.infinity,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.face, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'Kein Bild ausgewählt',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mache ein Foto oder wähle eines aus der Galerie',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.4)),
        ),
        textStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }
}

class _AnalyzingIndicator extends StatelessWidget {
  const _AnalyzingIndicator();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00897B))),
            const SizedBox(height: 16),
            const Text('KI analysiert dein Gesicht...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Gemini Vision prüft:\nAugenlider • Hautfarbe • Asymmetrie • Rötungen',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFEBEE),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFD32F2F)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Color(0xFFB71C1C)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: const Color(0xFF00897B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.biotech,
                      color: Color(0xFF00897B), size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'KI-Analyse Ergebnis',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            MarkdownBody(
              data: result,
              styleSheet: MarkdownStyleSheet(
                h2: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00897B)),
                p: const TextStyle(fontSize: 14, height: 1.5),
                listBullet: const TextStyle(fontSize: 14),
                strong: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_hospital,
                      color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Diese KI-Analyse ersetzt keine ärztliche Untersuchung.',
                      style: TextStyle(
                          color: Colors.orange,
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
    );
  }
}
