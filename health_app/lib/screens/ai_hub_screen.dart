import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/gemini_service.dart';
import 'ai_chat_screen.dart';
import 'face_scan_screen.dart';
import 'symptom_checker_screen.dart';
import 'health_score_screen.dart';
import 'health_report_screen.dart';
import 'first_aid_screen.dart';
import 'settings_screen.dart';

class AiHubScreen extends StatefulWidget {
  const AiHubScreen({super.key});

  @override
  State<AiHubScreen> createState() => _AiHubScreenState();
}

class _AiHubScreenState extends State<AiHubScreen> {
  bool _hasApiKey = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final has = await GeminiService.hasApiKey();
    setState(() => _hasApiKey = has);
  }

  void _go(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => screen,
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0, 0.05), end: Offset.zero)
                .animate(a),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) => _check());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 16, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF111111), Color(0xFF000000)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GradientText(
                        'KI-Arztassistent',
                        style: AppTheme.headline1,
                        gradient: const LinearGradient(
                          colors: [AppTheme.white, AppTheme.grey90],
                        ),
                      ),
                      const Spacer(),
                      _KeyStatus(hasKey: _hasApiKey),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Powered by Google Gemini • Komplett kostenlos',
                    style: AppTheme.caption,
                  ),
                  const SizedBox(height: 20),
                  // Haupt-Chat-Button
                  GlassCard(
                    glowColor: AppTheme.colorAI,
                    glowIntensity: 0.35,
                    padding: const EdgeInsets.all(20),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.colorAI.withOpacity(0.3),
                        AppTheme.colorAI.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => _go(const AiChatScreen()),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.colorAI.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.smart_toy_rounded,
                              color: AppTheme.colorAI, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Arzt-Chat starten',
                                  style: AppTheme.headline3),
                              const SizedBox(height: 4),
                              Text(
                                'Stelle jede medizinische Frage',
                                style: AppTheme.body,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppTheme.colorAI),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── KI-Module Grid ──────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text('KI-Module', style: AppTheme.headline3),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _AiModuleCard(
                        title: 'Gesichtsscan',
                        subtitle: 'KI analysiert sichtbare Gesundheitszeichen',
                        icon: Icons.face_retouching_natural,
                        color: AppTheme.colorFace,
                        badge: 'VISION',
                        onTap: () => _go(const FaceScanScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AiModuleCard(
                        title: 'Symptom-\nChecker',
                        subtitle: 'Deep Research zu deinen Symptomen',
                        icon: Icons.medical_information,
                        color: AppTheme.colorSymptom,
                        badge: 'SEARCH',
                        onTap: () => _go(const SymptomCheckerScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _AiFeatureRow(
                  title: 'Gesundheits-Score',
                  subtitle:
                      'KI berechnet deinen persönlichen Score aus allen Trackingdaten',
                  icon: Icons.auto_graph,
                  color: AppTheme.colorScore,
                  badge: 'KI',
                  onTap: () => _go(const HealthScoreScreen()),
                ),
                const SizedBox(height: 12),
                _AiFeatureRow(
                  title: 'KI Gesundheitsbericht',
                  subtitle:
                      'Vollständige KI-Analyse aller Daten + wissenschaftliche Empfehlungen',
                  icon: Icons.summarize,
                  color: AppTheme.colorReport,
                  badge: 'NEU',
                  onTap: () => _go(const HealthReportScreen()),
                ),
                const SizedBox(height: 12),
                _AiFeatureRow(
                  title: 'Erste Hilfe & Notfall',
                  subtitle:
                      'Sofortmaßnahmen bei Notfällen mit KI-Unterstützung',
                  icon: Icons.emergency,
                  color: AppTheme.colorEmergency,
                  badge: 'SOS',
                  onTap: () => _go(const FirstAidScreen()),
                ),
                const SizedBox(height: 12),

                // Was kann die KI?
                const SizedBox(height: 8),
                const NeonDivider(color: AppTheme.colorAI),
                const SizedBox(height: 16),
                const Text('Was kann die KI?', style: AppTheme.headline3),
                const SizedBox(height: 12),
                ..._capabilities.map((c) => _CapabilityItem(
                      icon: c.$1,
                      title: c.$2,
                      desc: c.$3,
                      color: AppTheme.colorAI,
                    )),

                // Setup wenn kein Key
                if (!_hasApiKey) ...[
                  const SizedBox(height: 20),
                  _SetupBanner(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    ).then((_) => _check()),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static const _capabilities = [
    (Icons.search, 'Google Search Grounding',
        'Sucht aktiv nach den neuesten Studien aus PubMed, WHO, Cochrane'),
    (Icons.visibility, 'Bildanalyse (Vision)',
        'Analysiert Gesichtfotos auf sichtbare Gesundheitszeichen'),
    (Icons.psychology, 'Medizinisches Fachwissen',
        'Alle Fachrichtungen: Innere Medizin, Kardiologie, Neurologie u.v.m.'),
    (Icons.translate, 'Verständliche Erklärungen',
        'Komplexe Medizin in einfache Sprache übersetzt'),
    (Icons.history, 'Konversationsverlauf',
        'Erinnert sich an den Chat-Verlauf für präzisere Antworten'),
  ];
}

// ── Widgets ───────────────────────────────────────────────────────

class _KeyStatus extends StatelessWidget {
  final bool hasKey;
  const _KeyStatus({required this.hasKey});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PulseDot(
          color: hasKey ? AppTheme.neonGreen : AppTheme.textMuted,
          size: 8,
        ),
        const SizedBox(width: 6),
        Text(
          hasKey ? 'Online' : 'Offline',
          style: AppTheme.caption.copyWith(
            color: hasKey ? AppTheme.neonGreen : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _AiModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String badge;
  final VoidCallback onTap;

  const _AiModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: color,
      glowIntensity: 0.2,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              NeonBadge(label: badge, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Text(title,
              style: AppTheme.bodyBold.copyWith(height: 1.3)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTheme.caption, maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Icon(Icons.arrow_forward, color: color, size: 16),
        ],
      ),
    );
  }
}

class _AiFeatureRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String badge;
  final VoidCallback onTap;

  const _AiFeatureRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: color,
      glowIntensity: 0.15,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: AppTheme.bodyBold),
                    const SizedBox(width: 8),
                    NeonBadge(label: badge, color: color),
                  ],
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: AppTheme.caption, maxLines: 2),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: color, size: 20),
        ],
      ),
    );
  }
}

class _CapabilityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _CapabilityItem(
      {required this.icon,
      required this.title,
      required this.desc,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.bodyBold),
                Text(desc, style: AppTheme.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _SetupBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: AppTheme.colorAI,
      glowIntensity: 0.3,
      onTap: onTap,
      gradient: LinearGradient(
        colors: [
          AppTheme.colorAI.withOpacity(0.2),
          AppTheme.colorAI.withOpacity(0.05),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.key, color: AppTheme.colorAI, size: 28),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kostenlos einrichten', style: AppTheme.headline3),
                Text('aistudio.google.com/app/apikey\nKeine Kreditkarte nötig',
                    style: AppTheme.caption),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              color: AppTheme.colorAI, size: 16),
        ],
      ),
    );
  }
}
