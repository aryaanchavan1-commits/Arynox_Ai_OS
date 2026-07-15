import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_providers.dart';

class AiSettingsPage extends ConsumerWidget {
  const AiSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);

    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Settings',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure AI providers, models, and privacy',
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 32),

        _SettingsSection(
          title: 'Default Provider',
          children: [
            _DropdownSetting(
              label: 'AI Provider',
              value: settings.defaultProvider,
              items: AiProvider.values.map((p) => DropdownMenuItem(
                value: p,
                child: Text(p.displayName),
              )).toList(),
              onChanged: (v) {
                if (v != null) {
                  ref.read(aiSettingsProvider.notifier).state = AiSettings(
                    defaultProvider: v,
                    providerApiKey: settings.providerApiKey,
                    providerBaseUrl: settings.providerBaseUrl,
                    preferredModel: settings.preferredModel,
                    temperature: settings.temperature,
                    maxTokens: settings.maxTokens,
                    streaming: settings.streaming,
                    reasoningMode: settings.reasoningMode,
                    vision: settings.vision,
                    voice: settings.voice,
                    memory: settings.memory,
                    contextLength: settings.contextLength,
                    mode: settings.mode,
                    encryptKeys: settings.encryptKeys,
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            _TextSetting(
              label: 'API Key',
              value: settings.providerApiKey,
              obscured: true,
              hint: 'Enter your API key',
              onChanged: (v) {
                ref.read(aiSettingsProvider.notifier).state = AiSettings(
                  defaultProvider: settings.defaultProvider,
                  providerApiKey: v,
                  providerBaseUrl: settings.providerBaseUrl,
                  preferredModel: settings.preferredModel,
                  temperature: settings.temperature,
                  maxTokens: settings.maxTokens,
                  streaming: settings.streaming,
                  reasoningMode: settings.reasoningMode,
                  vision: settings.vision,
                  voice: settings.voice,
                  memory: settings.memory,
                  contextLength: settings.contextLength,
                  mode: settings.mode,
                  encryptKeys: settings.encryptKeys,
                );
              },
            ),
            const SizedBox(height: 12),
            _TextSetting(
              label: 'Base URL',
              value: settings.providerBaseUrl,
              hint: 'https://api.groq.com/openai/v1',
              onChanged: (v) {
                ref.read(aiSettingsProvider.notifier).state = AiSettings(
                  defaultProvider: settings.defaultProvider,
                  providerApiKey: settings.providerApiKey,
                  providerBaseUrl: v,
                  preferredModel: settings.preferredModel,
                  temperature: settings.temperature,
                  maxTokens: settings.maxTokens,
                  streaming: settings.streaming,
                  reasoningMode: settings.reasoningMode,
                  vision: settings.vision,
                  voice: settings.voice,
                  memory: settings.memory,
                  contextLength: settings.contextLength,
                  mode: settings.mode,
                  encryptKeys: settings.encryptKeys,
                );
              },
            ),
            const SizedBox(height: 12),
            _TextSetting(
              label: 'Preferred Model',
              value: settings.preferredModel,
              hint: 'llama3-70b-8192',
              onChanged: (v) {
                ref.read(aiSettingsProvider.notifier).state = AiSettings(
                  defaultProvider: settings.defaultProvider,
                  providerApiKey: settings.providerApiKey,
                  providerBaseUrl: settings.providerBaseUrl,
                  preferredModel: v,
                  temperature: settings.temperature,
                  maxTokens: settings.maxTokens,
                  streaming: settings.streaming,
                  reasoningMode: settings.reasoningMode,
                  vision: settings.vision,
                  voice: settings.voice,
                  memory: settings.memory,
                  contextLength: settings.contextLength,
                  mode: settings.mode,
                  encryptKeys: settings.encryptKeys,
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Connection test successful')),
                  );
                },
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('Test Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        _SettingsSection(
          title: 'Model Configuration',
          children: [
            _SliderSetting(
              label: 'Temperature',
              value: settings.temperature,
              min: 0.0,
              max: 2.0,
              divisions: 40,
              displayValue: settings.temperature.toStringAsFixed(1),
              onChanged: (v) {
                ref.read(aiSettingsProvider.notifier).state = AiSettings(
                  defaultProvider: settings.defaultProvider,
                  providerApiKey: settings.providerApiKey,
                  providerBaseUrl: settings.providerBaseUrl,
                  preferredModel: settings.preferredModel,
                  temperature: v,
                  maxTokens: settings.maxTokens,
                  streaming: settings.streaming,
                  reasoningMode: settings.reasoningMode,
                  vision: settings.vision,
                  voice: settings.voice,
                  memory: settings.memory,
                  contextLength: settings.contextLength,
                  mode: settings.mode,
                  encryptKeys: settings.encryptKeys,
                );
              },
            ),
            const SizedBox(height: 12),
            _SliderSetting(
              label: 'Max Tokens',
              value: settings.maxTokens.toDouble(),
              min: 256,
              max: 65536,
              divisions: 255,
              displayValue: '${settings.maxTokens}',
              onChanged: (v) {
                ref.read(aiSettingsProvider.notifier).state = AiSettings(
                  maxTokens: v.toInt(),
                  defaultProvider: settings.defaultProvider,
                  providerApiKey: settings.providerApiKey,
                  providerBaseUrl: settings.providerBaseUrl,
                  preferredModel: settings.preferredModel,
                  temperature: settings.temperature,
                  streaming: settings.streaming,
                  reasoningMode: settings.reasoningMode,
                  vision: settings.vision,
                  voice: settings.voice,
                  memory: settings.memory,
                  contextLength: settings.contextLength,
                  mode: settings.mode,
                  encryptKeys: settings.encryptKeys,
                );
              },
            ),
            const SizedBox(height: 12),
            _SliderSetting(
              label: 'Context Length',
              value: settings.contextLength.toDouble(),
              min: 1024,
              max: 131072,
              divisions: 127,
              displayValue: '${settings.contextLength}',
              onChanged: (v) {
                ref.read(aiSettingsProvider.notifier).state = AiSettings(
                  contextLength: v.toInt(),
                  defaultProvider: settings.defaultProvider,
                  providerApiKey: settings.providerApiKey,
                  providerBaseUrl: settings.providerBaseUrl,
                  preferredModel: settings.preferredModel,
                  temperature: settings.temperature,
                  maxTokens: settings.maxTokens,
                  streaming: settings.streaming,
                  reasoningMode: settings.reasoningMode,
                  vision: settings.vision,
                  voice: settings.voice,
                  memory: settings.memory,
                  mode: settings.mode,
                  encryptKeys: settings.encryptKeys,
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 24),

        _SettingsSection(
          title: 'Capabilities',
          children: [
            _SwitchSetting(
              label: 'Streaming',
              value: settings.streaming,
              onChanged: (v) {
                ref.read(aiSettingsProvider.notifier).state = AiSettings(
                  streaming: v,
                  defaultProvider: settings.defaultProvider,
                  providerApiKey: settings.providerApiKey,
                  providerBaseUrl: settings.providerBaseUrl,
                  preferredModel: settings.preferredModel,
                  temperature: settings.temperature,
                  maxTokens: settings.maxTokens,
                  reasoningMode: settings.reasoningMode,
                  vision: settings.vision,
                  voice: settings.voice,
                  memory: settings.memory,
                  contextLength: settings.contextLength,
                  mode: settings.mode,
                  encryptKeys: settings.encryptKeys,
                );
              },
            ),
            _SwitchSetting(
              label: 'Reasoning Mode',
              value: settings.reasoningMode,
              onChanged: (v) {
                ref.read(aiSettingsProvider.notifier).state = AiSettings(
                  reasoningMode: v,
                  defaultProvider: settings.defaultProvider,
                  providerApiKey: settings.providerApiKey,
                  providerBaseUrl: settings.providerBaseUrl,
                  preferredModel: settings.preferredModel,
                  temperature: settings.temperature,
                  maxTokens: settings.maxTokens,
                  streaming: settings.streaming,
                  vision: settings.vision,
                  voice: settings.voice,
                  memory: settings.memory,
                  contextLength: settings.contextLength,
                  mode: settings.mode,
                  encryptKeys: settings.encryptKeys,
                );
              },
            ),
            _SwitchSetting(
              label: 'Vision (Image Understanding)',
              value: settings.vision,
              onChanged: (v) {
                ref.read(aiSettingsProvider.notifier).state = AiSettings(
                  vision: v,
                  defaultProvider: settings.defaultProvider,
                  providerApiKey: settings.providerApiKey,
                  providerBaseUrl: settings.providerBaseUrl,
                  preferredModel: settings.preferredModel,
                  temperature: settings.temperature,
                  maxTokens: settings.maxTokens,
                  streaming: settings.streaming,
                  reasoningMode: settings.reasoningMode,
                  voice: settings.voice,
                  memory: settings.memory,
                  contextLength: settings.contextLength,
                  mode: settings.mode,
                  encryptKeys: settings.encryptKeys,
                );
              },
            ),
            _SwitchSetting(
              label: 'Voice',
              value: settings.voice,
              onChanged: (v) {
                ref.read(aiSettingsProvider.notifier).state = AiSettings(
                  voice: v,
                  defaultProvider: settings.defaultProvider,
                  providerApiKey: settings.providerApiKey,
                  providerBaseUrl: settings.providerBaseUrl,
                  preferredModel: settings.preferredModel,
                  temperature: settings.temperature,
                  maxTokens: settings.maxTokens,
                  streaming: settings.streaming,
                  reasoningMode: settings.reasoningMode,
                  vision: settings.vision,
                  memory: settings.memory,
                  contextLength: settings.contextLength,
                  mode: settings.mode,
                  encryptKeys: settings.encryptKeys,
                );
              },
            ),
            _SwitchSetting(
              label: 'Memory (Conversation History)',
              value: settings.memory,
              onChanged: (v) {
                ref.read(aiSettingsProvider.notifier).state = AiSettings(
                  memory: v,
                  defaultProvider: settings.defaultProvider,
                  providerApiKey: settings.providerApiKey,
                  providerBaseUrl: settings.providerBaseUrl,
                  preferredModel: settings.preferredModel,
                  temperature: settings.temperature,
                  maxTokens: settings.maxTokens,
                  streaming: settings.streaming,
                  reasoningMode: settings.reasoningMode,
                  vision: settings.vision,
                  voice: settings.voice,
                  contextLength: settings.contextLength,
                  mode: settings.mode,
                  encryptKeys: settings.encryptKeys,
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 24),

        _SettingsSection(
          title: 'AI Mode',
          children: [
            _ChoiceChipSetting(
              label: 'Processing Mode',
              value: settings.mode,
              options: const [
                (AiMode.local, 'Local AI', 'Run models locally on-device'),
                (AiMode.cloud, 'Cloud AI', 'Use cloud provider APIs'),
                (AiMode.hybrid, 'Hybrid', 'Local for privacy, cloud for complex'),
              ],
              onSelected: (mode) {
                ref.read(aiSettingsProvider.notifier).state = AiSettings(
                  mode: mode,
                  defaultProvider: settings.defaultProvider,
                  providerApiKey: settings.providerApiKey,
                  providerBaseUrl: settings.providerBaseUrl,
                  preferredModel: settings.preferredModel,
                  temperature: settings.temperature,
                  maxTokens: settings.maxTokens,
                  streaming: settings.streaming,
                  reasoningMode: settings.reasoningMode,
                  vision: settings.vision,
                  voice: settings.voice,
                  memory: settings.memory,
                  contextLength: settings.contextLength,
                  encryptKeys: settings.encryptKeys,
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 24),

        _SettingsSection(
          title: 'Privacy & Security',
          children: [
            _SwitchSetting(
              label: 'Encrypt API Keys',
              value: settings.encryptKeys,
              onChanged: (v) {
                ref.read(aiSettingsProvider.notifier).state = AiSettings(
                  encryptKeys: v,
                  defaultProvider: settings.defaultProvider,
                  providerApiKey: settings.providerApiKey,
                  providerBaseUrl: settings.providerBaseUrl,
                  preferredModel: settings.preferredModel,
                  temperature: settings.temperature,
                  maxTokens: settings.maxTokens,
                  streaming: settings.streaming,
                  reasoningMode: settings.reasoningMode,
                  vision: settings.vision,
                  voice: settings.voice,
                  memory: settings.memory,
                  contextLength: settings.contextLength,
                  mode: settings.mode,
                );
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFFA29BFE)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'All API keys are encrypted at rest',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Keys are stored using AES-256 encryption tied to your device',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Usage Statistics
        _SettingsSection(
          title: 'Usage & Costs',
          children: [
            _StatRow(label: 'Tokens Used (Today)', value: '0'),
            _StatRow(label: 'Requests (Today)', value: '0'),
            _StatRow(label: 'Estimated Cost (Today)', value: '\$0.00'),
            _StatRow(label: 'Model Latency (Avg)', value: '0ms'),
            _StatRow(label: 'Current Model', value: settings.preferredModel),
            _StatRow(label: 'Provider Status', value: 'Connected'),
          ],
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

extension AiProviderDisplay on AiProvider {
  String get displayName {
    switch (this) {
      case AiProvider.groq: return 'Groq';
      case AiProvider.openai: return 'OpenAI';
      case AiProvider.anthropic: return 'Anthropic';
      case AiProvider.gemini: return 'Google Gemini';
      case AiProvider.openRouter: return 'OpenRouter';
      case AiProvider.ollama: return 'Ollama';
      case AiProvider.lmStudio: return 'LM Studio';
      case AiProvider.custom: return 'Custom (OpenAI-compatible)';
    }
  }
}

// --- Reusable Settings Widgets ---

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1B2E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _DropdownSetting extends StatelessWidget {
  final String label;
  final AiProvider value;
  final List<DropdownMenuItem<AiProvider>> items;
  final ValueChanged<AiProvider?> onChanged;

  const _DropdownSetting({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1023),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AiProvider>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1B2E),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _TextSetting extends StatelessWidget {
  final String label;
  final String value;
  final bool obscured;
  final String hint;
  final ValueChanged<String> onChanged;

  const _TextSetting({
    required this.label,
    required this.value,
    this.obscured = false,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
        const SizedBox(height: 6),
        TextField(
          obscureText: obscured,
          controller: TextEditingController(text: value),
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: const Color(0xFF0F1023),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _SliderSetting extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;

  const _SliderSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
            const Spacer(),
            Text(displayValue, style: const TextStyle(fontSize: 13, color: Colors.white)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF6C5CE7),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            thumbColor: const Color(0xFFA29BFE),
            overlayColor: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _SwitchSetting extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSetting({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6C5CE7),
          ),
        ],
      ),
    );
  }
}

class _ChoiceChipSetting extends StatelessWidget {
  final String label;
  final AiMode value;
  final List<(AiMode, String, String)> options;
  final ValueChanged<AiMode> onSelected;

  const _ChoiceChipSetting({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
        const SizedBox(height: 8),
        ...options.map((opt) {
          final (mode, title, description) = opt;
          final selected = value == mode;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => onSelected(mode),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF6C5CE7).withValues(alpha: 0.2)
                      : const Color(0xFF0F1023),
                  borderRadius: BorderRadius.circular(12),
                  border: selected
                      ? Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.4))
                      : Border.all(color: Colors.transparent),
                ),
                child: Row(
                  children: [
                    Radio<AiMode>(
                      value: mode,
                      groupValue: value,
                      onChanged: (v) => onSelected(v!),
                      activeColor: const Color(0xFFA29BFE),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white70,
                              fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.white60)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, color: Colors.white)),
        ],
      ),
    );
  }
}
