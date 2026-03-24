import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Google Gemini 1.5 Flash API Service
/// KOMPLETT KOSTENLOS: 15 Anfragen/Min, 1 Million Tokens/Tag
/// API Key kostenlos holen: https://aistudio.google.com/app/apikey
class GeminiService {
  static const String _model = 'gemini-1.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _apiKeyPref = 'gemini_api_key';

  // Medizinisches System-Prompt – macht die KI zum Gesundheitsexperten
  static const String _medicalSystemPrompt = '''
Du bist ein hochqualifizierter medizinischer KI-Assistent der HealthBar-App.
Du hast umfassendes Wissen in allen medizinischen Fachgebieten:
- Innere Medizin, Allgemeinmedizin, Kardiologie, Neurologie
- Dermatologie, Ophthalmologie (Augenheilkunde)
- Ernährungsmedizin, Sportmedizin, Präventivmedizin
- Pharmakologie (Medikamente, Wechselwirkungen)
- Erste Hilfe und Notfallmedizin

WICHTIGE REGELN:
1. Antworte IMMER auf Deutsch
2. Sei präzise, verständlich und hilfreich
3. Füge bei ernsten Symptomen IMMER den Hinweis ein: "Bitte suche sofort einen Arzt auf!"
4. Diese App ersetzt KEINEN Arztbesuch – weise darauf hin wenn angebracht
5. Nutze dein Wissen für Deep Research: erkläre Hintergründe, Ursachen, Behandlungsoptionen
6. Bei Bildanalysen: sei detailliert aber sachlich, ohne Panikmache
''';

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
    return key != null && key.isNotEmpty;
  }

  /// Text-Anfrage an Gemini (Medizinischer Chat, Symptom-Checker, etc.)
  static Future<GeminiResponse> chat(
    String userMessage, {
    List<ChatMessage>? history,
    String? customSystemPrompt,
  }) async {
    final apiKey = await getSavedApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return GeminiResponse.error('Kein API-Key gesetzt. Bitte in Einstellungen eingeben.');
    }

    final systemPrompt = customSystemPrompt ?? _medicalSystemPrompt;

    // Konversationsverlauf aufbauen
    final contents = <Map<String, dynamic>>[];

    // Vorherige Nachrichten
    if (history != null) {
      for (final msg in history) {
        contents.add({
          'role': msg.isUser ? 'user' : 'model',
          'parts': [{'text': msg.text}],
        });
      }
    }

    // Aktuelle Nachricht mit System-Prompt
    final fullMessage = history == null || history.isEmpty
        ? '$systemPrompt\n\nNutzer: $userMessage'
        : userMessage;

    contents.add({
      'role': 'user',
      'parts': [{'text': fullMessage}],
    });

    return _sendRequest(apiKey, contents);
  }

  /// Bildanalyse mit Gemini Vision (Gesichtsscan, Hautanalyse, etc.)
  static Future<GeminiResponse> analyzeImage(
    Uint8List imageBytes, {
    required String analysisPrompt,
  }) async {
    final apiKey = await getSavedApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return GeminiResponse.error('Kein API-Key gesetzt. Bitte in Einstellungen eingeben.');
    }

    final base64Image = base64Encode(imageBytes);

    final contents = [
      {
        'role': 'user',
        'parts': [
          {'text': '$_medicalSystemPrompt\n\n$analysisPrompt'},
          {
            'inline_data': {
              'mime_type': 'image/jpeg',
              'data': base64Image,
            }
          },
        ],
      }
    ];

    return _sendRequest(apiKey, contents);
  }

  /// Gesichtsscan – analysiert sichtbare Gesundheitszeichen im Gesicht
  static Future<GeminiResponse> analyzeFace(Uint8List imageBytes) async {
    const prompt = '''
Analysiere dieses Gesichtsfoto auf sichtbare medizinische Gesundheitszeichen.
Untersuche systematisch folgende Bereiche:

**👁️ AUGEN & AUGENLIDER:**
- Schwellung der Augenlider (Ödeme) → mögliche Allergien, Nierenprobleme, Schlafmangel
- Rötung der Augen → Bindehautentzündung, Erschöpfung, Allergien
- Gelbfärbung der Augenweiß (Skleren) → Leberfunktion (Ikterus/Gelbsucht)
- Dunkle Ringe → Schlafmangel, Erschöpfung, Vitaminmangel
- Herunterhängende Augenlider (Ptosis) → neurologische Warnsignale

**🎨 HAUT & GESICHTSFARBE:**
- Blässe → mögliche Anämie, Kreislaufprobleme
- Rötung → Entzündung, Fieber, Rosacea, Bluthochdruck
- Gelbliche Tönung → Leber- oder Gallenblasenprobleme
- Trockene/schuppige Haut → Dehydratation, Vitaminmangel
- Akne oder Ausschläge → Hormonelles Ungleichgewicht

**🧠 GESICHTSASYMMETRIE:**
- Ungleichmäßige Gesichtshälfte → SOFORT Arzt: möglicher Schlaganfall (FAST-Check)
- Hängendes Augenlid auf einer Seite → neurologische Warnung

**💧 ALLGEMEINE ZEICHEN:**
- Geschwollenes Gesicht (generell) → Allergische Reaktion, Nierenprobleme
- Erschöpfungszeichen, müder Gesichtsausdruck

Gib eine strukturierte, detaillierte Analyse. Wenn du nichts Auffälliges siehst, sage das klar.
WICHTIGER HINWEIS AM ENDE: "⚕️ Diese Analyse ist kein Ersatz für eine ärztliche Untersuchung."
''';

    return analyzeImage(imageBytes, analysisPrompt: prompt);
  }

  /// Symptom-Checker – tiefe medizinische Recherche zu Symptomen
  static Future<GeminiResponse> checkSymptoms(
    List<String> symptoms, {
    String? additionalInfo,
  }) async {
    final symptomList = symptoms.map((s) => '• $s').join('\n');
    final extra = additionalInfo != null ? '\nZusatzinfo: $additionalInfo' : '';

    final prompt = '''
Führe eine tiefe medizinische Analyse für folgende Symptome durch:

$symptomList$extra

Strukturiere deine Antwort so:
**🔍 MÖGLICHE URSACHEN** (von häufig bis selten):
[Liste mit Erklärungen]

**⚠️ WARNSIGNALE** (wann sofort zum Arzt):
[Klare Liste]

**💊 ERSTE MASSNAHMEN** (was ich jetzt tun kann):
[Praktische Tipps]

**🏥 EMPFOHLENE FACHRICHTUNG:**
[Welcher Arzt ist zuständig]

**📚 HINTERGRUNDWISSEN:**
[Medizinische Erklärung der Symptome]

Sei präzise und vollständig. Nutze dein medizinisches Fachwissen für echte Deep Research.
''';

    return chat(prompt);
  }

  /// Gesundheits-Score berechnen basierend auf App-Daten
  static Future<GeminiResponse> calculateHealthScore({
    required double? bmi,
    required int waterMl,
    required int sleepHours,
    required int activityMinutes,
    required int calories,
  }) async {
    final prompt = '''
Berechne einen umfassenden Gesundheits-Score (0-100) basierend auf diesen Tageswerten:

- BMI: ${bmi?.toStringAsFixed(1) ?? 'nicht gemessen'}
- Wasseraufnahme: ${waterMl}ml (Empfehlung: 2500ml)
- Schlafdauer: ${sleepHours}h (Empfehlung: 7-9h)
- Bewegung/Sport: ${activityMinutes} Minuten (Empfehlung: 30min)
- Kalorien: ${calories} kcal

Antworte NUR in diesem Format:

**SCORE: [Zahl 0-100]**

**📊 BEWERTUNG:**
[2 Sätze Gesamteinschätzung]

**✅ GUT:**
[Was gut ist]

**⚠️ VERBESSERUNGSPOTENZIAL:**
[Was verbessert werden sollte]

**💡 TOP 3 TIPPS FÜR HEUTE:**
1. [Konkreter Tipp]
2. [Konkreter Tipp]
3. [Konkreter Tipp]

**🔬 MEDIZINISCHER HINTERGRUND:**
[Kurze Erklärung warum diese Werte wichtig sind]
''';

    return chat(prompt);
  }

  /// Medikamenten-Info
  static Future<GeminiResponse> getMedicationInfo(String medicationName) async {
    final prompt = '''
Gib mir umfassende medizinische Informationen zu diesem Medikament: "$medicationName"

**💊 WIRKSTOFF & WIRKUNG:**
[Wie wirkt es, was macht es im Körper]

**📋 ANWENDUNGSGEBIETE:**
[Wofür wird es eingesetzt]

**⚠️ NEBENWIRKUNGEN:**
[Häufige und seltene Nebenwirkungen]

**🔄 WECHSELWIRKUNGEN:**
[Mit welchen anderen Medikamenten/Lebensmitteln nicht kombinieren]

**📏 DOSIERUNG (allgemein):**
[Typische Dosierung – kein Ersatz für Beipackzettel!]

**❗ KONTRAINDIKATIONEN:**
[Wer sollte es nicht nehmen]

Hinweis am Ende: Befolge immer die Anweisung deines Arztes und den Beipackzettel.
''';

    return chat(prompt);
  }

  // ── Interne Methode ────────────────────────────────────────────

  static Future<GeminiResponse> _sendRequest(
    String apiKey,
    List<Map<String, dynamic>> contents,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$apiKey');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': contents,
              'generationConfig': {
                'temperature': 0.7,
                'topK': 40,
                'topP': 0.95,
                'maxOutputTokens': 2048,
              },
              'safetySettings': [
                {
                  'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
                  'threshold': 'BLOCK_ONLY_HIGH',
                },
                {
                  'category': 'HARM_CATEGORY_MEDICAL',
                  'threshold': 'BLOCK_NONE',
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null) {
          return GeminiResponse.success(text);
        }
        return GeminiResponse.error('Leere Antwort von der KI.');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return GeminiResponse.error(
            'Ungültiger API-Key. Bitte in Einstellungen prüfen.\n'
            'Kostenloser Key: aistudio.google.com/app/apikey');
      } else if (response.statusCode == 429) {
        return GeminiResponse.error(
            'Zu viele Anfragen. Kurz warten und erneut versuchen.\n'
            '(Kostenlos: 15 Anfragen/Minute)');
      } else {
        final error = jsonDecode(response.body);
        return GeminiResponse.error(
            'Fehler ${response.statusCode}: ${error['error']?['message'] ?? 'Unbekannter Fehler'}');
      }
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return GeminiResponse.error('Zeitüberschreitung. Internetverbindung prüfen.');
      }
      return GeminiResponse.error('Verbindungsfehler: $e');
    }
  }
}

// ── Datenklassen ──────────────────────────────────────────────────

class GeminiResponse {
  final String? text;
  final String? error;
  final bool isSuccess;

  GeminiResponse.success(this.text)
      : error = null,
        isSuccess = true;

  GeminiResponse.error(this.error)
      : text = null,
        isSuccess = false;
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
