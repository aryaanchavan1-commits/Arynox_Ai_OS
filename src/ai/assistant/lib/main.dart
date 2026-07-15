import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ProviderScope(child: AIAssistantApp()));
}

class AIAssistantApp extends StatelessWidget {
  const AIAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arynox AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C5CE7),
        brightness: Brightness.dark,
      ),
      home: const AIAssistant(),
    );
  }
}

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

final messagesProvider = StateProvider<List<ChatMessage>>((ref) => []);
final isListeningProvider = StateProvider<bool>((ref) => false);

class AIAssistant extends ConsumerStatefulWidget {
  const AIAssistant({super.key});

  @override
  ConsumerState<AIAssistant> createState() => _AIAssistantState();
}

class _AIAssistantState extends ConsumerState<AIAssistant> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    ref.read(messagesProvider.notifier).state = [
      ...ref.read(messagesProvider),
      ChatMessage(role: 'user', content: content.trim()),
    ];

    _inputController.clear();
    setState(() => _isLoading = true);

    try {
      final messages = ref.read(messagesProvider)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8741/v1/chat'),
        body: jsonEncode({
          'provider': 'groq',
          'model': 'llama3-70b-8192',
          'messages': messages,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ref.read(messagesProvider.notifier).state = [
          ...ref.read(messagesProvider),
          ChatMessage(role: 'assistant', content: data['content'] ?? ''),
        ];
      }
    } catch (e) {
      ref.read(messagesProvider.notifier).state = [
        ...ref.read(messagesProvider),
        ChatMessage(role: 'assistant', content: 'Error: $e'),
      ];
    } finally {
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider);

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Arynox AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                    Text('Groq · llama3-70b', style: TextStyle(fontSize: 12, color: Colors.white38)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.mic, color: Colors.white54),
                  onPressed: () {},
                  tooltip: 'Voice input',
                ),
                Container(
                  width: 1, height: 24,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                        const SizedBox(height: 16),
                        Text('How can I help you?',
                          style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.3))),
                        const SizedBox(height: 8),
                        Text('Ask me to write, research, code, or analyze',
                          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.2))),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && _isLoading) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(children: [
                            SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA29BFE)),
                            ),
                            SizedBox(width: 12),
                            Text('Thinking...', style: TextStyle(color: Colors.white38)),
                          ]),
                        );
                      }
                      final msg = messages[index];
                      return _MessageBubble(message: msg);
                    },
                  ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1B2E),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ask anything...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: () => _sendMessage(_inputController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF6C5CE7).withValues(alpha: 0.3)
                    : const Color(0xFF1A1B2E),
                borderRadius: BorderRadius.circular(14).copyWith(
                  bottomLeft: isUser ? null : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: Text(
                message.content,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person, color: Colors.white54, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}
