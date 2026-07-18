import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ArynoxDesktopApp());
}

class ArynoxDesktopApp extends StatelessWidget {
  const ArynoxDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arynox Desktop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF0A0A1A),
        useMaterial3: true,
      ),
      home: const DesktopShell(),
    );
  }
}

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A1B2E),
                    Color(0xFF0A0A1A),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.circle,
                        color: Colors.indigo,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Arynox OS',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Desktop Environment',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 60,
            color: const Color(0xFF14152B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _dockItem(Icons.terminal, 'Terminal'),
                const SizedBox(width: 8),
                _dockItem(Icons.folder, 'Files'),
                const SizedBox(width: 8),
                _dockItem(Icons.public, 'Browser'),
                const SizedBox(width: 8),
                _dockItem(Icons.settings, 'Settings'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dockItem(IconData icon, String label) {
    return Tooltip(
      message: label,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white70, size: 24),
      ),
    );
  }
}
