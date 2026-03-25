import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class FirstAidScreen extends StatefulWidget {
  const FirstAidScreen({super.key});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  bool _loading = false;
  String _result = '';
  String? _activeScenario;
  final _customCtrl = TextEditingController();

  static const _scenarios = [
    _Scenario('🫀', 'Herzstillstand', 'CPR & Defibrillator',
        AppTheme.colorEmergency,
        'Erkläre Schritt für Schritt was bei einem Herzstillstand zu tun ist: CPR-Technik (30:2), AED-Nutzung, Rettungskette. Praktische, sofort umsetzbare Anweisungen.'),
    _Scenario('🩸', 'Starke Blutung', 'Wundversorgung',
        AppTheme.colorFood,
        'Erkläre wie man starke Blutungen stoppt: Druckverband, Staumanschette, Schocklagerung. Schritt-für-Schritt mit klaren Anweisungen.'),
    _Scenario('😮‍💨', 'Atemwegsverlegung', 'Heimlich-Manöver',
        AppTheme.colorActivity,
        'Erkläre das Heimlich-Manöver bei Erstickungsgefahr: Rückenschläge, Heimlich bei Erwachsenen, bei Kindern und Säuglingen. Schritt-für-Schritt.'),
    _Scenario('🧠', 'Schlaganfall', 'FAST-Test & Soforthilfe',
        AppTheme.colorVitals,
        'Erkläre Schlaganfall-Erkennung (FAST-Test: Face, Arms, Speech, Time) und sofortige Maßnahmen bis zum Eintreffen des Notarztes.'),
    _Scenario('🔥', 'Verbrennung', 'Kühlung & Versorgung',
        AppTheme.colorResearch,
        'Erkläre die Erstversorgung von Verbrennungen: Kühlung (wie lange, wie), Grade 1-3, was man nicht tun sollte, wann Notarzt.'),
    _Scenario('⚡', 'Stromunfall', 'Sicherheit & Erste Hilfe',
        AppTheme.neonGreen,
        'Erkläre Erste Hilfe bei Stromunfällen: eigene Sicherheit, Stromunterbrechung, Bewusstseinskontrolle, stabile Seitenlage, HLW.'),
    _Scenario('😵', 'Ohnmacht', 'Bewusstlosigkeit',
        AppTheme.colorSleep,
        'Erkläre was bei Ohnmacht zu tun ist: stabile Seitenlage, Atemwegskontrolle, Pulscheck, wann Notruf, Anzeichen gefährlicher Ohnmacht.'),
    _Scenario('🐝', 'Allergischer Schock', 'Anaphylaxie',
        AppTheme.colorMeds,
        'Erkläre den anaphylaktischen Schock: Erkennung, Epi-Pen-Einsatz, Schocklagerung, Atemwegsicherung, Notruf. Sofortmaßnahmen.'),
    _Scenario('🦴', 'Knochenbruch', 'Ruhigstellung',
        AppTheme.neonBlue,
        'Erkläre Erste Hilfe bei Knochenbrüchen: Erkennung offener/geschlossener Bruch, Ruhigstellung, Schiene, was vermeiden, wann Notruf.'),
    _Scenario('🌡️', 'Hitzschlag', 'Überhitzung & Heatstroke',
        AppTheme.colorActivity,
        'Erkläre Hitzschlag vs. Hitzeerschöpfung: Erkennung, Kühlung, Flüssigkeit, Bewusstlosigkeit, Notruf. Unterschied Hitzekrampf.'),
    _Scenario('❄️', 'Unterkühlung', 'Hypothermie-Soforthilfe',
        AppTheme.neonBlue,
        'Erkläre Hypothermie-Grade, Erste Hilfe: aufwärmen wie, nasse Kleidung, keine Reibung, warme Getränke wann möglich, Notruf.'),
    _Scenario('💊', 'Vergiftung', 'Giftnotruf & Soforthilfe',
        AppTheme.colorMeds,
        'Erkläre was bei Vergiftungen zu tun ist: kein Erbrechen auslösen (außer Ausnahmen), Giftnotruf, wichtige Informationen für Notruf, Bewusstseinskontrolle.'),
  ];

  Future<void> _askAbout(String topic, String prompt) async {
    final hasKey = await GeminiService.hasApiKey();
    if (!hasKey) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bitte erst API-Schlüssel in Einstellungen eingeben'),
          backgroundColor: AppTheme.colorEmergency,
        ));
      }
      return;
    }

    setState(() { _loading = true; _activeScenario = topic; _result = ''; });

    final fullPrompt = '''
Du bist Notarzt und Erste-Hilfe-Experte. Antworte auf Deutsch, klar und strukturiert.
WICHTIG: Halte die Antwort präzise und praktisch umsetzbar. Nutze Schritt-Nummerierung.

$prompt

Füge am Ende immer hinzu: "**Notruf: 112 (EU) | 110 (Polizei) | Giftnotruf: 030 19240**"
    ''';

    final result = await GeminiService().chat(fullPrompt, useSearch: true);

    if (mounted) {
      setState(() {
        _loading = false;
        _result = result['text'] ?? 'Fehler bei der Anfrage';
      });
    }
  }

  Future<void> _askCustom() async {
    final q = _customCtrl.text.trim();
    if (q.isEmpty) return;
    await _askAbout(q, 'Erste-Hilfe-Frage: $q\nBitte präzise und praktisch antworten.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.colorEmergency.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.emergency,
                color: AppTheme.colorEmergency, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Erste Hilfe'),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Notruf-Banner
          GlassCard(
            glowColor: AppTheme.colorEmergency,
            glowIntensity: 0.3,
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.colorEmergency.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_in_talk,
                    color: AppTheme.colorEmergency, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NOTRUF', style: TextStyle(
                    color: AppTheme.colorEmergency,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 2,
                  )),
                  Text('112', style: TextStyle(
                    color: AppTheme.colorEmergency,
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
                  )),
                  Text('Europäischer Notruf · Polizei: 110',
                      style: AppTheme.caption),
                ],
              )),
              Column(children: [
                _EmNum('110', 'Polizei'),
                const SizedBox(height: 4),
                _EmNum('030\n19240', 'Giftnotruf'),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Eigene Frage
          GlassCard(
            glowColor: AppTheme.neon,
            glowIntensity: 0.1,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.smart_toy, color: AppTheme.neon, size: 18),
                const SizedBox(width: 8),
                const Text('KI-Notfallfrage', style: AppTheme.bodyBold),
                const Spacer(),
                PulseDot(color: AppTheme.neon),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(
                  controller: _customCtrl,
                  style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'z.B. Was tun bei Nasenbluten?',
                    prefixIcon: Icon(Icons.help_outline,
                        color: AppTheme.neon, size: 18),
                  ),
                  onSubmitted: (_) => _askCustom(),
                )),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _askCustom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neon,
                    foregroundColor: AppTheme.bg,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall)),
                  ),
                  child: const Icon(Icons.send, size: 18),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Ergebnis
          if (_loading)
            GlassCard(
              glowColor: AppTheme.colorEmergency,
              glowIntensity: 0.15,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  const CircularProgressIndicator(
                      color: AppTheme.colorEmergency),
                  const SizedBox(height: 12),
                  Text('KI-Notfallhilfe für "$_activeScenario"...',
                      style: AppTheme.caption),
                ]),
              ),
            )
          else if (_result.isNotEmpty)
            GlassCard(
              glowColor: AppTheme.colorEmergency,
              glowIntensity: 0.1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.medical_services,
                        color: AppTheme.colorEmergency, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      _activeScenario ?? 'Erste Hilfe',
                      style: AppTheme.bodyBold
                          .copyWith(color: AppTheme.colorEmergency),
                    )),
                    GestureDetector(
                      onTap: () => setState(() => _result = ''),
                      child: const Icon(Icons.close,
                          size: 18, color: AppTheme.textMuted),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  const NeonDivider(),
                  const SizedBox(height: 12),
                  MarkdownBody(
                    data: _result,
                    styleSheet: MarkdownStyleSheet(
                      h1: const TextStyle(
                          color: AppTheme.colorEmergency,
                          fontSize: 18,
                          fontWeight: FontWeight.w800),
                      h2: const TextStyle(
                          color: AppTheme.colorEmergency,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                      h3: const TextStyle(
                          color: AppTheme.neon,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      p: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          height: 1.6),
                      strong: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700),
                      listBullet: const TextStyle(
                          color: AppTheme.colorEmergency),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          const Text('Notfallszenarien', style: AppTheme.headline3),
          const SizedBox(height: 10),

          // Szenario Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
            ),
            itemCount: _scenarios.length,
            itemBuilder: (_, i) {
              final s = _scenarios[i];
              final isActive = _activeScenario == s.title;
              return GlassCard(
                glowColor: s.color,
                glowIntensity: isActive ? 0.3 : 0.1,
                onTap: () => _askAbout(s.title, s.prompt),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(s.emoji,
                          style: const TextStyle(fontSize: 22)),
                      const Spacer(),
                      if (isActive && _loading)
                        SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: s.color,
                          ),
                        ),
                    ]),
                    const Spacer(),
                    Text(s.title,
                        style: TextStyle(
                            color: s.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    Text(s.subtitle, style: AppTheme.caption),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),
          // Hinweis
          GlassCard(
            glowColor: const Color(0xFFFFB300),
            glowIntensity: 0.08,
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: Color(0xFFFFB300), size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Diese App ersetzt keinen Erste-Hilfe-Kurs. Alle 2 Jahre auffrischen! '
                  'Im Zweifelsfall sofort 112 anrufen.',
                  style: AppTheme.caption,
                )),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _Scenario {
  final String emoji, title, subtitle;
  final Color color;
  final String prompt;
  const _Scenario(this.emoji, this.title, this.subtitle, this.color, this.prompt);
}

class _EmNum extends StatelessWidget {
  final String number, label;
  const _EmNum(this.number, this.label);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(number,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 13)),
    Text(label, style: AppTheme.caption),
  ]);
}
