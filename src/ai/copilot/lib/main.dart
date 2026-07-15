import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ProviderScope(child: CopilotApp()));
}

class CopilotApp extends StatelessWidget {
  const CopilotApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Copilot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C5CE7),
        brightness: Brightness.dark,
      ),
      home: const AICopilot(),
    );
  }
}

// Actions the copilot can perform on selected content
enum CopilotAction {
  rewrite, explain, summarize, translate, generateCode, fixCode, generateSql, generateEmail, generateReport
}

extension CopilotActionExt on CopilotAction {
  String get label {
    switch (this) {
      case CopilotAction.rewrite: return 'Rewrite';
      case CopilotAction.explain: return 'Explain';
      case CopilotAction.summarize: return 'Summarize';
      case CopilotAction.translate: return 'Translate';
      case CopilotAction.generateCode: return 'Generate Code';
      case CopilotAction.fixCode: return 'Fix Code';
      case CopilotAction.generateSql: return 'Generate SQL';
      case CopilotAction.generateEmail: return 'Generate Email';
      case CopilotAction.generateReport: return 'Generate Report';
    }
  }
  IconData get icon {
    switch (this) {
      case CopilotAction.rewrite: return Icons.edit;
      case CopilotAction.explain: return Icons.lightbulb_outline;
      case CopilotAction.summarize: return Icons.summarize;
      case CopilotAction.translate: return Icons.translate;
      case CopilotAction.generateCode: return Icons.code;
      case CopilotAction.fixCode: return Icons.bug_report;
      case CopilotAction.generateSql: return Icons.storage;
      case CopilotAction.generateEmail: return Icons.email;
      case CopilotAction.generateReport: return Icons.assessment;
    }
  }
}

class AICopilot extends StatefulWidget {
  const AICopilot({super.key});
  @override
  State<AICopilot> createState() => _AICopilotState();
}

class _AICopilotState extends State<AICopilot> {
  CopilotAction? _selectedAction;
  String _result = '';
  bool _loading = false;
  String _contextText = '';

  // Context source
  String _contextSource = 'Selected Text';

  Future<void> _executeAction(CopilotAction action) async {
    setState(() {
      _selectedAction = action;
      _loading = true;
      _result = '';
    });

    final prompt = _buildPrompt(action, _contextText);

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8741/v1/chat'),
        body: jsonEncode({
          'provider': 'groq',
          'model': 'llama3-70b-8192',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _result = data['content'] ?? '');
      }
    } catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  String _buildPrompt(CopilotAction action, String context) {
    switch (action) {
      case CopilotAction.rewrite:
        return 'Rewrite the following text to be more clear and professional:\n\n$context';
      case CopilotAction.explain:
        return 'Explain the following in simple terms:\n\n$context';
      case CopilotAction.summarize:
        return 'Summarize the following concisely:\n\n$context';
      case CopilotAction.translate:
        return 'Translate the following to English:\n\n$context';
      case CopilotAction.generateCode:
        return 'Generate code for the following requirement:\n\n$context';
      case CopilotAction.fixCode:
        return 'Fix bugs or issues in this code:\n\n$context';
      case CopilotAction.generateSql:
        return 'Generate SQL query for:\n\n$context';
      case CopilotAction.generateEmail:
        return 'Generate a professional email about:\n\n$context';
      case CopilotAction.generateReport:
        return 'Generate a report based on:\n\n$context';
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('AI Copilot',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_contextSource,
                    style: const TextStyle(fontSize: 11, color: Colors.white38)),
                ),
              ],
            ),
          ),

          // Context preview
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1B2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.text_snippet_outlined, color: Colors.white38, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _contextText.isEmpty ? 'No context selected' : _contextText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Change', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CopilotAction.values.map((action) {
                final selected = _selectedAction == action;
                return ActionChip(
                  avatar: Icon(action.icon, size: 16,
                    color: selected ? Colors.white : Colors.white54),
                  label: Text(action.label,
                    style: TextStyle(fontSize: 12, color: selected ? Colors.white : Colors.white70)),
                  backgroundColor: selected ? const Color(0xFF6C5CE7) : const Color(0xFF1A1B2E),
                  onPressed: () => _executeAction(action),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0x1AFFFFFF)),

          // Result
          Expanded(
            child: _loading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFA29BFE)),
                        SizedBox(height: 12),
                        Text('Processing...', style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  )
                : _result.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.touch_app, size: 48, color: Colors.white.withValues(alpha: 0.1)),
                            const SizedBox(height: 12),
                            Text('Select an action to start',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.2))),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(
                          _result,
                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
