import 'package:flutter/material.dart';

void main() {
  runApp(const ArynoxDevToolsApp());
}

class ArynoxDevToolsApp extends StatelessWidget {
  const ArynoxDevToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arynox DevTools',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0A0A1A),
      ),
      home: const DevToolsHome(),
    );
  }
}

class DevToolsHome extends StatefulWidget {
  const DevToolsHome({super.key});

  @override
  State<DevToolsHome> createState() => _DevToolsHomeState();
}

class _DevToolsHomeState extends State<DevToolsHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            backgroundColor: const Color(0xFF0D0D1F),
            indicatorColor: Colors.blue.withOpacity(0.2),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard, color: Colors.white54),
                selectedIcon: Icon(Icons.dashboard, color: Colors.blue),
                label: Text('Dashboard', style: TextStyle(color: Colors.white70)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.terminal, color: Colors.white54),
                selectedIcon: Icon(Icons.terminal, color: Colors.blue),
                label: Text('Terminal', style: TextStyle(color: Colors.white70)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bug_report, color: Colors.white54),
                selectedIcon: Icon(Icons.bug_report, color: Colors.blue),
                label: Text('Debug', style: TextStyle(color: Colors.white70)),
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
        return _buildTerminal();
      case 2:
        return _buildDebug();
      default:
        return const SizedBox();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.developer_mode, color: Colors.blue, size: 32),
              ),
              const SizedBox(width: 16),
              const Text('Developer Tools',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 32),
          _buildCard(
            'System Info',
            Icons.info,
            'CPU: Intel Core i7-13700K (16 cores)\n'
                'RAM: 32.0 GB / 32.0 GB\n'
                'GPU: NVIDIA RTX 4090 (24 GB)\n'
                'OS: Arynox OS 1.0',
          ),
          const SizedBox(height: 16),
          _buildCard(
            'Languages & Tools',
            Icons.code,
            'Python 3.12.0 · Rust 1.75.0 · Node.js 20.11.0\n'
                'Java 21.0.2 · GCC 13.2.0 · Flutter 3.44.2',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildToggleCard('Developer Mode', Icons.developer_mode, true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildToggleCard('SSH Server', Icons.terminal, false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(color: Colors.white70, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildToggleCard(String title, IconData icon, bool value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
          Switch(
            value: value,
            onChanged: (_) {},
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildTerminal() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.terminal, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text('Terminal', style: TextStyle(color: Colors.white54, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDebug() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bug_report, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text('Debug Tools', style: TextStyle(color: Colors.white54, fontSize: 16)),
        ],
      ),
    );
  }
}
