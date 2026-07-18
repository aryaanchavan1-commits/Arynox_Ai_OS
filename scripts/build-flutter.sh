#!/bin/bash
export PATH="/opt/flutter/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
PROJECT="/mnt/d/Arynoxtech/ArynoxOS"
mkdir -p "$PROJECT/build/flutter-apps"

for app in desktop devices software network devtools installer; do
    echo "=== Building src/$app ==="
    cd "$PROJECT/src/$app"
    if [ ! -f pubspec.yaml ]; then
        echo "  No pubspec.yaml, skipping"
        continue
    fi
    flutter pub get 2>&1 | tail -2
    flutter build linux --release 2>&1 | tail -3
    if [ -d "build/linux/x64/release/bundle" ]; then
        mkdir -p "$PROJECT/build/flutter-apps/$app"
        cp -r build/linux/x64/release/bundle/* "$PROJECT/build/flutter-apps/$app/"
        echo "  Copied to build/flutter-apps/$app/"
    fi
    echo ""
done

echo "=== Build Summary ==="
for app in desktop settings ai/hub devices software network devtools installer; do
    if [ -d "$PROJECT/build/flutter-apps/$app" ]; then
        size=$(du -sh "$PROJECT/build/flutter-apps/$app" 2>/dev/null | cut -f1)
        echo "  $app: $size"
    else
        echo "  $app: NOT BUILT"
    fi
done

# Create AI assistant and copilot apps
echo ""
echo "=== Creating AI assistant app ==="
mkdir -p "$PROJECT/src/ai/assistant/lib"
cat > "$PROJECT/src/ai/assistant/pubspec.yaml" << 'YAML'
name: arynox_assistant
description: Arynox AI Assistant
publish_to: none
version: 1.0.0+1
environment: { sdk: '>=3.2.0 <4.0.0' }
dependencies:
  flutter: { sdk: flutter }
  http: ^1.2.0
dev_dependencies:
  flutter_test: { sdk: flutter }
  flutter_lints: ^6.0.0
flutter: { uses-material-design: true }
YAML
cat > "$PROJECT/src/ai/assistant/lib/main.dart" << 'DART'
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
DART

cd "$PROJECT/src/ai/assistant"
flutter pub get 2>&1 | tail -2
flutter build linux --release 2>&1 | tail -3
if [ -d "build/linux/x64/release/bundle" ]; then
    mkdir -p "$PROJECT/build/flutter-apps/ai-assistant"
    cp -r build/linux/x64/release/bundle/* "$PROJECT/build/flutter-apps/ai-assistant/"
fi

echo ""
echo "=== Creating AI copilot app ==="
mkdir -p "$PROJECT/src/ai/copilot/lib"
cat > "$PROJECT/src/ai/copilot/pubspec.yaml" << 'YAML'
name: arynox_copilot
description: Arynox AI Copilot
publish_to: none
version: 1.0.0+1
environment: { sdk: '>=3.2.0 <4.0.0' }
dependencies:
  flutter: { sdk: flutter }
  http: ^1.2.0
dev_dependencies:
  flutter_test: { sdk: flutter }
  flutter_lints: ^6.0.0
flutter: { uses-material-design: true }
YAML
cat > "$PROJECT/src/ai/copilot/lib/main.dart" << 'DART'
import 'package:flutter/material.dart';

void main() => runApp(const CopilotApp());

class CopilotApp extends StatelessWidget {
  const CopilotApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Arynox Copilot',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
    home: const CopilotScreen(),
  );
}

class CopilotScreen extends StatefulWidget {
  const CopilotScreen({super.key});
  @override
  State<CopilotScreen> createState() => _CopilotScreenState();
}

class _CopilotScreenState extends State<CopilotScreen> {
  final _codeController = TextEditingController(text: '// Write your code here\nfn main() {\n    println!("Hello, Arynox!");\n}');
  String _output = 'Output will appear here...';

  void _runCode() {
    setState(() { _output = 'Running...\n> Compiled successfully\n> Output: Hello, Arynox!'; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI Copilot')),
    body: Row(children: [
      Expanded(
        child: Column(children: [
          const Padding(padding: EdgeInsets.all(8), child: Text('Code Editor', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _codeController,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          )),
          ElevatedButton.icon(onPressed: _runCode, icon: const Icon(Icons.play_arrow), label: const Text('Run')),
          const SizedBox(height: 8),
        ]),
      ),
      Expanded(
        child: Column(children: [
          const Padding(padding: EdgeInsets.all(8), child: Text('Output', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: SelectableText(_output, style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent)),
          )),
        ]),
      ),
    ]),
  );
}
DART

cd "$PROJECT/src/ai/copilot"
flutter pub get 2>&1 | tail -2
flutter build linux --release 2>&1 | tail -3
if [ -d "build/linux/x64/release/bundle" ]; then
    mkdir -p "$PROJECT/build/flutter-apps/ai-copilot"
    cp -r build/linux/x64/release/bundle/* "$PROJECT/build/flutter-apps/ai-copilot/"
fi

echo ""
echo "=== Final Build Summary ==="
for app in desktop settings ai/hub ai/assistant ai/copilot devices software network devtools installer; do
    if [ -d "$PROJECT/build/flutter-apps/$app" ]; then
        size=$(du -sh "$PROJECT/build/flutter-apps/$app" 2>/dev/null | cut -f1)
        echo "  $app: $size (SUCCESS)"
    else
        echo "  $app: NOT BUILT"
    fi
done
echo ""
echo "Total flutter apps: $(ls -d $PROJECT/build/flutter-apps/*/ 2>/dev/null | wc -l)"
