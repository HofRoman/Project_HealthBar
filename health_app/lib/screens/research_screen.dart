import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'settings_screen.dart';

class ResearchScreen extends StatefulWidget {
  const ResearchScreen({super.key});

  @override
  State<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends State<ResearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String? _result;
  String? _error;
  String? _currentTopic;
  bool _hasApiKey = false;
  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;

  // Beliebte Medizin-Themen
  static const _hotTopics = [
    ('Herzinfarkt Prävention 2024', Icons.favorite),
    ('Diabetes Typ 2 Umkehr', Icons.bloodtype),
    ('Alzheimer Forschung aktuell', Icons.psychology),
    ('Krebs Immuntherapie Studien', Icons.biotech),
    ('Schlaf & Demenz Zusammenhang', Icons.bedtime),
    ('Mikronährstoffe Immunsystem', Icons.spa),
    ('Bewegung & Gehirngesundheit', Icons.directions_run),
    ('Darmflora Mikrobiom 2025', Icons.science),
  ];

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(_scanCtrl);
    _checkApiKey();
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkApiKey() async {
    final has = await GeminiService.hasApiKey();
    setState(() => _hasApiKey = has);
  }

  Future<void> _search(String topic) async {
    if (topic.trim().isEmpty) return;
    if (!_hasApiKey) {
      _showNoKeyDialog();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _result = null;
      _error = null;
      _currentTopic = topic.trim();
    });

    final response = await GeminiService.deepMedicalResearch(topic.trim());

    setState(() {
      _isSearching = false;
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
      builder: (ctx) => _NoKeyDialog(
        onSetup: () {
          Navigator.pop(ctx);
          Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()))
              .then((_) => _checkApiKey());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppTheme.bg,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Hintergrund-Gradient
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0A1628),
                          Color(0xFF1A0A28),
                        ],
                      ),
                    ),
                  ),
                  // Scan-Linie Animation
                  AnimatedBuilder(
                    animation: _scanAnim,
                    builder: (_, __) => Positioned(
                      top: 160 * _scanAnim.value,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppTheme.colorResearch.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.colorResearch.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.colorResearch.withOpacity(0.4),
                                  ),
                                ),
                                child: const Icon(Icons.science,
                                    color: AppTheme.colorResearch, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Medizin Deep Research',
                                      style: AppTheme.headline2.copyWith(
                                          color: AppTheme.colorResearch)),
                                  Text(
                                    'KI sucht nach aktuellen Studien & Leitlinien',
                                    style: AppTheme.caption,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Suchleiste
                          GlassCard(
                            padding: EdgeInsets.zero,
                            glowColor: _isSearching ? AppTheme.colorResearch : null,
                            glowIntensity: 0.2,
                            borderRadius: AppTheme.radiusSmall,
                            child: TextField(
                              controller: _searchController,
                              style: AppTheme.bodyBold,
                              onSubmitted: _search,
                              decoration: InputDecoration(
                                hintText: 'Medizin-Thema eingeben...',
                                hintStyle: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 14),
                                prefixIcon: const Icon(Icons.search,
                                    color: AppTheme.colorResearch, size: 20),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.send_rounded,
                                      color: AppTheme.colorResearch),
                                  onPressed: () =>
                                      _search(_searchController.text),
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // API-Key Hinweis
                if (!_hasApiKey)
                  _NoKeyBanner(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ).then((_) => _checkApiKey()),
                  ),
                if (!_hasApiKey) const SizedBox(height: 16),

                // Heiße Themen
                if (_result == null && !_isSearching) ...[
                  Text('🔥 Aktuelle Medizin-Themen',
                      style: AppTheme.headline3.copyWith(
                          color: AppTheme.colorResearch)),
                  const SizedBox(height: 12),
                  ...List.generate(
                    (_hotTopics.length / 2).ceil(),
                    (rowIndex) {
                      final i1 = rowIndex * 2;
                      final i2 = i1 + 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: _TopicCard(
                                topic: _hotTopics[i1].$1,
                                icon: _hotTopics[i1].$2,
                                onTap: () {
                                  _searchController.text = _hotTopics[i1].$1;
                                  _search(_hotTopics[i1].$1);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (i2 < _hotTopics.length)
                              Expanded(
                                child: _TopicCard(
                                  topic: _hotTopics[i2].$1,
                                  icon: _hotTopics[i2].$2,
                                  onTap: () {
                                    _searchController.text = _hotTopics[i2].$1;
                                    _search(_hotTopics[i2].$1);
                                  },
                                ),
                              )
                            else
                              const Expanded(child: SizedBox()),
                          ],
                        ),
                      );
                    },
                  ),
                ],

                // Ladeindikator
                if (_isSearching) ...[
                  const SizedBox(height: 20),
                  _SearchingCard(topic: _currentTopic ?? ''),
                ],

                // Fehler
                if (_error != null && !_isSearching) ...[
                  const SizedBox(height: 16),
                  _ErrorCard(message: _error!),
                ],

                // Ergebnis
                if (_result != null && !_isSearching) ...[
                  const SizedBox(height: 16),
                  _ResultSection(
                    topic: _currentTopic ?? '',
                    result: _result!,
                    onNewSearch: () {
                      setState(() {
                        _result = null;
                        _currentTopic = null;
                        _searchController.clear();
                      });
                    },
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────

class _TopicCard extends StatelessWidget {
  final String topic;
  final IconData icon;
  final VoidCallback onTap;

  const _TopicCard(
      {required this.topic, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      glowColor: AppTheme.colorResearch,
      glowIntensity: 0.1,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.colorResearch, size: 20),
          const SizedBox(height: 8),
          Text(
            topic,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.arrow_forward,
                  size: 12, color: AppTheme.colorResearch),
              const SizedBox(width: 4),
              Text('Recherchieren',
                  style: AppTheme.caption.copyWith(
                      color: AppTheme.colorResearch)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchingCard extends StatefulWidget {
  final String topic;
  const _SearchingCard({required this.topic});

  @override
  State<_SearchingCard> createState() => _SearchingCardState();
}

class _SearchingCardState extends State<_SearchingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _step = 0;
  final _steps = [
    'Google Scholar durchsuchen...',
    'PubMed-Datenbank abfragen...',
    'WHO-Leitlinien analysieren...',
    'Studien-Metadaten extrahieren...',
    'Wissenschaftliche Ergebnisse kompilieren...',
    'Antwort wird generiert...',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1).animate(_ctrl);

    // Zyklisch durch Steps gehen
    Future.delayed(Duration.zero, _cycleSteps);
  }

  void _cycleSteps() async {
    for (int i = 0; i < _steps.length; i++) {
      if (!mounted) return;
      setState(() => _step = i);
      await Future.delayed(const Duration(milliseconds: 1800));
    }
    if (mounted) _cycleSteps();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: AppTheme.colorResearch,
      glowIntensity: 0.3,
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.colorResearch.withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.colorResearch
                            .withOpacity(_anim.value * 0.5),
                        blurRadius: 16 * _anim.value,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.science,
                      color: AppTheme.colorResearch, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recherchiere: ${widget.topic}',
                        style: AppTheme.bodyBold,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        _steps[_step],
                        key: ValueKey(_step),
                        style: AppTheme.caption.copyWith(
                            color: AppTheme.colorResearch),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              backgroundColor:
                  AppTheme.colorResearch.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.colorResearch),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  final String topic;
  final String result;
  final VoidCallback onNewSearch;

  const _ResultSection({
    required this.topic,
    required this.result,
    required this.onNewSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            NeonBadge(
              label: 'DEEP RESEARCH',
              color: AppTheme.colorResearch,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                topic,
                style: AppTheme.bodyBold,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close,
                  color: AppTheme.textSecondary, size: 20),
              onPressed: onNewSearch,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Ergebnis-Karte
        GlassCard(
          glowColor: AppTheme.colorResearch,
          glowIntensity: 0.15,
          padding: const EdgeInsets.all(20),
          child: MarkdownBody(
            data: result,
            styleSheet: MarkdownStyleSheet(
              h1: AppTheme.headline2.copyWith(color: AppTheme.colorResearch),
              h2: AppTheme.headline3.copyWith(color: AppTheme.colorResearch),
              h3: AppTheme.bodyBold.copyWith(color: AppTheme.neonBlue),
              p: AppTheme.body.copyWith(
                  color: AppTheme.textPrimary, height: 1.6),
              strong: AppTheme.bodyBold,
              listBullet: AppTheme.body.copyWith(color: AppTheme.textPrimary),
              code: const TextStyle(
                fontFamily: 'monospace',
                backgroundColor: Color(0x22FFFFFF),
                color: AppTheme.neon,
                fontSize: 13,
              ),
              blockquote: AppTheme.body.copyWith(
                  color: AppTheme.textSecondary),
              tableBody: AppTheme.body.copyWith(
                  color: AppTheme.textPrimary),
              tableHead: AppTheme.bodyBold,
              horizontalRuleDecoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.glassBorder),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Disclaimer
        GlassCard(
          hasBorder: false,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  color: AppTheme.colorResearch.withOpacity(0.7), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Diese KI-Recherche basiert auf öffentlich verfügbaren wissenschaftlichen Quellen. '
                  'Sie ersetzt keine professionelle medizinische Beratung.',
                  style: AppTheme.caption.copyWith(
                      color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onNewSearch,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Neue Recherche'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.colorResearch,
              side: BorderSide(
                  color: AppTheme.colorResearch.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoKeyBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _NoKeyBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        glowColor: AppTheme.colorResearch,
        glowIntensity: 0.2,
        child: Row(
          children: [
            const Icon(Icons.key, color: AppTheme.colorResearch, size: 22),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('API-Key einrichten',
                      style: AppTheme.bodyBold),
                  Text('Komplett kostenlos – tippe hier',
                      style: AppTheme.caption),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: AppTheme.colorResearch, size: 14),
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
    return GlassCard(
      glowColor: AppTheme.colorSymptom,
      glowIntensity: 0.15,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.colorSymptom, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: AppTheme.body.copyWith(color: AppTheme.colorSymptom)),
          ),
        ],
      ),
    );
  }
}

class _NoKeyDialog extends StatelessWidget {
  final VoidCallback onSetup;
  const _NoKeyDialog({required this.onSetup});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      title: const Text('API-Key benötigt', style: AppTheme.headline3),
      content: Text(
        'Für Deep Research wird ein kostenloser Gemini API-Key benötigt.\n\n'
        'Holen unter: aistudio.google.com/app/apikey',
        style: AppTheme.body,
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen',
                style: TextStyle(color: AppTheme.textSecondary))),
        ElevatedButton(
          onPressed: onSetup,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.colorResearch,
              foregroundColor: AppTheme.bg),
          child: const Text('Einrichten'),
        ),
      ],
    );
  }
}
