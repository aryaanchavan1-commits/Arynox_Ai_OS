import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: IntelligenceHubApp(),
    ),
  );
}

class IntelligenceHubApp extends StatelessWidget {
  const IntelligenceHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Intelligence Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C5CE7),
        brightness: Brightness.dark,
      ),
      home: const IntelligenceHub(),
    );
  }
}

// Data models

class ProviderStatus {
  final String name;
  final String model;
  final int tokensUsed;
  final double cost;
  final int latencyMs;
  final bool online;
  final bool isDefault;

  const ProviderStatus({
    required this.name,
    required this.model,
    this.tokensUsed = 0,
    this.cost = 0,
    this.latencyMs = 0,
    this.online = true,
    this.isDefault = false,
  });
}

class AppAiProvider {
  final String appName;
  final String provider;
  final String model;

  const AppAiProvider({
    required this.appName,
    required this.provider,
    required this.model,
  });
}

// Mock data
final providers = [
  const ProviderStatus(name: 'Groq', model: 'llama3-70b-8192', tokensUsed: 15234, cost: 0.0, latencyMs: 120, online: true, isDefault: true),
  const ProviderStatus(name: 'OpenAI', model: 'gpt-4o', tokensUsed: 8900, cost: 0.45, latencyMs: 340, online: true),
  const ProviderStatus(name: 'Anthropic', model: 'claude-3-5-sonnet', tokensUsed: 4500, cost: 0.30, latencyMs: 420, online: true),
  const ProviderStatus(name: 'Google Gemini', model: 'gemini-1.5-pro', tokensUsed: 3200, cost: 0.15, latencyMs: 280, online: true),
  const ProviderStatus(name: 'Ollama', model: 'llama3.2-local', tokensUsed: 12000, cost: 0.0, latencyMs: 890, online: true),
];

final appProviders = [
  const AppAiProvider(appName: 'Chat', provider: 'Groq', model: 'llama3-70b-8192'),
  const AppAiProvider(appName: 'Files', provider: 'Ollama', model: 'llama3.2-local'),
  const AppAiProvider(appName: 'Browser', provider: 'Gemini', model: 'gemini-1.5-pro'),
  const AppAiProvider(appName: 'Terminal', provider: 'OpenAI', model: 'gpt-4o'),
  const AppAiProvider(appName: 'Documents', provider: 'Anthropic', model: 'claude-3-5-sonnet'),
];

class IntelligenceHub extends StatelessWidget {
  const IntelligenceHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
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
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Intelligence Hub', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      Text('Manage AI providers and permissions', style: TextStyle(fontSize: 12, color: Colors.white60)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Health Overview
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1B2E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('System AI Health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _HealthIndicator(label: 'Runtime', status: 'Running', color: Colors.green),
                          const SizedBox(width: 16),
                          _HealthIndicator(label: 'Providers', status: '5/5 Online', color: Colors.green),
                          const SizedBox(width: 16),
                          _HealthIndicator(label: 'Local Model', status: 'Loaded', color: Colors.green),
                          const SizedBox(width: 16),
                          _HealthIndicator(label: 'Memory', status: 'Active', color: Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Provider cards
                const Text('AI Providers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 12),
                ...providers.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ProviderCard(provider: p),
                )),

                const SizedBox(height: 24),

                // Per-app provider mapping
                const Text('Provider per Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 12),
                ...appProviders.map((ap) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AppProviderCard(appProvider: ap),
                )),

                const SizedBox(height: 24),

                // Usage summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1B2E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Usage Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(height: 16),
                      _UsageRow(label: 'Total Tokens Today', value: '43,834'),
                      _UsageRow(label: 'Total Cost Today', value: '\$0.90'),
                      _UsageRow(label: 'Total Requests', value: '127'),
                      _UsageRow(label: 'Average Latency', value: '410ms'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.bar_chart),
                          label: const Text('View Detailed Analytics'),
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
                ),

                const SizedBox(height: 24),

                // Privacy controls
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1B2E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: Color(0xFFA29BFE), size: 20),
                          SizedBox(width: 8),
                          Text('Privacy Controls', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _PrivacyToggle(label: 'Allow cloud AI processing', value: true),
                      _PrivacyToggle(label: 'Allow AI to access files', value: true),
                      _PrivacyToggle(label: 'Allow AI to access clipboard', value: false),
                      _PrivacyToggle(label: 'Allow AI to access screen', value: false),
                      _PrivacyToggle(label: 'Send anonymous usage data', value: false),
                      const SizedBox(height: 16),
                      const Text(
                        'Your data is processed according to your privacy settings. Local AI processing never leaves your device.',
                        style: TextStyle(fontSize: 12, color: Colors.white38),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthIndicator extends StatelessWidget {
  final String label; final String status; final Color color;
  const _HealthIndicator({required this.label, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white38)),
        ]),
        const SizedBox(height: 4),
        Text(status, style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
      ],
    ));
  }
}

class _ProviderCard extends StatelessWidget {
  final ProviderStatus provider;
  const _ProviderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B2E),
        borderRadius: BorderRadius.circular(14),
        border: provider.isDefault ? Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.4)) : null,
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: provider.online ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.cloud, color: provider.online ? Colors.green : Colors.redAccent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(provider.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              if (provider.isDefault) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF6C5CE7).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4)),
                  child: const Text('Default', style: TextStyle(fontSize: 10, color: Color(0xFFA29BFE))),
                ),
              ],
            ]),
            Text(provider.model, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${provider.tokensUsed}', style: const TextStyle(fontSize: 13, color: Colors.white60)),
          Text('tokens', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.3))),
        ]),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('\$${provider.cost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Colors.white60)),
          Text('cost', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.3))),
        ]),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${provider.latencyMs}ms', style: const TextStyle(fontSize: 13, color: Colors.white60)),
          Text('latency', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.3))),
        ]),
        const SizedBox(width: 8),
        Container(width: 8, height: 8, decoration: BoxDecoration(
          color: provider.online ? Colors.green : Colors.redAccent, shape: BoxShape.circle)),
      ]),
    );
  }
}

class _AppProviderCard extends StatelessWidget {
  final AppAiProvider appProvider;
  const _AppProviderCard({required this.appProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF1A1B2E), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: const Color(0xFF0F1023), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.apps, color: Colors.white54, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(appProvider.appName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
        Text(appProvider.provider, style: const TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: const Color(0xFF0F1023), borderRadius: BorderRadius.circular(6)),
          child: Text(appProvider.model, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
        ),
      ]),
    );
  }
}

class _UsageRow extends StatelessWidget {
  final String label; final String value;
  const _UsageRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Colors.white60)),
      const Spacer(),
      Text(value, style: const TextStyle(fontSize: 13, color: Colors.white)),
    ]),
  );
}

class _PrivacyToggle extends StatelessWidget {
  final String label; final bool value;
  const _PrivacyToggle({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70))),
      Switch(value: value, onChanged: (_) {}, activeColor: const Color(0xFF6C5CE7)),
    ]),
  );
}
