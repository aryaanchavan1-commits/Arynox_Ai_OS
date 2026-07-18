import 'package:flutter/material.dart';

void main() {
  runApp(const ArynoxNetworkManagerApp());
}

class ArynoxNetworkManagerApp extends StatelessWidget {
  const ArynoxNetworkManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arynox Network Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF0F1023),
      ),
      home: const NetworkManagerPage(),
    );
  }
}

class NetworkManagerPage extends StatefulWidget {
  const NetworkManagerPage({super.key});

  @override
  State<NetworkManagerPage> createState() => _NetworkManagerPageState();
}

class _NetworkManagerPageState extends State<NetworkManagerPage> {
  int _selectedIndex = 0;

  static const List<String> _titles = ['WiFi', 'VPN', 'Firewall', 'Proxy'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            backgroundColor: const Color(0xFF0D0D1F),
            indicatorColor: Colors.indigo.withOpacity(0.2),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.wifi, color: Colors.white54),
                selectedIcon: Icon(Icons.wifi, color: Colors.indigo),
                label: Text('WiFi', style: TextStyle(color: Colors.white70)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.vpn_lock, color: Colors.white54),
                selectedIcon: Icon(Icons.vpn_lock, color: Colors.indigo),
                label: Text('VPN', style: TextStyle(color: Colors.white70)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shield, color: Colors.white54),
                selectedIcon: Icon(Icons.shield, color: Colors.indigo),
                label: Text('Firewall', style: TextStyle(color: Colors.white70)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings, color: Colors.white54),
                selectedIcon: Icon(Icons.settings, color: Colors.indigo),
                label: Text('Proxy', style: TextStyle(color: Colors.white70)),
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
        return _buildWifiPage();
      case 1:
        return _buildVpnPage();
      case 2:
        return _buildFirewallPage();
      case 3:
        return _buildProxyPage();
      default:
        return const SizedBox();
    }
  }

  Widget _buildWifiPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildNetworkTile('Home Network', '5 GHz', true),
        _buildNetworkTile('Guest Network', '2.4 GHz', false),
        _buildNetworkTile('Neighbor WiFi', '5 GHz', true),
      ],
    );
  }

  Widget _buildNetworkTile(String ssid, String band, bool secured) {
    return Card(
      color: const Color(0xFF1A1B2E),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.wifi, color: Colors.indigo),
        title: Text(ssid, style: const TextStyle(color: Colors.white)),
        subtitle: Text('$band · ${secured ? "Secured" : "Open"}',
            style: const TextStyle(color: Colors.white54)),
        trailing: const Icon(Icons.lock_outline, color: Colors.white38),
      ),
    );
  }

  Widget _buildVpnPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.vpn_lock, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('No VPN connections',
              style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add VPN'),
          ),
        ],
      ),
    );
  }

  Widget _buildFirewallPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            color: const Color(0xFF1A1B2E),
            child: SwitchListTile(
              title: const Text('Firewall', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Protection active',
                  style: TextStyle(color: Colors.green)),
              value: true,
              activeColor: Colors.indigo,
              onChanged: (_) {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProxyPage() {
    return const Center(
      child: Text('Proxy settings', style: TextStyle(color: Colors.white54)),
    );
  }
}
