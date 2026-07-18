import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const AssistantApp());

class AssistantApp extends StatelessWidget {
  const AssistantApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Arynox AI',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
    home: const ChatScreen(),
  );
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <Map<String, String>>[];
  final _controller = TextEditingController();
  bool _loading = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() { _messages.add({'role': 'user', 'content': text}); _loading = true; });
    try {
      final res = await http.post(Uri.parse('http://127.0.0.1:8080/chat'),
        headers: {'Content-Type': 'application/json'},
        body: '{"message": "${text.replaceAll('"', '\\"')}"}');
      setState(() { _messages.add({'role': 'assistant', 'content': res.body}); });
    } catch (e) {
      setState(() { _messages.add({'role': 'assistant', 'content': 'Error: $e'}); });
    }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Arynox AI Assistant')),
    body: Column(children: [
      Expanded(child: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (_, i) => ListTile(
          leading: Icon(_messages[i]['role'] == 'user' ? Icons.person : Icons.smart_toy),
          title: Text(_messages[i]['content'] ?? ''),
        ),
      )),
      if (_loading) const LinearProgressIndicator(),
      Padding(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Ask anything...'))),
          IconButton(icon: const Icon(Icons.send), onPressed: _send),
        ]),
      ),
    ]),
  );
}
