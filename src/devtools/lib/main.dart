import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

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
        fontFamily: GoogleFonts.inter().fontFamily,
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
  bool _devMode = false;
  bool _sshRunning = false;
  int _selectedIndex = 0;
  Map<String, dynamic> _sysInfo = {};
  List<dynamic> _containers = [];
  List<dynamic> _logs = [];
  String _gitOutput = '';
  final _gitController = TextEditingController();
  final _logSearchController = TextEditingController();
  Timer? _pollTimer;

  final String _apiBase = 'http://localhost:9876/api';

  @override
  void initState() {
    super.initState();
    _fetchSystemInfo();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchSystemInfo();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _gitController.dispose();
    _logSearchController.dispose();
    super.dispose();
  }

  Future<void> _dubusCall(String method, {Map<String, dynamic>? args}) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/$method'),
        headers: {'Content-Type': 'application/json'},
        body: args != null ? jsonEncode(args) : null,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {});
        return data;
      }
    } catch (e) {
      debugPrint('API call failed: $e');
    }
    return null;
  }

  Future<void> _fetchSystemInfo() async {
    final response = await _dubusCall('system_info');
    if (response != null && response['success']) {
      setState(() {
        _sysInfo = response['data'] ?? {};
      });
    }
  }

  Future<void> _toggleDevMode(bool value) async {
    final method = value ? 'enable_dev_mode' : 'disable_dev_mode';
    await _dubusCall(method);
    setState(() => _devMode = value);
  }

  Future<void> _toggleSSH(bool value) async {
    final method = value ? 'start_ssh' : 'stop_ssh';
    await _dubusCall(method);
    setState(() => _sshRunning = value);
  }

  Future<void> _runGitCommand() async {
    final response = await _dubusCall('git_command', args: {
      'args': _gitController.text.split(' '),
    });
    if (response != null && response['success']) {
      setState(() => _gitOutput = response['data']['output'] ?? '');
    }
  }

  Future<void> _fetchContainers() async {
    final response = await _dubusCall('docker_ps');
    if (response != null && response['success']) {
      setState(() => _containers = response['data']['containers'] ?? []);
    }
  }

  Future<void> _fetchLogs() async {
    final response = await _dubusCall('get_logs');
    if (response != null && response['success']) {
      setState(() => _logs = response['data']['logs'] ?? []);
    }
  }

  Widget _buildGlassCard(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDevToolsDashboard() {
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
              Text('Developer Tools',
                  style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: _buildGlassCard(
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Developer Mode', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          Switch(
                            value: _devMode,
                            onChanged: _toggleDevMode,
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('SSH Server', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          Switch(
                            value: _sshRunning,
                            onChanged: _toggleSSH,
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('System Profiler'),
          _buildGlassCard(
            Column(
              children: [
                _buildStatRow('CPU', '${_sysInfo['cpu']?['model'] ?? 'N/A'} - ${_sysInfo['cpu']?['cores'] ?? 0} cores'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(10, (i) => FlSpot(i.toDouble(), (i % 5) * 20.0)),
                          isCurved: true,
                          color: Colors.cyan,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: Colors.cyan.withOpacity(0.1)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatRow('Memory', '${(_sysInfo['memory']?['used_kb'] ?? 0) / 1024 / 1024:.1f} GB / ${(_sysInfo['memory']?['total_kb'] ?? 0) / 1024 / 1024:.1f} GB'),
                LinearProgressIndicator(
                  value: (_sysInfo['memory']?['percent'] ?? 0) / 100,
                  backgroundColor: Colors.white10,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildStatRow('Disk', '${_sysInfo['disk']?['used_gb'] ?? 0:.1f} GB / ${_sysInfo['disk']?['total_gb'] ?? 0:.1f} GB'),
                LinearProgressIndicator(
                  value: (_sysInfo['disk']?['percent'] ?? 0) / 100,
                  backgroundColor: Colors.white10,
                  color: Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildStatRow('GPU', '${_sysInfo['gpu']?['model'] ?? 'N/A'} (${_sysInfo['gpu']?['memory_mb'] ?? 0} MB)'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('Languages & Tools'),
          _buildGlassCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildToolRow('Python', '3.12.0'),
                _buildToolRow('Rust', '1.75.0'),
                _buildToolRow('Node.js', '20.11.0'),
                _buildToolRow('Java', '21.0.2'),
                _buildToolRow('C/C++', 'GCC 13.2.0'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.code),
                    label: const Text('Launch VS Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.terminal),
                    label: const Text('Open Terminal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('Git Operations'),
          _buildGlassCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _gitController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'git command (e.g. status, log --oneline)',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _runGitCommand,
                      icon: const Icon(Icons.play_arrow, color: Colors.green),
                    ),
                  ],
                ),
                if (_gitOutput.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      _gitOutput,
                      style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('Containers'),
          _buildGlassCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Running Containers', style: TextStyle(color: Colors.white70)),
                    IconButton(
                      onPressed: _fetchContainers,
                      icon: const Icon(Icons.refresh, color: Colors.white54),
                    ),
                  ],
                ),
                if (_containers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('No containers running', style: TextStyle(color: Colors.white38))),
                  )
                else
                  ..._containers.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: c['status']?.toString().contains('Up') == true ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(c['name'] ?? '', style: const TextStyle(color: Colors.white))),
                        Text(c['status'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  )),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('Log Viewer'),
          _buildGlassCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _logSearchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search logs...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterChip('INFO', Colors.blue),
                    _buildFilterChip('WARN', Colors.orange),
                    _buildFilterChip('ERROR', Colors.red),
                    _buildFilterChip('DEBUG', Colors.grey),
                    const Spacer(),
                    IconButton(
                      onPressed: _fetchLogs,
                      icon: const Icon(Icons.refresh, color: Colors.white54),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 250,
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, i) {
                      final log = _logs[i];
                      final msg = log['message'] ?? '';
                      if (_logSearchController.text.isNotEmpty &&
                          !msg.toString().toLowerCase().contains(_logSearchController.text.toLowerCase())) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text(log['timestamp']?.toString().substring(0, 19) ?? '',
                                style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: _logColor(log['priority'] ?? 6).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(_priorityLabel(log['priority'] ?? 6),
                                  style: TextStyle(color: _logColor(log['priority'] ?? 6), fontSize: 10)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(msg.toString(),
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildToolRow(String language, String version) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(language, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 12),
          Text(version, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        selected: true,
        onSelected: (_) {},
        backgroundColor: color.withOpacity(0.1),
        selectedColor: color.withOpacity(0.2),
        checkmarkColor: color,
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(fontSize: 11),
      ),
    );
  }

  Color _logColor(int priority) {
    if (priority <= 2) return Colors.red;
    if (priority <= 4) return Colors.orange;
    if (priority == 6) return Colors.blue;
    return Colors.grey;
  }

  String _priorityLabel(int priority) {
    if (priority <= 2) return 'ERR';
    if (priority <= 4) return 'WARN';
    if (priority == 6) return 'INFO';
    return 'DBUG';
  }

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
            ],
          ),
          Expanded(child: _buildDevToolsDashboard()),
        ],
      ),
    );
  }
}
