import 'package:flutter/material.dart';

void main() {
  runApp(const ArynoxSettingsApp());
}

class ArynoxSettingsApp extends StatelessWidget {
  const ArynoxSettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arynox Settings',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF0F1023),
        useMaterial3: true,
      ),
      home: const SettingsPage(),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 0;

  static const _sections = [
    _SettingsSection('Appearance', Icons.palette, [
      _Setting('Theme', 'Dark', Icons.dark_mode),
      _Setting('Accent Color', 'Indigo', Icons.color_lens),
      _Setting('Font Size', 'Medium', Icons.text_fields),
    ]),
    _SettingsSection('System', Icons.settings, [
      _Setting('Language', 'English', Icons.language),
      _Setting('Date & Time', 'UTC', Icons.schedule),
      _Setting('Region', 'US', Icons.public),
    ]),
    _SettingsSection('Display', Icons.monitor, [
      _Setting('Resolution', '1920x1080', Icons.display_settings),
      _Setting('Refresh Rate', '60 Hz', Icons.speed),
      _Setting('Brightness', '75%', Icons.brightness_medium),
    ]),
    _SettingsSection('Network', Icons.wifi, [
      _Setting('WiFi', 'Connected', Icons.wifi),
      _Setting('Bluetooth', 'Off', Icons.bluetooth),
      _Setting('VPN', 'Disconnected', Icons.vpn_lock),
    ]),
    _SettingsSection('Security', Icons.security, [
      _Setting('Screen Lock', 'Enabled', Icons.lock),
      _Setting('Firewall', 'Active', Icons.shield),
      _Setting('Privacy', 'Standard', Icons.privacy_tip),
    ]),
    _SettingsSection('AI', Icons.smart_toy, [
      _Setting('AI Assistant', 'Enabled', Icons.chat),
      _Setting('Providers', 'OpenAI', Icons.cloud),
      _Setting('Voice', 'Disabled', Icons.mic),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sections.length,
        itemBuilder: (ctx, i) {
          final section = _sections[i];
          return Card(
            color: const Color(0xFF1A1B2E),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(section.icon, color: Colors.indigo, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        section.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF2A2B42)),
                  ...section.items.map((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(item.icon, color: Colors.white54, size: 20),
                    title: Text(item.name, style: const TextStyle(color: Colors.white)),
                    trailing: Text(item.value, style: const TextStyle(color: Colors.white54)),
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SettingsSection {
  final String title;
  final IconData icon;
  final List<_Setting> items;
  const _SettingsSection(this.title, this.icon, this.items);
}

class _Setting {
  final String name;
  final String value;
  final IconData icon;
  const _Setting(this.name, this.value, this.icon);
}
