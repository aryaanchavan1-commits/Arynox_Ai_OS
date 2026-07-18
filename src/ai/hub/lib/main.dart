import 'package:flutter/material.dart';

void main() {
  runApp(const IntelligenceHubApp());
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

class ProviderModel {
  final String name;
  final String model;
  final bool connected;
  final IconData icon;
  const ProviderModel(this.name, this.model, this.connected, this.icon);
}

class IntelligenceHub extends StatefulWidget {
  const IntelligenceHub({super.key});

  @override
  State<IntelligenceHub> createState() => _IntelligenceHubState();
}

class _IntelligenceHubState extends State<IntelligenceHub> {
  int _selectedIndex = 0;

  static const providers = [
    ProviderModel('OpenAI', 'GPT-4o', true, Icons.auto_awesome),
    ProviderModel('Anthropic', 'Claude 3.5', true, Icons.psychology),
    ProviderModel('Google', 'Gemini Pro', false, Icons.cloud),
    ProviderModel('Meta', 'Llama 3', true, Icons.model_training),
    ProviderModel('Mistral', 'Mistral Large', false, Icons.smart_toy),
    ProviderModel('Local', 'Ollama', true, Icons.computer),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intelligence Hub'),
        centerTitle: false,
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            backgroundColor: const Color(0xFF0D0D1F),
            indicatorColor: const Color(0xFF6C5CE7).withOpacity(0.2),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard, color: Colors.white54),
                selectedIcon: Icon(Icons.dashboard, color: Color(0xFF6C5CE7)),
                label: Text('Dashboard', style: TextStyle(color: Colors.white70)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.cloud, color: Colors.white54),
                selectedIcon: Icon(Icons.cloud, color: Color(0xFF6C5CE7)),
                label: Text('Providers', style: TextStyle(color: Colors.white70)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics, color: Colors.white54),
                selectedIcon: Icon(Icons.analytics, color: Color(0xFF6C5CE7)),
                label: Text('Analytics', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _buildPage()),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildProviders();
      case 2:
        return _buildAnalytics();
      default:
        return const SizedBox();
    }
  }

  Widget _buildDashboard() {
    final connected = providers.where((p) => p.connected).length;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF6C5CE7), size: 32),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Intelligence Hub',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('$connected/${providers.length} providers connected',
                      style: const TextStyle(color: Colors.white54)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: providers.length,
              itemBuilder: (ctx, i) {
                final p = providers[i];
                return Card(
                  color: const Color(0xFF1A1B2E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(p.icon, color: const Color(0xFF6C5CE7), size: 32),
                        const SizedBox(height: 8),
                        Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        Text(p.model, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: p.connected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p.connected ? 'Connected' : 'Offline',
                            style: TextStyle(color: p.connected ? Colors.green : Colors.red, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviders() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: providers.length,
      itemBuilder: (ctx, i) {
        final p = providers[i];
        return Card(
          color: const Color(0xFF1A1B2E),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.2),
              child: Icon(p.icon, color: const Color(0xFF6C5CE7)),
            ),
            title: Text(p.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(p.model, style: const TextStyle(color: Colors.white54)),
            trailing: Switch(
              value: p.connected,
              activeColor: const Color(0xFF6C5CE7),
              onChanged: (_) {},
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalytics() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text('Analytics Dashboard', style: TextStyle(color: Colors.white54, fontSize: 16)),
          SizedBox(height: 8),
          Text('Usage statistics and performance metrics',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }
}
