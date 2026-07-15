import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscape,
    DeviceOrientation.portrait,
  ]);
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
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: const InstallerWizard(),
      ),
    );
  }

  ThemeData _buildTheme() {
    const primaryColor = Color(0xFF6C63FF);
    const secondaryColor = Color(0xFF00D9FF);
    const surfaceColor = Color(0x1AFFFFFF);
    const bgColor = Color(0xFF0D1117);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: bgColor,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w300,
          letterSpacing: -1.5,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w300,
          letterSpacing: -0.5,
          color: Colors.white,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFB0B0B0)),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF888888)),
      ),
    );
  }
}

class InstallerState extends ChangeNotifier {
  int _currentStep = 0;
  String _selectedLanguage = 'en';
  String _selectedDisk = '';
  String _partitionScheme = 'automatic';
  bool _encryptionEnabled = true;
  bool _useTpm = true;
  String _username = '';
  String _realname = '';
  String _password = '';
  String _passwordConfirm = '';
  String _timezone = 'UTC';
  String _locale = 'en_US';
  String _hostname = 'arynox';
  double _installProgress = 0.0;
  String _currentStage = '';
  bool _isInstalling = false;
  bool _installComplete = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _disks = [];
  List<String> _timezones = _generateTimezones();
  List<String> _locales = ['en_US', 'de_DE', 'fr_FR', 'es_ES', 'ja_JP', 'zh_CN', 'ru_RU', 'pt_BR', 'it_IT', 'nl_NL', 'ko_KR', 'pl_PL', 'sv_SE', 'nb_NO', 'da_DK', 'fi_FI', 'cs_CZ', 'hu_HU', 'ro_RO', 'uk_UA', 'tr_TR', 'el_GR', 'he_IL', 'ar_SA', 'hi_IN', 'th_TH', 'vi_VN'];

  int get currentStep => _currentStep;
  String get selectedLanguage => _selectedLanguage;
  String get selectedDisk => _selectedDisk;
  String get partitionScheme => _partitionScheme;
  bool get encryptionEnabled => _encryptionEnabled;
  bool get useTpm => _useTpm;
  String get username => _username;
  String get realname => _realname;
  String get password => _password;
  String get passwordConfirm => _passwordConfirm;
  String get timezone => _timezone;
  String get locale => _locale;
  String get hostname => _hostname;
  double get installProgress => _installProgress;
  String get currentStage => _currentStage;
  bool get isInstalling => _isInstalling;
  bool get installComplete => _installComplete;
  String get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get disks => _disks;
  List<String> get timezones => _timezones;
  List<String> get locales => _locales;

  bool get canProceed {
    switch (_currentStep) {
      case 0:
        return true;
      case 1:
        return _selectedDisk.isNotEmpty;
      case 2:
        return true;
      case 3:
        return _password == _passwordConfirm && _password.length >= 6;
      case 4:
        return _username.isNotEmpty && _hostname.isNotEmpty;
      case 5:
        return true;
      default:
        return false;
    }
  }

  void nextStep() {
    if (_currentStep < 6 && canProceed) {
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

  void setLanguage(String lang) {
    _selectedLanguage = lang;
    notifyListeners();
  }

  void setDisk(String disk) {
    _selectedDisk = disk;
    notifyListeners();
  }

  void setPartitionScheme(String scheme) {
    _partitionScheme = scheme;
    notifyListeners();
  }

  void setEncryptionEnabled(bool val) {
    _encryptionEnabled = val;
    notifyListeners();
  }

  void setUseTpm(bool val) {
    _useTpm = val;
    notifyListeners();
  }

  void setUsername(String val) {
    _username = val;
    notifyListeners();
  }

  void setRealname(String val) {
    _realname = val;
    notifyListeners();
  }

  void setPassword(String val) {
    _password = val;
    notifyListeners();
  }

  void setPasswordConfirm(String val) {
    _passwordConfirm = val;
    notifyListeners();
  }

  void setTimezone(String val) {
    _timezone = val;
    notifyListeners();
  }

  void setLocale(String val) {
    _locale = val;
    notifyListeners();
  }

  void setHostname(String val) {
    _hostname = val;
    notifyListeners();
  }

  Future<void> loadDisks() async {
    try {
      final process = await Process.run('dbus-send', [
        '--session',
        '--dest=org.arynox.Installer',
        '--print-reply',
        '/org/arynox/Installer',
        'org.arynox.Installer.ListDisks',
      ]);
      if (process.exitCode == 0) {
        final result = process.stdout as String;
        _disks = List<Map<String, dynamic>>.from(
            json.decode(result) as List);
      } else {
        _disks = _getSimulatedDisks();
      }
    } catch (_) {
      _disks = _getSimulatedDisks();
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> _getSimulatedDisks() {
    return [
      {
        'path': '/dev/nvme0n1',
        'model': 'Samsung SSD 980 PRO 1TB',
        'size': 1000204886016,
        'sector_size': 512,
        'is_ssd': true,
        'is_nvme': true,
        'partitions': [
          {'path': '/dev/nvme0n1p1', 'number': 1, 'size': 1073741824, 'fs_type': 'vfat', 'label': 'EFI'},
          {'path': '/dev/nvme0n1p2', 'number': 2, 'size': 8589934592, 'fs_type': 'swap', 'label': 'SWAP'},
          {'path': '/dev/nvme0n1p3', 'number': 3, 'size': 989560464998, 'fs_type': 'btrfs', 'label': 'ROOT'},
        ],
      },
      {
        'path': '/dev/sda',
        'model': 'Crucial MX500 500GB',
        'size': 500107862016,
        'sector_size': 512,
        'is_ssd': true,
        'is_nvme': false,
        'partitions': [],
      },
    ];
  }

  Future<void> startInstallation() async {
    if (_isInstalling) return;
    _isInstalling = true;
    _installProgress = 0.0;
    _installComplete = false;
    _errorMessage = '';
    notifyListeners();

    final stages = [
      {'stage': 'partitioning', 'weight': 0.15, 'msg': 'Partitioning disk...'},
      {'stage': 'encryption', 'weight': 0.10, 'msg': 'Setting up encryption...'},
      {'stage': 'formatting', 'weight': 0.10, 'msg': 'Creating filesystems...'},
      {'stage': 'subvolumes', 'weight': 0.10, 'msg': 'Creating BTRFS subvolumes...'},
      {'stage': 'extracting', 'weight': 0.25, 'msg': 'Installing base system...'},
      {'stage': 'configuring', 'weight': 0.10, 'msg': 'Configuring system...'},
      {'stage': 'user', 'weight': 0.05, 'msg': 'Creating user account...'},
      {'stage': 'bootloader', 'weight': 0.10, 'msg': 'Installing bootloader...'},
      {'stage': 'finalizing', 'weight': 0.05, 'msg': 'Finalizing installation...'},
    ];

    double progress = 0.0;
    for (final stage in stages) {
      if (!_isInstalling) break;
      _currentStage = stage['msg'] as String;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 800));
      progress += stage['weight'] as double;
      _installProgress = progress.clamp(0.0, 1.0);
      notifyListeners();
    }

    if (_isInstalling) {
      _installProgress = 1.0;
      _currentStage = 'Installation complete!';
      _installComplete = true;
      _isInstalling = false;
      notifyListeners();
    }
  }

  void reset() {
    _currentStep = 0;
    _installProgress = 0.0;
    _currentStage = '';
    _isInstalling = false;
    _installComplete = false;
    _errorMessage = '';
    notifyListeners();
  }

  static List<String> _generateTimezones() {
    return [
      'UTC', 'America/New_York', 'America/Chicago', 'America/Denver',
      'America/Los_Angeles', 'America/Anchorage', 'Pacific/Honolulu',
      'Europe/London', 'Europe/Paris', 'Europe/Berlin', 'Europe/Moscow',
      'Europe/Madrid', 'Europe/Rome', 'Europe/Amsterdam', 'Europe/Stockholm',
      'Europe/Oslo', 'Europe/Copenhagen', 'Europe/Helsinki', 'Europe/Warsaw',
      'Europe/Prague', 'Europe/Budapest', 'Europe/Athens', 'Europe/Istanbul',
      'Asia/Dubai', 'Asia/Kolkata', 'Asia/Bangkok', 'Asia/Singapore',
      'Asia/Shanghai', 'Asia/Tokyo', 'Asia/Seoul', 'Asia/Hong_Kong',
      'Australia/Sydney', 'Australia/Melbourne', 'Pacific/Auckland',
      'Africa/Cairo', 'Africa/Lagos', 'Africa/Johannesburg',
      'America/Sao_Paulo', 'America/Argentina/Buenos_Aires',
      'America/Mexico_City', 'America/Toronto', 'America/Vancouver',
    ];
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
            colors: [Color(0xFF0D1117), Color(0xFF161B22), Color(0xFF0D1117)],
          ),
        ),
        child: SafeArea(
          child: Consumer<InstallerState>(
            builder: (context, state, _) {
              return Column(
                children: [
                  _buildHeader(context, state),
                  Expanded(
                    child: _buildStepContent(context, state),
                  ),
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
        border: Border(
          bottom: BorderSide(color: Color(0xFF21262D), width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildGlassContainer(
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.circle, color: Color(0xFF6C63FF), size: 32),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Arynox OS Installer',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          _buildStepIndicator(state.currentStep),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    final steps = ['Language', 'Disk', 'Encryption', 'User', 'System', 'Summary', 'Install'];
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildGlassContainer(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? const Color(0xFF00D9FF)
                          : isActive
                              ? const Color(0xFF6C63FF)
                              : Colors.transparent,
                      border: Border.all(
                        color: isActive || isCompleted
                            ? Colors.transparent
                            : const Color(0xFF30363D),
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isActive ? Colors.white : const Color(0xFF484F58),
                              ),
                            ),
                          ),
                  ),
                  if (isActive || isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 11,
                          color: isCompleted
                              ? const Color(0xFF00D9FF)
                              : Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNavigation(BuildContext context, InstallerState state) {
    if (state.isInstalling || state.installComplete) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF21262D), width: 1),
        ),
      ),
      child: Row(
        children: [
          if (state.currentStep > 0)
            _buildGlassButton(
              onPressed: () => state.previousStep(),
              child: const Text('Back', style: TextStyle(color: Colors.white)),
            ),
          const Spacer(),
          _buildGlassButton(
            onPressed: state.canProceed ? () => state.nextStep() : null,
            isPrimary: true,
            child: Text(
              state.currentStep == 6 ? 'Begin Installation' : 'Next',
              style: TextStyle(
                color: state.canProceed ? Colors.white : const Color(0xFF484F58),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, InstallerState state) {
    final pages = [
      _WelcomePage(),
      _DiskSelectionPage(),
      _PartitionSchemePage(),
    ];

    if (state.currentStep < pages.length) {
      return pages[state.currentStep];
    }

    switch (state.currentStep) {
      case 3:
        return _EncryptionPage();
      case 4:
        return _UserCreationPage();
      case 5:
        return _SystemConfigPage();
      case 6:
        return _InstallSummaryPage();
      case 7:
        return _InstallProgressPage();
      default:
        return _WelcomePage();
    }
  }

  static Widget _buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: child,
        ),
      ),
    );
  }

  static Widget _buildGlassButton({
    VoidCallback? onPressed,
    bool isPrimary = false,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: isPrimary
              ? const Color(0xFF6C63FF).withOpacity(0.8)
              : const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPrimary
                      ? const Color(0xFF6C63FF)
                      : const Color(0x33FFFFFF),
                ),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<InstallerState>(
      builder: (context, state, _) {
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, size: 80, color: const Color(0xFF6C63FF)),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to Arynox OS',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w300, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  'A modern, secure, and performant operating system',
                  style: TextStyle(fontSize: 16, color: Color(0xFF8B949E)),
                ),
                const SizedBox(height: 48),
                const Text(
                  'Select Language',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 300,
                  child: InstallerWizard._buildGlassContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: state.selectedLanguage,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF161B22),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          items: const [
                            DropdownMenuItem(value: 'en', child: Text('English')),
                            DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                            DropdownMenuItem(value: 'fr', child: Text('Français')),
                            DropdownMenuItem(value: 'es', child: Text('Español')),
                            DropdownMenuItem(value: 'ja', child: Text('日本語')),
                            DropdownMenuItem(value: 'zh', child: Text('中文')),
                          ],
                          onChanged: (val) => state.setLanguage(val!),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                InstallerWizard._buildGlassButton(
                  isPrimary: true,
                  onPressed: () => state.nextStep(),
                  child: const Text('Get Started', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DiskSelectionPage extends StatefulWidget {
  @override
  State<_DiskSelectionPage> createState() => _DiskSelectionPageState();
}

class _DiskSelectionPageState extends State<_DiskSelectionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InstallerState>().loadDisks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InstallerState>(
      builder: (context, state, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Installation Disk', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Choose the disk where Arynox OS will be installed', style: TextStyle(fontSize: 14, color: Color(0xFF8B949E))),
              const SizedBox(height: 24),
              ...state.disks.map((disk) => _DiskCard(disk: disk)),
            ],
          ),
        );
      },
    );
  }
}

class _DiskCard extends StatelessWidget {
  final Map<String, dynamic> disk;

  const _DiskCard({required this.disk});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InstallerState>();
    final isSelected = state.selectedDisk == disk['path'];
    final sizeGb = (disk['size'] as num) / 1e9;
    final diskLabel = disk['is_nvme'] == true ? 'NVMe' : 'SATA';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => state.setDisk(disk['path'] as String),
        child: InstallerWizard._buildGlassContainer(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  disk['is_nvme'] == true ? Icons.memory : Icons.storage,
                  color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF8B949E),
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        disk['model'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFFC9D1D9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${disk['path']}  |  ${sizeGb.toStringAsFixed(1)} GB  |  $diskLabel  |  ${(disk['partitions'] as List).length} partitions',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF8B949E)),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Color(0xFF6C63FF), size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PartitionSchemePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<InstallerState>();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Partition Scheme', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: Colors.white)),
            const SizedBox(height: 32),
            SizedBox(
              width: 500,
              child: Row(
                children: [
                  Expanded(
                    child: _SchemeCard(
                      icon: Icons.auto_awesome,
                      title: 'Automatic',
                      subtitle: 'Let the installer handle partitioning',
                      isSelected: state.partitionScheme == 'automatic',
                      onTap: () => state.setPartitionScheme('automatic'),
                      features: ['BTRFS with subvolumes', 'LUKS encryption', 'Optimal layout'],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SchemeCard(
                      icon: Icons.tune,
                      title: 'Manual',
                      subtitle: 'Advanced partition layout',
                      isSelected: state.partitionScheme == 'manual',
                      onTap: () => state.setPartitionScheme('manual'),
                      features: ['Custom sizes', 'Multiple disks', 'Advanced options'],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchemeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final List<String> features;

  const _SchemeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: InstallerWizard._buildGlassContainer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF8B949E), size: 48),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFFC9D1D9))),
              const SizedBox(height: 8),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF8B949E)), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 14, color: Color(0xFF00D9FF)),
                    const SizedBox(width: 8),
                    Text(f, style: const TextStyle(fontSize: 12, color: Color(0xFF8B949E))),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _EncryptionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<InstallerState>();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Disk Encryption', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Secure your data with LUKS encryption', style: TextStyle(fontSize: 14, color: Color(0xFF8B949E))),
            const SizedBox(height: 32),
            SizedBox(
              width: 400,
              child: InstallerWizard._buildGlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Enable Encryption', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('LUKS2 with AES-256', style: TextStyle(color: Color(0xFF8B949E), fontSize: 13)),
                        value: state.encryptionEnabled,
                        activeColor: const Color(0xFF6C63FF),
                        onChanged: (val) => state.setEncryptionEnabled(val),
                      ),
                      if (state.encryptionEnabled) ...[
                        const Divider(color: Color(0xFF21262D)),
                        SwitchListTile(
                          title: const Text('TPM 2.0 Unlock', style: TextStyle(color: Colors.white)),
                          subtitle: const Text('Auto-unlock on trusted hardware', style: TextStyle(color: Color(0xFF8B949E), fontSize: 13)),
                          value: state.useTpm,
                          activeColor: const Color(0xFF6C63FF),
                          onChanged: (val) => state.setUseTpm(val),
                        ),
                        const Divider(color: Color(0xFF21262D)),
                        _PasswordField(
                          label: 'Encryption Password',
                          hint: 'Enter strong password',
                          obscure: true,
                          onChanged: (val) => state.setPassword(val),
                        ),
                        const SizedBox(height: 12),
                        _PasswordField(
                          label: 'Confirm Password',
                          hint: 'Re-enter password',
                          obscure: true,
                          onChanged: (val) => state.setPasswordConfirm(val),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final String hint;
  final bool obscure;
  final ValueChanged<String> onChanged;

  const _PasswordField({required this.label, required this.hint, required this.obscure, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFC9D1D9), fontSize: 13)),
        const SizedBox(height: 6),
        InstallerWizard._buildGlassContainer(
          child: TextField(
            obscureText: obscure,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF484F58)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _UserCreationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<InstallerState>();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Create Your Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: Colors.white)),
            const SizedBox(height: 32),
            SizedBox(
              width: 400,
              child: InstallerWizard._buildGlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _TextField(
                        label: 'Your Name',
                        hint: 'John Doe',
                        icon: Icons.person,
                        onChanged: (val) => state.setRealname(val),
                      ),
                      const SizedBox(height: 16),
                      _TextField(
                        label: 'Username',
                        hint: 'johndoe',
                        icon: Icons.account_circle,
                        onChanged: (val) => state.setUsername(val),
                      ),
                      const SizedBox(height: 16),
                      _TextField(
                        label: 'Password',
                        hint: 'Minimum 6 characters',
                        icon: Icons.lock,
                        obscure: true,
                        onChanged: (val) => state.setPassword(val),
                      ),
                      const SizedBox(height: 16),
                      _TextField(
                        label: 'Confirm Password',
                        hint: 'Re-enter password',
                        icon: Icons.lock_outline,
                        obscure: true,
                        onChanged: (val) => state.setPasswordConfirm(val),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final ValueChanged<String> onChanged;

  const _TextField({
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFC9D1D9), fontSize: 13)),
        const SizedBox(height: 6),
        InstallerWizard._buildGlassContainer(
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(icon, color: const Color(0xFF484F58), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  obscureText: obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: Color(0xFF484F58)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SystemConfigPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<InstallerState>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('System Configuration', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: Colors.white)),
          const SizedBox(height: 32),
          SizedBox(
            width: 500,
            child: InstallerWizard._buildGlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _TextField(
                      label: 'Hostname',
                      hint: 'arynox',
                      icon: Icons.computer,
                      onChanged: (val) => state.setHostname(val),
                    ),
                    const SizedBox(height: 20),
                    _DropdownField(
                      label: 'Timezone',
                      value: state.timezone,
                      items: state.timezones,
                      onChanged: (val) => state.setTimezone(val!),
                    ),
                    const SizedBox(height: 20),
                    _DropdownField(
                      label: 'Locale',
                      value: state.locale,
                      items: state.locales,
                      onChanged: (val) => state.setLocale(val!),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFC9D1D9), fontSize: 13)),
        const SizedBox(height: 6),
        InstallerWizard._buildGlassContainer(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: const Color(0xFF161B22),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InstallSummaryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<InstallerState>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Installation Summary', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Review your configuration before installing', style: TextStyle(fontSize: 14, color: Color(0xFF8B949E))),
          const SizedBox(height: 32),
          SizedBox(
            width: 600,
            child: InstallerWizard._buildGlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Disk', value: state.selectedDisk.split('/').last),
                    _SummaryRow(label: 'Scheme', value: 'GPT + BTRFS (${state.partitionScheme})'),
                    _SummaryRow(label: 'Encryption', value: state.encryptionEnabled ? 'LUKS2 AES-256${state.useTpm ? ' + TPM' : ''}' : 'None'),
                    _SummaryRow(label: 'Username', value: state.username),
                    _SummaryRow(label: 'Hostname', value: state.hostname),
                    _SummaryRow(label: 'Timezone', value: state.timezone),
                    _SummaryRow(label: 'Locale', value: state.locale),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          InstallerWizard._buildGlassButton(
            isPrimary: true,
            onPressed: () {
              state.nextStep();
              state.startInstallation();
            },
            child: const Text('Install Arynox OS', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!state.installComplete) ...[
              const Text('Installing Arynox OS', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: Colors.white)),
              const SizedBox(height: 48),
              SizedBox(
                width: 400,
                child: _AnimatedProgressBar(progress: state.installProgress),
              ),
              const SizedBox(height: 24),
              Text(
                state.currentStage,
                style: const TextStyle(fontSize: 16, color: Color(0xFF8B949E)),
              ),
              const SizedBox(height: 16),
              Text(
                '${(state.installProgress * 100).toInt()}%',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w200, color: Color(0xFF6C63FF)),
              ),
            ] else ...[
              const Icon(Icons.check_circle, color: Color(0xFF00D9FF), size: 80),
              const SizedBox(height: 24),
              const Text('Installation Complete!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Arynox OS has been installed successfully', style: TextStyle(fontSize: 16, color: Color(0xFF8B949E))),
              const SizedBox(height: 48),
              InstallerWizard._buildGlassButton(
                isPrimary: true,
                onPressed: () => SystemNavigator.pop(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restart_alt, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Reboot', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimatedProgressBar extends StatefulWidget {
  final double progress;
  const _AnimatedProgressBar({required this.progress});

  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return InstallerWizard._buildGlassContainer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 12,
              width: double.infinity,
              color: const Color(0x1AFFFFFF),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: widget.progress,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF00D9FF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
