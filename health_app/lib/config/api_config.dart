/// HealthBar — API Konfiguration
///
/// Trage hier deinen kostenlosen Gemini API-Key ein.
/// Kostenlos erhalten: https://aistudio.google.com/app/apikey
///
/// Der Key wird als Standard verwendet. Du kannst ihn auch
/// in den Einstellungen der App überschreiben.
class ApiConfig {
  /// Gemini 2.0 Flash API Key
  /// Ersetze 'YOUR_GEMINI_API_KEY' mit deinem echten Key.
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';

  /// Gibt true zurück wenn ein gültiger Key konfiguriert ist
  static bool get isConfigured =>
      geminiApiKey.isNotEmpty && geminiApiKey != 'YOUR_GEMINI_API_KEY';
}
