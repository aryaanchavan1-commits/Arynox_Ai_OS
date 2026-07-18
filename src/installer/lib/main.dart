import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ArynoxInstallerApp());
}

class ArynoxInstallerApp extends StatelessWidget {
  const ArynoxInstallerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InstallerState(),
      child: MaterialApp(
        title: 'Arynox OS Installer',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const InstallerWizard(),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.indigo,
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      useMaterial3: true,
    );
  }
}

class InstallerState extends ChangeNotifier {
  int _currentStep = 0;
  String _selectedDisk = '';
  String _username = '';
  String _password = '';
  String _hostname = 'arynox';
  double _installProgress = 0.0;
  bool _isInstalling = false;
  bool _installComplete = false;

  int get currentStep => _currentStep;
  String get selectedDisk => _selectedDisk;
  String get username => _username;
  String get hostname => _hostname;
  double get installProgress => _installProgress;
  bool get isInstalling => _isInstalling;
  bool get installComplete => _installComplete;

  bool get canProceed {
    switch (_currentStep) {
      case 0:
        return _selectedDisk.isNotEmpty;
      case 1:
        return _username.isNotEmpty && _hostname.isNotEmpty;
      default:
        return false;
    }
  }

  void nextStep() {
    if (_currentStep < 4 && canProceed) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void setDisk(String disk) {
    _selectedDisk = disk;
    notifyListeners();
  }

  void setUsername(String val) {
    _username = val;
    notifyListeners();
  }

  void setHostname(String val) {
    _hostname = val;
    notifyListeners();
  }

  Future<void> startInstallation() async {
    _isInstalling = true;
    _installProgress = 0.0;
    _installComplete = false;
    notifyListeners();

    const stages = [
      'Partitioning disk...',
      'Creating filesystems...',
      'Installing base system...',
      'Configuring system...',
      'Finalizing...',
    ];

    for (int i = 0; i < stages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      _installProgress = (i + 1) / stages.length;
      notifyListeners();
    }

    _installProgress = 1.0;
    _installComplete = true;
    _isInstalling = false;
    notifyListeners();
  }

  void reset() {
    _currentStep = 0;
    _installProgress = 0.0;
    _isInstalling = false;
    _installComplete = false;
    notifyListeners();
  }
}

class InstallerWizard extends StatelessWidget {
  const InstallerWizard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1117), Color(0xFF161B22)],
          ),
        ),
        child: SafeArea(
          child: Consumer<InstallerState>(
            builder: (context, state, _) {
              return Column(
                children: [
                  _buildHeader(context, state),
                  Expanded(child: _buildStepContent(context, state)),
                  _buildNavigation(context, state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, InstallerState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF21262D))),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, color: Color(0xFF6C63FF), size: 32),
          const SizedBox(width: 12),
          const Text(
            'Arynox OS Installer',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const Spacer(),
          Text(
            'Step ${state.currentStep + 1} of 5',
            style: const TextStyle(color: Color(0xFF8B949E)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation(BuildContext context, InstallerState state) {
    if (state.isInstalling || state.installComplete) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF21262D))),
      ),
      child: Row(
        children: [
          if (state.currentStep > 0)
            OutlinedButton(
              onPressed: () => state.previousStep(),
              child: const Text('Back'),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: state.canProceed ? () => state.nextStep() : null,
            child: Text(state.currentStep == 4 ? 'Install' : 'Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, InstallerState state) {
    switch (state.currentStep) {
      case 0:
        return _WelcomePage();
      case 1:
        return _UserCreationPage();
      case 2:
        return _SystemConfigPage();
      case 3:
        return _InstallSummaryPage();
      case 4:
        return _InstallProgressPage();
      default:
        return _WelcomePage();
    }
  }
}

class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<InstallerState>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.circle, size: 80, color: Color(0xFF6C63FF)),
          const SizedBox(height: 24),
          const Text(
            'Welcome to Arynox OS',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: Colors.white),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => state.nextStep(),
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}

class _UserCreationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<InstallerState>();
    return Center(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Create Account',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: Colors.white),
            ),
            const SizedBox(height: 32),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: Color(0xFF8B949E)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF30363D))),
              ),
              onChanged: (v) => state.setUsername(v),
            ),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Hostname',
                labelStyle: TextStyle(color: Color(0xFF8B949E)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF30363D))),
              ),
              controller: TextEditingController(text: state.hostname),
              onChanged: (v) => state.setHostname(v),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemConfigPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('System Configuration', style: TextStyle(color: Colors.white54)),
    );
  }
}

class _InstallSummaryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<InstallerState>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Ready to Install',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text('User: ${state.username}', style: const TextStyle(color: Colors.white54)),
          Text('Hostname: ${state.hostname}', style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              state.nextStep();
              state.startInstallation();
            },
            child: const Text('Install Arynox OS'),
          ),
        ],
      ),
    );
  }
}

class _InstallProgressPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<InstallerState>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!state.installComplete) ...[
            const Text(
              'Installing...',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: Colors.white),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 400,
              child: LinearProgressIndicator(
                value: state.installProgress,
                backgroundColor: const Color(0xFF21262D),
                color: const Color(0xFF6C63FF),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${(state.installProgress * 100).toInt()}%',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w200, color: Color(0xFF6C63FF)),
            ),
          ] else ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            const Text(
              'Installation Complete!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: Colors.white),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => state.reset(),
              child: const Text('Restart'),
            ),
          ],
        ],
      ),
    );
  }
}
