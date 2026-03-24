import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'settings_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _hasApiKey = false;

  static const _quickQ = [
    'Was bedeutet BMI 27?',
    'Anzeichen von Eisenmangel?',
    'Wie viel Wasser täglich?',
    'Wann zum Arzt bei Kopfschmerzen?',
    'Beste Lebensmittel fürs Herz?',
    'Schlafmangel Folgen?',
  ];

  @override
  void initState() {
    super.initState();
    _checkApiKey();
    _messages.add(ChatMessage(
      isUser: false,
      text:
          '**Hallo! Ich bin dein KI-Arztassistent** 🩺\n\nIch nutze **Google Search** um aktuelle wissenschaftliche Erkenntnisse zu finden.\n\n**Ich kann helfen mit:**\n- 🔍 Symptom-Analyse & Deep Research\n- 💊 Medikamenten-Informationen\n- 🏥 Alle medizinischen Fragen\n- 📊 Laborwerte erklären\n- 🔬 Aktuelle Studien recherchieren\n\nStelle mir einfach deine Frage!',
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkApiKey() async {
    final has = await GeminiService.hasApiKey();
    setState(() => _hasApiKey = has);
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    if (!_hasApiKey) { _showNoKey(); return; }

    _controller.clear();
    final userMsg = ChatMessage(text: text.trim(), isUser: true);
    setState(() { _messages.add(userMsg); _isLoading = true; });
    _scrollDown();

    final history = _messages.length > 1
        ? _messages.skip(1).take(_messages.length - 2).toList()
        : <ChatMessage>[];

    final response = await GeminiService.chat(
      text.trim(),
      history: history,
      useSearch: true, // Google Search aktiv für aktuelle Informationen
    );

    setState(() {
      _isLoading = false;
      _messages.add(ChatMessage(
        text: response.isSuccess ? response.text! : '❌ ${response.error}',
        isUser: false,
        isSearchResult: response.isSuccess && response.sources.isNotEmpty,
      ));
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showNoKey() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: const Text('API-Key benötigt', style: AppTheme.headline3),
        content: const Text(
          'Komplett kostenloser Google Gemini Key:\naistudio.google.com/app/apikey',
          style: AppTheme.body,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen',
                  style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()))
                  .then((_) => _checkApiKey());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colorAI,
                foregroundColor: Colors.white),
            child: const Text('Einrichten'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.colorAI.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: AppTheme.colorAI, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('KI-Arztassistent',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                Row(
                  children: [
                    PulseDot(
                        size: 6,
                        color: _hasApiKey
                            ? AppTheme.neonGreen
                            : AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      _hasApiKey
                          ? 'Gemini 2.0 • Google Search'
                          : 'Offline – Key einrichten',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppTheme.textSecondary, size: 20),
            onPressed: () => setState(() {
              _messages.clear();
              _messages.add(ChatMessage(
                isUser: false,
                text: '**Chat zurückgesetzt.** Stelle mir deine Frage!',
              ));
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          // Nachrichten
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length) return const _TypingBubble();
                return _Bubble(message: _messages[i]);
              },
            ),
          ),

          // Quick-Fragen
          if (_messages.length <= 1)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickQ.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) => GestureDetector(
                  onTap: () => _send(_quickQ[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.colorAI.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.colorAI.withOpacity(0.3)),
                    ),
                    child: Text(_quickQ[i],
                        style: const TextStyle(
                            color: AppTheme.colorAI,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),

          // Eingabe
          _Input(
            controller: _controller,
            isLoading: _isLoading,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.colorAI.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: AppTheme.colorAI, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: message.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Kopiert!'),
                    backgroundColor: AppTheme.bgCard,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall)),
                  ),
                );
              },
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser
                      ? AppTheme.colorAI
                      : AppTheme.bgCard,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  border: isUser
                      ? null
                      : Border.all(color: AppTheme.glassBorder),
                  boxShadow: [
                    if (!isUser)
                      BoxShadow(
                        color: AppTheme.colorAI.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                  ],
                ),
                child: isUser
                    ? Text(message.text,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14, height: 1.4))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.isSearchResult)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.search,
                                      size: 12,
                                      color: AppTheme.colorResearch),
                                  const SizedBox(width: 4),
                                  Text('Google Search aktiv',
                                      style: AppTheme.caption.copyWith(
                                          color: AppTheme.colorResearch)),
                                ],
                              ),
                            ),
                          MarkdownBody(
                            data: message.text,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                  height: 1.5),
                              h2: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.colorAI),
                              h3: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.neonBlue),
                              strong: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary),
                              listBullet: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14),
                              code: const TextStyle(
                                  fontFamily: 'monospace',
                                  color: AppTheme.neon,
                                  fontSize: 13),
                              blockquoteDecoration: BoxDecoration(
                                color: AppTheme.colorAI.withOpacity(0.08),
                                border: Border(
                                  left: BorderSide(
                                      color: AppTheme.colorAI, width: 3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: const Icon(Icons.person,
                  color: AppTheme.textSecondary, size: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.colorAI.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: AppTheme.colorAI, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) {
                    final phase = (_ctrl.value * 3 - i).clamp(0.0, 1.0);
                    final opacity = math_sin(phase * 3.14159).abs();
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      child: Opacity(
                        opacity: opacity.clamp(0.2, 1.0),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.colorAI,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double math_sin(double x) {
  // Approximation von sin für Animation
  return (x < 1.5708) ? x * (1 - x * x / 6) : (3.14159 - x) * (1 - (3.14159 - x) * (3.14159 - x) / 6);
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final Function(String) onSend;

  const _Input({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12, right: 12, top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: const Border(top: BorderSide(color: AppTheme.glassBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Medizinische Frage stellen...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLoading
                  ? AppTheme.textMuted.withOpacity(0.2)
                  : AppTheme.colorAI,
              boxShadow: isLoading
                  ? null
                  : [
                      BoxShadow(
                        color: AppTheme.colorAI.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
            ),
            child: IconButton(
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: AppTheme.textSecondary, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
              onPressed: isLoading ? null : () => onSend(controller.text),
            ),
          ),
        ],
      ),
    );
  }
}
