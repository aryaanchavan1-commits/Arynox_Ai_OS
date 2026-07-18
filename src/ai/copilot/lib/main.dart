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
