import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Google Gemini 2.0 Flash API Service
/// KOMPLETT KOSTENLOS:
///   - gemini-2.0-flash: 15 RPM, 1 Mio Tokens/Tag, unterstützt Google Search
///   - Kein Abo, keine Kreditkarte
/// API Key holen: https://aistudio.google.com/app/apikey
class GeminiService {
  // gemini-2.0-flash unterstützt Google Search Grounding (kostenlos)
  static const String _model       = 'gemini-2.0-flash';
  static const String _modelVision = 'gemini-2.0-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _apiKeyPref = 'gemini_api_key';

  // ── Medizinischer System-Prompt ──────────────────────────────
  static const String _systemPrompt = '''
Du bist ein hochqualifizierter KI-Medizinassistent der HealthBar-App.
Du hast Zugang zu Google Search und kannst aktiv nach den NEUESTEN wissenschaftlichen Medizin-Publikationen, Studien und Leitlinien suchen.

Deine medizinischen Fachgebiete:
- Innere Medizin, Allgemeinmedizin, Notfallmedizin
- Kardiologie, Neurologie, Onkologie
- Dermatologie, Ophthalmologie (Augenheilkunde)
- Ernährungsmedizin, Sportmedizin, Präventivmedizin
- Pharmakologie, Immunologie, Genetik
- Evidence-based Medicine: PubMed, Cochrane, WHO-Leitlinien

VERHALTENSREGELN:
1. Antworte IMMER auf Deutsch
2. Nutze Google Search aktiv um neueste wissenschaftliche Erkenntnisse zu finden
3. Zitiere Quellen wenn möglich (Studie, Jahr, Journal)
4. Bei ernsthaften Symptomen: "⚠️ Bitte sofort einen Arzt aufsuchen!"
5. Weise immer darauf hin: Diese App ersetzt keinen Arztbesuch
6. Sei präzise, verständlich und hilfreich
7. Nutze Markdown für strukturierte Antworten
''';

  // ── API Key Management ──────────────────────────────────────
  static Future<String?> getSavedApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPref);
  }

  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, key.trim());
  }

  static Future<bool> hasApiKey() async {
    final key = await getSavedApiKey();
    return key != null && key.trim().isNotEmpty;
  }

  // ── Text-Chat ───────────────────────────────────────────────
  /// Medizinischer Chat mit optionalem Verlauf
  static Future<GeminiResponse> chat(
    String userMessage, {
    List<ChatMessage>? history,
    String? customSystemPrompt,
    bool useSearch = false,
  }) async {
    final apiKey = await getSavedApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return GeminiResponse.error(_noKeyError);
    }

    final systemPrompt = customSystemPrompt ?? _systemPrompt;
    final contents = <Map<String, dynamic>>[];

    if (history != null) {
      for (final msg in history) {
        contents.add({
          'role': msg.isUser ? 'user' : 'model',
          'parts': [{'text': msg.text}],
        });
      }
    }

    final fullMessage = (history == null || history.isEmpty)
        ? '$systemPrompt\n\nNutzer: $userMessage'
        : userMessage;

    contents.add({
      'role': 'user',
      'parts': [{'text': fullMessage}],
    });

    return _sendRequest(apiKey, contents, useSearch: useSearch);
  }

  // ── Medizin Deep Research mit Google Search ─────────────────
  /// KI sucht SELBST nach aktuellen wissenschaftlichen Quellen
  static Future<GeminiResponse> deepMedicalResearch(String topic) async {
    final apiKey = await getSavedApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return GeminiResponse.error(_noKeyError);
    }

    final prompt = '''
$_systemPrompt

AUFGABE: Führe eine tiefe wissenschaftliche Medizin-Recherche zu folgendem Thema durch:
"$topic"

Nutze Google Search aktiv um die NEUESTEN Erkenntnisse zu finden.

Strukturiere deine Antwort:

## 🔬 Aktueller Wissenschaftsstand
[Neueste Erkenntnisse aus aktuellen Studien]

## 📊 Schlüsselstudien & Evidenz
[Wichtige Studien mit Quellenangaben: Autor, Jahr, Journal]

## 🏥 Aktuelle Leitlinien
[WHO, DGI, AWMF oder andere anerkannte Leitlinien]

## 💊 Therapieoptionen (Stand der Wissenschaft)
[Evidenzbasierte Behandlungsmethoden]

## ⚠️ Warnsignale & Risikofaktoren
[Wann zum Arzt]

## 🔮 Forschungsausblick
[Was erforscht wird, Trends]

Quellenangaben am Ende.
''';

    final contents = [{
      'role': 'user',
      'parts': [{'text': prompt}],
    }];

    return _sendRequest(apiKey, contents, useSearch: true);
  }

  // ── Gesichtsscan mit Vision ──────────────────────────────────
  static Future<GeminiResponse> analyzeFace(Uint8List imageBytes) async {
    final apiKey = await getSavedApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return GeminiResponse.error(_noKeyError);
    }

    const prompt = '''
$_systemPrompt

Analysiere dieses Gesichtsfoto auf sichtbare medizinische Gesundheitszeichen.
Nutze dein medizinisches Fachwissen für eine systematische Untersuchung:

**👁️ AUGEN & AUGENLIDER:**
- Schwellung der Augenlider → Allergien, Nierenprobleme, Schlafmangel
- Gelbfärbung der Skleren (Augenweiß) → Ikterus/Gelbsucht (Leberfunktion!)
- Rötung der Bindehaut → Konjunktivitis, Allergien, Erschöpfung
- Dunkle Augenringe → Schlafmangel, Anämie, Vitaminmangel
- Herabhängende Lider (Ptosis) → Neurologische Warnung

**🎨 HAUTBILD & GESICHTSFARBE:**
- Blässe → Anämie, Kreislaufprobleme, Eisenmangel
- Rötungen/Flush → Rosacea, Hypertonie, Entzündungen
- Gelbliche Tönung → Leber- / Gallenblasenprobleme
- Trockene / schuppige Haut → Dehydratation, Schilddrüse, Vitaminmangel
- Akne / Ausschläge → Hormonelles Ungleichgewicht, Ernährung

**⚠️ GESICHTSASYMMETRIE (NOTFALL-CHECK):**
- Einseitige Lähmung / herabhängende Gesichtshälfte → SCHLAGANFALL-WARNUNG (FAST!)
- Einseitige Ptosis → Hornersyndrom, Nervenläsion

**💧 WEITERE ZEICHEN:**
- Generalisierte Schwellung → Allergische Reaktion, Ödeme
- Erschöpfte Gesichtszüge → Stress, Überlastung, Krankheit

Gib eine klare, strukturierte Analyse. Triff keine endgültige Diagnose.
Schluss-Hinweis: "⚕️ Diese KI-Analyse ersetzt keine ärztliche Untersuchung."
''';

    final base64Image = base64Encode(imageBytes);
    final contents = [{
      'role': 'user',
      'parts': [
        {'text': prompt},
        {'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image}},
      ],
    }];

    return _sendRequest(apiKey, contents, useSearch: false, isVision: true);
  }

  // ── Symptom-Checker ──────────────────────────────────────────
  static Future<GeminiResponse> checkSymptoms(
    List<String> symptoms, {
    String? additionalInfo,
  }) async {
    final symptomList = symptoms.map((s) => '• $s').join('\n');
    final extra = additionalInfo != null ? '\nZusatzinfo: $additionalInfo' : '';

    return chat(
      '''
Symptom-Analyse mit Deep Research. Symptoms:
$symptomList$extra

## 🔍 Mögliche Ursachen
[Häufig → Selten, mit medizinischer Erklärung]

## ⚠️ Warnzeichen – sofort zum Arzt wenn:
[Klare Liste]

## 💊 Erste Maßnahmen
[Was ich jetzt tun kann]

## 🏥 Empfohlene Facharztrichtung

## 📚 Medizinischer Hintergrund
[Deep Research Erklärung der Pathophysiologie]

## 🔬 Aktuelle Studienerkenntnisse
[Neueste wissenschaftliche Erkenntnisse zu diesen Symptomen]
''',
      useSearch: true,
    );
  }

  // ── Gesundheits-Score ────────────────────────────────────────
  static Future<GeminiResponse> calculateHealthScore({
    required double? bmi,
    required int waterMl,
    required int sleepHours,
    required int activityMinutes,
    required int calories,
  }) async {
    return chat(
      '''
Berechne einen wissenschaftlich fundierten Gesundheits-Score (0-100) basierend auf:
- BMI: ${bmi?.toStringAsFixed(1) ?? 'nicht gemessen'}
- Wasser: ${waterMl}ml (Empfehlung: 2500ml)
- Schlaf: ${sleepHours}h (Empfehlung: 7-9h)
- Bewegung: ${activityMinutes}min (Empfehlung: ≥30min)
- Kalorien: ${calories}kcal

Antworte EXAKT in diesem Format:

**SCORE: [Zahl 0-100]**

## 📊 Bewertung
[2 Sätze mit wissenschaftlicher Begründung]

## ✅ Gut
[Was gut ist und warum laut Forschung]

## 🎯 Verbesserung
[Konkrete, evidenzbasierte Tipps]

## 💡 Top 3 Maßnahmen für heute

## 🔬 Wissenschaftlicher Hintergrund
[Studien-basierte Erklärung]
''',
      useSearch: true,
    );
  }

  // ── Medikamenten-Info ────────────────────────────────────────
  static Future<GeminiResponse> getMedicationInfo(String name) async {
    return chat(
      '''
Recherchiere umfassend das Medikament / den Wirkstoff: "$name"
Nutze Google Search für neueste Informationen.

## 💊 Wirkstoff & Pharmakologie
## 📋 Indikationen (Anwendungsgebiete)
## ⚠️ Nebenwirkungen (häufig / selten / sehr selten)
## 🔄 Wechselwirkungen (Medikamente + Lebensmittel)
## 📏 Dosierung (allgemein, kein Ersatz für Arzt!)
## ❗ Kontraindikationen
## 🔬 Neueste Forschungsergebnisse (laut aktuellen Studien)

Quellen angeben. Hinweis: Beipackzettel und Arztanweisung beachten!
''',
      useSearch: true,
    );
  }

  // ── Interner Request-Handler ─────────────────────────────────
  static Future<GeminiResponse> _sendRequest(
    String apiKey,
    List<Map<String, dynamic>> contents, {
    bool useSearch = false,
    bool isVision = false,
  }) async {
    try {
      final model = isVision ? _modelVision : _model;
      final url = Uri.parse('$_baseUrl/$model:generateContent?key=$apiKey');

      final body = <String, dynamic>{
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 4096,
        },
      };

      // Google Search Grounding aktivieren (kostenfrei mit gemini-2.0-flash)
      if (useSearch) {
        body['tools'] = [
          {'google_search': {}}
        ];
      }

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        // Quellen aus dem Grounding-Metadata extrahieren
        final groundingMeta =
            data['candidates']?[0]?['groundingMetadata'];
        List<String> sources = [];
        if (groundingMeta != null) {
          final chunks = groundingMeta['groundingChunks'] as List? ?? [];
          for (final chunk in chunks) {
            final uri = chunk['web']?['uri'] as String?;
            final title = chunk['web']?['title'] as String?;
            if (uri != null) sources.add('[$title]($uri)');
          }
        }

        if (text != null) {
          final fullText = sources.isNotEmpty
              ? '$text\n\n---\n**🔗 Quellen:**\n${sources.map((s) => '- $s').join('\n')}'
              : text;
          return GeminiResponse.success(fullText, sources: sources);
        }
        return GeminiResponse.error('Leere Antwort von der KI.');
      } else if (response.statusCode == 400) {
        // Fallback ohne Search wenn Google Search nicht verfügbar
        if (useSearch) {
          return _sendRequest(apiKey, contents,
              useSearch: false, isVision: isVision);
        }
        final error = jsonDecode(response.body);
        return GeminiResponse.error(
            'Fehler 400: ${error['error']?['message'] ?? 'Ungültige Anfrage'}');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return GeminiResponse.error(
            'Ungültiger API-Key.\nKostenlos holen: aistudio.google.com/app/apikey');
      } else if (response.statusCode == 429) {
        return GeminiResponse.error(
            'Zu viele Anfragen (Max. 15/Min bei kostenlosem Plan).\nKurz warten und erneut versuchen.');
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        return GeminiResponse.error(
            'Fehler ${response.statusCode}: ${error['error']?['message'] ?? 'Unbekannter Fehler'}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return GeminiResponse.error(
            'Zeitüberschreitung (45s). Internetverbindung prüfen.');
      }
      return GeminiResponse.error('Verbindungsfehler: $e');
    }
  }

  static const String _noKeyError =
      'Kein API-Key gesetzt.\nKostenlos holen: aistudio.google.com/app/apikey\n'
      'Dann in Einstellungen (⚙️) eingeben.';
}

// ── Datenklassen ──────────────────────────────────────────────────

class GeminiResponse {
  final String? text;
  final String? error;
  final bool isSuccess;
  final List<String> sources;

  GeminiResponse.success(this.text, {this.sources = const []})
      : error = null,
        isSuccess = true;

  GeminiResponse.error(this.error)
      : text = null,
        isSuccess = false,
        sources = const [];
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isSearchResult;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isSearchResult = false,
  }) : timestamp = timestamp ?? DateTime.now();
}
