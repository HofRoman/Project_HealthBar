import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../services/gemini_service.dart';
import 'settings_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _hasApiKey = false;

  // Schnell-Fragen für den Einstieg
  static const _quickQuestions = [
    'Was bedeutet ein BMI von 27?',
    'Wie viel Wasser sollte ich täglich trinken?',
    'Was sind Zeichen von Eisenmangel?',
    'Welche Lebensmittel stärken das Immunsystem?',
    'Was tun bei anhaltenden Kopfschmerzen?',
    'Wie erkenne ich Bluthochdruck?',
  ];

  @override
  void initState() {
    super.initState();
    _checkApiKey();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkApiKey() async {
    final has = await GeminiService.hasApiKey();
    setState(() => _hasApiKey = has);
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text: '''Hallo! Ich bin dein persönlicher **KI-Arztassistent** powered by Google Gemini.

Ich kann dir helfen bei:
- 🔍 **Symptom-Analyse** – Erkläre deine Symptome
- 💊 **Medikamenten-Info** – Wirkung, Nebenwirkungen, Wechselwirkungen
- 🏥 **Gesundheitsfragen** – Von Ernährung bis Krankheiten
- 📚 **Deep Research** – Tiefe medizinische Recherche zu jedem Thema
- 🧬 **Laborwerte** – Erkläre deine Blutwerte

Stelle mir einfach deine Frage!''',
      isUser: false,
    ));
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (!_hasApiKey) {
      _showNoKeyDialog();
      return;
    }

    _controller.clear();

    final userMsg = ChatMessage(text: text.trim(), isUser: true);
    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _scrollToBottom();

    // Nur die letzten 10 Nachrichten als Verlauf mitgeben (spart Tokens)
    final history = _messages.length > 1
        ? _messages
            .skip(1) // Begrüßungsnachricht überspringen
            .take(_messages.length - 2)
            .toList()
        : <ChatMessage>[];

    final response = await GeminiService.chat(
      text.trim(),
      history: history,
    );

    setState(() {
      _isLoading = false;
      _messages.add(ChatMessage(
        text: response.isSuccess
            ? response.text!
            : '❌ Fehler: ${response.error}',
        isUser: false,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showNoKeyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API-Key benötigt'),
        content: const Text(
          'Für den KI-Arztassistenten wird ein kostenloser '
          'Google Gemini API-Key benötigt.\n\n'
          'Komplett kostenlos, keine Kreditkarte nötig:\naistudio.google.com/app/apikey',
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
                backgroundColor: const Color(0xFF5C6BC0)),
            child: const Text('Jetzt einrichten',
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('KI-Arztassistent',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Powered by Google Gemini (kostenlos)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: const Color(0xFF5C6BC0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Chat löschen',
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ).then((_) => _checkApiKey()),
          ),
        ],
      ),
      body: Column(
        children: [
          // API-Key Warnung
          if (!_hasApiKey)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) => _checkApiKey()),
              child: Container(
                width: double.infinity,
                color: Colors.orange.shade100,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: const Row(
                  children: [
                    Icon(Icons.key, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kein API-Key gesetzt. Tippe hier um ihn einzurichten (kostenlos).',
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.orange),
                  ],
                ),
              ),
            ),

          // Nachrichten
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (ctx, index) {
                if (index == _messages.length) {
                  return const _TypingIndicator();
                }
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),

          // Schnell-Fragen (nur wenn Chat leer/Willkommen)
          if (_messages.length <= 1)
            _QuickQuestions(
              questions: _quickQuestions,
              onTap: _sendMessage,
            ),

          // Eingabe
          _ChatInput(
            controller: _controller,
            isLoading: _isLoading,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ── Widgets ─────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

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
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF5C6BC0),
              child: const Text('KI',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: message.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kopiert!')),
                );
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser
                      ? const Color(0xFF5C6BC0)
                      : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isUser
                    ? Text(
                        message.text,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15),
                      )
                    : MarkdownBody(
                        data: message.text,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1A1A2E),
                              height: 1.5),
                          h2: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5C6BC0)),
                          h3: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                          listBullet: const TextStyle(fontSize: 14),
                          strong: const TextStyle(
                              fontWeight: FontWeight.bold),
                          code: const TextStyle(
                              backgroundColor: Color(0xFFF0F0F0),
                              fontFamily: 'monospace'),
                        ),
                      ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.person,
                  color: Colors.grey, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF5C6BC0),
            child: Text('KI',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0),
                const SizedBox(width: 4),
                _Dot(delay: 200),
                const SizedBox(width: 4),
                _Dot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF5C6BC0),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _QuickQuestions extends StatelessWidget {
  final List<String> questions;
  final Function(String) onTap;

  const _QuickQuestions(
      {required this.questions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) => GestureDetector(
          onTap: () => onTap(questions[i]),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF5C6BC0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF5C6BC0).withOpacity(0.3)),
            ),
            child: Text(
              questions[i],
              style: const TextStyle(
                  color: Color(0xFF5C6BC0),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final Function(String) onSend;

  const _ChatInput({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Stelle eine medizinische Frage...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: isLoading
                  ? Colors.grey[300]
                  : const Color(0xFF5C6BC0),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: isLoading
                  ? null
                  : () => onSend(controller.text),
            ),
          ),
        ],
      ),
    );
  }
}
