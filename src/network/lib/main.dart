import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Theme constants
// ---------------------------------------------------------------------------

const Color kBgDark = Color(0xFF0F1023);
const Color kBgCard = Color(0xFF1A1B2E);
const Color kAccent = Color(0xFF6C5CE7);
const Color kTextPrimary = Color(0xFFF0F0F5);
const Color kTextSecondary = Color(0xFF8B8DA3);
const Color kGreen = Color(0xFF00D68F);
const Color kRed = Color(0xFFFF6B6B);
const Color kOrange = Color(0xFFFFA94D);

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class WiFiNetwork {
  final String ssid;
  final String bssid;
  final int frequency;
  final int signalStrength;
  final String security;
  final bool saved;

  WiFiNetwork({
    required this.ssid,
    required this.bssid,
    required this.frequency,
    required this.signalStrength,
    required this.security,
    required this.saved,
  });

  factory WiFiNetwork.fromJson(Map<String, dynamic> json) => WiFiNetwork(
        ssid: json['ssid'] ?? '',
        bssid: json['bssid'] ?? '',
        frequency: json['frequency'] ?? 0,
        signalStrength: json['signal_strength'] ?? 0,
        security: json['security'] ?? '',
        saved: json['saved'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'ssid': ssid,
        'bssid': bssid,
        'frequency': frequency,
        'signal_strength': signalStrength,
        'security': security,
        'saved': saved,
      };
}

class BluetoothDevice {
  final String address;
  final String name;
  final bool paired;
  final bool connected;
  final bool tetheringEnabled;

  BluetoothDevice({
    required this.address,
    required this.name,
    required this.paired,
    required this.connected,
    required this.tetheringEnabled,
  });

  factory BluetoothDevice.fromJson(Map<String, dynamic> json) =>
      BluetoothDevice(
        address: json['address'] ?? '',
        name: json['name'] ?? '',
        paired: json['paired'] ?? false,
        connected: json['connected'] ?? false,
        tetheringEnabled: json['tethering_enabled'] ?? false,
      );
}

class EthernetConfig {
  final String interface;
  final String mac;
  final String? ipv4;
  final String? ipv6;
  final String? gateway;
  final List<String> dns;
  final bool linkUp;
  final int speedMbps;

  EthernetConfig({
    required this.interface,
    required this.mac,
    this.ipv4,
    this.ipv6,
    this.gateway,
    required this.dns,
    required this.linkUp,
    required this.speedMbps,
  });

  factory EthernetConfig.fromJson(Map<String, dynamic> json) =>
      EthernetConfig(
        interface: json['interface'] ?? '',
        mac: json['mac'] ?? '',
        ipv4: json['ipv4'],
        ipv6: json['ipv6'],
        gateway: json['gateway'],
        dns: List<String>.from(json['dns'] ?? []),
        linkUp: json['link_up'] ?? false,
        speedMbps: json['speed_mbps'] ?? 0,
      );
}

class VPNConnection {
  final String uuid;
  final String name;
  final String vpnType;
  final String state;
  final bool autoconnect;

  VPNConnection({
    required this.uuid,
    required this.name,
    required this.vpnType,
    required this.state,
    required this.autoconnect,
  });

  bool get connected => state == 'connected';

  factory VPNConnection.fromJson(Map<String, dynamic> json) => VPNConnection(
        uuid: json['uuid'] ?? '',
        name: json['name'] ?? '',
        vpnType: json['vpn_type'] ?? '',
        state: json['state'] ?? 'disconnected',
        autoconnect: json['autoconnect'] ?? false,
      );
}

class LANDevice {
  final String ip;
  final String mac;
  final String hostname;
  final List<String> services;

  LANDevice({
    required this.ip,
    required this.mac,
    required this.hostname,
    required this.services,
  });

  factory LANDevice.fromJson(Map<String, dynamic> json) => LANDevice(
        ip: json['ip'] ?? '',
        mac: json['mac'] ?? '',
        hostname: json['hostname'] ?? '',
        services: List<String>.from(json['services'] ?? []),
      );
}

class DiscoveredDevice {
  final String ip;
  final String mac;
  final String hostname;
  final String deviceType;
  final String osHint;
  final List<int> openPorts;

  DiscoveredDevice({
    required this.ip,
    required this.mac,
    required this.hostname,
    required this.deviceType,
    required this.osHint,
    required this.openPorts,
  });

  factory DiscoveredDevice.fromJson(Map<String, dynamic> json) =>
      DiscoveredDevice(
        ip: json['ip'] ?? '',
        mac: json['mac'] ?? '',
        hostname: json['hostname'] ?? '',
        deviceType: json['device_type'] ?? '',
        osHint: json['os_hint'] ?? '',
        openPorts: List<int>.from(json['open_ports'] ?? []),
      );
}

class FirewallRule {
  final String chain;
  final String protocol;
  final String src;
  final String dst;
  final int port;
  final String action;

  FirewallRule({
    required this.chain,
    required this.protocol,
    required this.src,
    required this.dst,
    required this.port,
    required this.action,
  });

  factory FirewallRule.fromJson(Map<String, dynamic> json) => FirewallRule(
        chain: json['chain'] ?? '',
        protocol: json['protocol'] ?? '',
        src: json['src'] ?? '',
        dst: json['dst'] ?? '',
        port: json['port'] ?? 0,
        action: json['action'] ?? '',
      );
}

class ProxyConfig {
  final String? httpProxy;
  final String? httpsProxy;
  final String? ftpProxy;
  final List<String> noProxy;
  final String? socksProxy;

  ProxyConfig({
    this.httpProxy,
    this.httpsProxy,
    this.ftpProxy,
    required this.noProxy,
    this.socksProxy,
  });

  bool get isSet =>
      httpProxy != null ||
      httpsProxy != null ||
      ftpProxy != null ||
      socksProxy != null;

  factory ProxyConfig.fromJson(Map<String, dynamic> json) => ProxyConfig(
        httpProxy: json['http_proxy'],
        httpsProxy: json['https_proxy'],
        ftpProxy: json['ftp_proxy'],
        noProxy: List<String>.from(json['no_proxy'] ?? []),
        socksProxy: json['socks_proxy'],
      );
}

class Printer {
  final String name;
  final String uri;
  final String model;
  final String status;
  final String location;

  Printer({
    required this.name,
    required this.uri,
    required this.model,
    required this.status,
    required this.location,
  });

  factory Printer.fromJson(Map<String, dynamic> json) => Printer(
        name: json['name'] ?? '',
        uri: json['uri'] ?? '',
        model: json['model'] ?? '',
        status: json['status'] ?? '',
        location: json['location'] ?? '',
      );
}

// ---------------------------------------------------------------------------
// D-Bus client emulation via HTTP (placeholder for real D-Bus integration)
// ---------------------------------------------------------------------------

class NetworkDBusClient {
  static const String _baseUrl = 'http://localhost:8080/dbus';

  Future<Map<String, dynamic>> _call(String method,
      {Map<String, dynamic> args = const {}}) async {
    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse('$_baseUrl/$method'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(args));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      return jsonDecode(body);
    } catch (_) {
      return {
        'type': 'Error',
        'code': 503,
        'message': 'D-Bus backend not available'
      };
    }
  }

  Future<List<WiFiNetwork>> scanWifi() async {
    final res = await _call('scan_wifi');
    if (res['type'] == 'Success' && res['data'] != null) {
      return (res['data'] as List)
          .map((e) => WiFiNetwork.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<List<BluetoothDevice>> scanBluetooth() async {
    final res = await _call('scan_bluetooth');
    if (res['type'] == 'Success' && res['data'] != null) {
      return (res['data'] as List)
          .map((e) => BluetoothDevice.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<EthernetConfig?> getEthernetStatus() async {
    final res = await _call('get_ethernet_status');
    if (res['type'] == 'Success' && res['data'] != null) {
      return EthernetConfig.fromJson(res['data']);
    }
    return null;
  }

  Future<List<VPNConnection>> getVPNs() async {
    final res = await _call('get_vpn_connections');
    if (res['type'] == 'Success' && res['data'] != null) {
      return (res['data'] as List)
          .map((e) => VPNConnection.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<List<LANDevice>> discoverLAN() async {
    final res = await _call('discover_lan');
    if (res['type'] == 'Success' && res['data'] != null) {
      return (res['data'] as List).map((e) => LANDevice.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<DiscoveredDevice>> discoverNearby() async {
    final res = await _call('discover_nearby_devices');
    if (res['type'] == 'Success' && res['data'] != null) {
      return (res['data'] as List)
          .map((e) => DiscoveredDevice.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<bool> setFirewallEnabled(bool enabled) async {
    final res = await _call('set_firewall_enabled', args: {'enabled': enabled});
    return res['type'] == 'Success';
  }

  Future<Map<String, dynamic>?> getFirewallStatus() async {
    return await _call('get_firewall_status');
  }

  Future<ProxyConfig?> getProxyConfig() async {
    final res = await _call('get_proxy_config');
    if (res['type'] == 'Success' && res['data'] != null) {
      return ProxyConfig.fromJson(res['data']);
    }
    return null;
  }

  Future<List<Printer>> discoverPrinters() async {
    final res = await _call('discover_printers');
    if (res['type'] == 'Success' && res['data'] != null) {
      return (res['data'] as List).map((e) => Printer.fromJson(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> call(String method,
      {Map<String, dynamic> args = const {}}) async {
    return await _call(method, args: args);
  }
}

// ---------------------------------------------------------------------------
// Pages
// ---------------------------------------------------------------------------

class WifiPage extends StatefulWidget {
  final NetworkDBusClient client;
  const WifiPage({super.key, required this.client});

  @override
  State<WifiPage> createState() => _WifiPageState();
}

class _WifiPageState extends State<WifiPage> {
  List<WiFiNetwork> _networks = [];
  List<WiFiNetwork> _saved = [];
  bool _loading = true;
  bool _showSaved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final nets = await widget.client.scanWifi();
    if (mounted) setState(() {
      _networks = nets;
      _saved = nets.where((n) => n.saved).toList();
      _loading = false;
    });
  }

  IconData _signalIcon(int rssi) {
    if (rssi >= -50) return Icons.wifi;
    if (rssi >= -65) return Icons.wifi_2_bar;
    if (rssi >= -75) return Icons.wifi_1_bar;
    return Icons.wifi_find;
  }

  Color _signalColor(int rssi) {
    if (rssi >= -50) return kGreen;
    if (rssi >= -65) return kOrange;
    if (rssi >= -75) return kOrange;
    return kRed;
  }

  @override
  Widget build(BuildContext context) {
    final items = _showSaved ? _saved : _networks;
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_showSaved ? 'Saved Networks' : 'WiFi Networks',
            style: GoogleFonts.poppins(color: kTextPrimary)),
        actions: [
          IconButton(
            icon: Icon(_showSaved ? Icons.wifi : Icons.bookmark,
                color: kAccent),
            onPressed: () => setState(() => _showSaved = !_showSaved),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: kTextPrimary),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccent))
          : items.isEmpty
              ? Center(
                  child: Text('No networks found',
                      style: GoogleFonts.poppins(color: kTextSecondary)))
              : RefreshIndicator(
                  color: kAccent,
                  backgroundColor: kBgDark,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final net = items[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: kBgCard.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kAccent.withOpacity(0.15)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Icon(_signalIcon(net.signalStrength),
                              color: _signalColor(net.signalStrength), size: 32),
                          title: Text(net.ssid,
                              style: GoogleFonts.poppins(
                                  color: kTextPrimary,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${net.security}  ${net.frequency}MHz  ${net.signalStrength}dBm',
                              style: GoogleFonts.poppins(
                                  color: kTextSecondary, fontSize: 12)),
                          trailing: IconButton(
                            icon: Icon(
                                net.saved ? Icons.bookmark : Icons.bookmark_border,
                                color: net.saved ? kAccent : kTextSecondary),
                            onPressed: () {},
                          ),
                          onTap: () => _connectDialog(net),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _connectDialog(WiFiNetwork net) {
    final pwdCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Connect to ${net.ssid}',
            style: GoogleFonts.poppins(color: kTextPrimary)),
        content: net.security == 'Open'
            ? const Text('No password required',
                style: TextStyle(color: kTextSecondary))
            : TextField(
                controller: pwdCtrl,
                obscureText: true,
                style: const TextStyle(color: kTextPrimary),
                decoration: const InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(color: kTextSecondary),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: kAccent)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: kAccent, width: 2)),
                ),
              ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: kTextSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Connecting to ${net.ssid}...'),
                  backgroundColor: kAccent,
                ),
              );
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

class BluetoothPage extends StatefulWidget {
  final NetworkDBusClient client;
  const BluetoothPage({super.key, required this.client});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  List<BluetoothDevice> _devices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final devs = await widget.client.scanBluetooth();
    if (mounted) setState(() {
      _devices = devs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Bluetooth Devices',
            style: GoogleFonts.poppins(color: kTextPrimary)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: kTextPrimary),
              onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccent))
          : _devices.isEmpty
              ? Center(
                  child: Text('No devices found',
                      style: GoogleFonts.poppins(color: kTextSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _devices.length,
                  itemBuilder: (ctx, i) {
                    final d = _devices[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: kBgCard.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kAccent.withOpacity(0.15)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: d.connected
                              ? kGreen.withOpacity(0.2)
                              : kTextSecondary.withOpacity(0.2),
                          child: Icon(Icons.bluetooth,
                              color: d.connected ? kGreen : kTextSecondary),
                        ),
                        title: Text(d.name,
                            style: GoogleFonts.poppins(
                                color: kTextPrimary,
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(d.address,
                            style: GoogleFonts.poppins(
                                color: kTextSecondary, fontSize: 12)),
                        trailing: Switch(
                          value: d.tetheringEnabled,
                          activeColor: kAccent,
                          onChanged: (v) {},
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class VPNPage extends StatefulWidget {
  final NetworkDBusClient client;
  const VPNPage({super.key, required this.client});

  @override
  State<VPNPage> createState() => _VPNPageState();
}

class _VPNPageState extends State<VPNPage> {
  List<VPNConnection> _vpns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final vpns = await widget.client.getVPNs();
    if (mounted) setState(() {
      _vpns = vpns;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('VPN Connections',
            style: GoogleFonts.poppins(color: kTextPrimary)),
        actions: [
          IconButton(
              icon: const Icon(Icons.add, color: kAccent),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.refresh, color: kTextPrimary),
              onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccent))
          : _vpns.isEmpty
              ? Center(
                  child: Text('No VPN connections',
                      style: GoogleFonts.poppins(color: kTextSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _vpns.length,
                  itemBuilder: (ctx, i) {
                    final vpn = _vpns[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: kBgCard.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: vpn.connected
                                ? kGreen.withOpacity(0.4)
                                : kAccent.withOpacity(0.15)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: vpn.connected
                                ? kGreen.withOpacity(0.15)
                                : kTextSecondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            vpn.vpnType == 'WireGuard'
                                ? Icons.lock
                                : Icons.vpn_lock,
                            color: vpn.connected ? kGreen : kTextSecondary,
                          ),
                        ),
                        title: Text(vpn.name,
                            style: GoogleFonts.poppins(
                                color: kTextPrimary,
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(vpn.vpnType,
                            style: GoogleFonts.poppins(
                                color: kTextSecondary, fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: vpn.connected
                                    ? kGreen.withOpacity(0.15)
                                    : kRed.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                vpn.connected ? 'ON' : 'OFF',
                                style: GoogleFonts.poppins(
                                    color:
                                        vpn.connected ? kGreen : kRed,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: vpn.connected,
                              activeColor: kGreen,
                              onChanged: (v) {},
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class LANPage extends StatefulWidget {
  final NetworkDBusClient client;
  const LANPage({super.key, required this.client});

  @override
  State<LANPage> createState() => _LANPageState();
}

class _LANPageState extends State<LANPage> {
  List<LANDevice> _devices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final devs = await widget.client.discoverLAN();
    if (mounted) setState(() {
      _devices = devs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('LAN Devices',
            style: GoogleFonts.poppins(color: kTextPrimary)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: kTextPrimary),
              onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccent))
          : _devices.isEmpty
              ? Center(
                  child: Text('No devices discovered',
                      style: GoogleFonts.poppins(color: kTextSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _devices.length,
                  itemBuilder: (ctx, i) {
                    final d = _devices[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kBgCard.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kAccent.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.computer,
                                  color: kAccent, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(d.hostname,
                                    style: GoogleFonts.poppins(
                                        color: kTextPrimary,
                                        fontWeight: FontWeight.w600)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: kGreen.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(d.ip,
                                    style: GoogleFonts.poppins(
                                        color: kGreen, fontSize: 11)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('MAC: ${d.mac}',
                              style: GoogleFonts.poppins(
                                  color: kTextSecondary, fontSize: 12)),
                          if (d.services.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: d.services
                                  .map((s) => Container(
                                        padding:
                                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: kAccent.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(s,
                                            style: GoogleFonts.poppins(
                                                color: kAccent,
                                                fontSize: 11)),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class FirewallPage extends StatefulWidget {
  final NetworkDBusClient client;
  const FirewallPage({super.key, required this.client});

  @override
  State<FirewallPage> createState() => _FirewallPageState();
}

class _FirewallPageState extends State<FirewallPage> {
  bool _enabled = true;
  List<FirewallRule> _rules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await widget.client.getFirewallStatus();
    if (mounted && res != null) {
      setState(() {
        _enabled = res['data']?['enabled'] ?? true;
        _rules = (res['data']?['rules'] as List? ?? [])
            .map((e) => FirewallRule.fromJson(e))
            .toList();
        _loading = false;
      });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Firewall',
            style: GoogleFonts.poppins(color: kTextPrimary)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: kTextPrimary),
              onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kBgCard.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kAccent.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Firewall',
                              style: GoogleFonts.poppins(
                                  color: kTextPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                              _enabled ? 'Protection active' : 'Disabled',
                              style: GoogleFonts.poppins(
                                  color:
                                      _enabled ? kGreen : kRed,
                                  fontSize: 13)),
                        ],
                      ),
                      Switch(
                        value: _enabled,
                        activeColor: kGreen,
                        onChanged: (v) async {
                          await widget.client.setFirewallEnabled(v);
                          setState(() => _enabled = v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Rules (${_rules.length})',
                    style: GoogleFonts.poppins(
                        color: kTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ..._rules.asMap().entries.map((entry) {
                  final r = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: kBgCard.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: r.action == 'ACCEPT'
                              ? kGreen.withOpacity(0.2)
                              : kRed.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: r.action == 'ACCEPT'
                                ? kGreen
                                : kRed,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${r.chain}  ${r.protocol.endsWith('any') ? 'ALL' : r.protocol.toUpperCase()}  port ${r.port}',
                                  style: GoogleFonts.poppins(
                                      color: kTextPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              Text('${r.src} -> ${r.dst}',
                                  style: GoogleFonts.poppins(
                                      color: kTextSecondary,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: r.action == 'ACCEPT'
                                ? kGreen.withOpacity(0.15)
                                : kRed.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(r.action,
                              style: GoogleFonts.poppins(
                                  color: r.action == 'ACCEPT'
                                      ? kGreen
                                      : kRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class ProxyPage extends StatefulWidget {
  final NetworkDBusClient client;
  const ProxyPage({super.key, required this.client});

  @override
  State<ProxyPage> createState() => _ProxyPageState();
}

class _ProxyPageState extends State<ProxyPage> {
  ProxyConfig? _config;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cfg = await widget.client.getProxyConfig();
    if (mounted) setState(() {
      _config = cfg;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Proxy Settings',
            style: GoogleFonts.poppins(color: kTextPrimary)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: kTextPrimary),
              onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kBgCard.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kAccent.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield, color: kAccent, size: 28),
                          const SizedBox(width: 12),
                          Text('Proxy Configuration',
                              style: GoogleFonts.poppins(
                                  color: kTextPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _proxyField('HTTP Proxy', _config?.httpProxy),
                      _proxyField('HTTPS Proxy', _config?.httpsProxy),
                      _proxyField('FTP Proxy', _config?.ftpProxy),
                      _proxyField('SOCKS Proxy', _config?.socksProxy),
                      if (_config?.noProxy != null &&
                          _config!.noProxy.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('No Proxy:',
                            style: GoogleFonts.poppins(
                                color: kTextSecondary, fontSize: 12)),
                        const SizedBox(height: 4),
                        ..._config!.noProxy.map((h) => Text(h,
                            style: GoogleFonts.poppins(
                                color: kTextPrimary, fontSize: 13))),
                      ],
                    ],
                  ),
                ),
              ],
            ),
  }

  Widget _proxyField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 110,
              child: Text(label,
                  style: GoogleFonts.poppins(
                      color: kTextSecondary, fontSize: 13))),
          Expanded(
            child: Text(value ?? 'Not set',
                style: GoogleFonts.poppins(
                    color: value != null ? kTextPrimary : kTextSecondary,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class SSHPage extends StatefulWidget {
  final NetworkDBusClient client;
  const SSHPage({super.key, required this.client});

  @override
  State<SSHPage> createState() => _SSHPageState();
}

class _SSHPageState extends State<SSHPage> {
  bool _enabled = false;
  bool _running = false;
  int _port = 22;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await widget.client.call('get_ssh_config');
    if (mounted && res['type'] == 'Success' && res['data'] != null) {
      setState(() {
        _enabled = res['data']['enabled'] ?? false;
        _running = res['data']['running'] ?? false;
        _port = res['data']['port'] ?? 22;
        _loading = false;
      });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('SSH Server',
            style: GoogleFonts.poppins(color: kTextPrimary)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: kTextPrimary),
              onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccent))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kBgCard.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kAccent.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.terminal, color: kAccent, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('SSH Server',
                              style: GoogleFonts.poppins(
                                  color: kTextPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16)),
                        ),
                        Switch(
                          value: _enabled,
                          activeColor: kAccent,
                          onChanged: (v) async {
                            await widget.client.call('set_ssh_config', args: {
                              'enabled': v,
                              'port': _port,
                              'password_auth': true,
                              'pubkey_auth': true,
                            });
                            setState(() {
                              _enabled = v;
                              _running = v;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _infoRow('Status', _running ? 'Running' : 'Stopped',
                        _running ? kGreen : kRed),
                    _infoRow('Port', '$_port', kTextPrimary),
                    _infoRow('Default User', Platform.environment['USER'] ?? 'arynox',
                        kTextPrimary),
                  ],
                ),
              ),
            );
  }

  Widget _infoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text(label,
                  style: GoogleFonts.poppins(
                      color: kTextSecondary, fontSize: 13))),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                    color: valueColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class RemoteDesktopPage extends StatefulWidget {
  final NetworkDBusClient client;
  const RemoteDesktopPage({super.key, required this.client});

  @override
  State<RemoteDesktopPage> createState() => _RemoteDesktopPageState();
}

class _RemoteDesktopPageState extends State<RemoteDesktopPage> {
  bool _vnc = false;
  bool _rdp = false;
  bool _running = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await widget.client.call('get_remote_desktop_config');
    if (mounted && res['type'] == 'Success' && res['data'] != null) {
      setState(() {
        _vnc = res['data']['vnc_enabled'] ?? false;
        _rdp = res['data']['rdp_enabled'] ?? false;
        _running = res['data']['running'] ?? false;
        _loading = false;
      });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Remote Desktop',
            style: GoogleFonts.poppins(color: kTextPrimary)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: kTextPrimary),
              onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccent))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kBgCard.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kAccent.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.monitor, color: kAccent, size: 28),
                        const SizedBox(width: 12),
                        Text('Remote Access',
                            style: GoogleFonts.poppins(
                                color: kTextPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _toggleItem('VNC Server', _vnc, (v) async {
                      await widget.client.call('set_remote_desktop_config',
                          args: {
                            'vnc_enabled': v,
                            'vnc_port': 5900,
                            'rdp_enabled': _rdp,
                            'rdp_port': 3389,
                          });
                      setState(() {
                        _vnc = v;
                        _running = _vnc || _rdp;
                      });
                    }),
                    const SizedBox(height: 12),
                    _toggleItem('RDP Server', _rdp, (v) async {
                      await widget.client.call('set_remote_desktop_config',
                          args: {
                            'vnc_enabled': _vnc,
                            'vnc_port': 5900,
                            'rdp_enabled': v,
                            'rdp_port': 3389,
                          });
                      setState(() {
                        _rdp = v;
                        _running = _vnc || _rdp;
                      });
                    }),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_running ? kGreen : kRed).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              _running
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: _running ? kGreen : kRed,
                              size: 20),
                          const SizedBox(width: 8),
                          Text(
                              _running ? 'Service Active' : 'Service Stopped',
                              style: GoogleFonts.poppins(
                                  color: _running ? kGreen : kRed,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
  }

  Widget _toggleItem(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kBgDark.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(color: kTextPrimary, fontSize: 14)),
          Switch(
            value: value,
            activeColor: kAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class PrintersPage extends StatefulWidget {
  final NetworkDBusClient client;
  const PrintersPage({super.key, required this.client});

  @override
  State<PrintersPage> createState() => _PrintersPageState();
}

class _PrintersPageState extends State<PrintersPage> {
  List<Printer> _printers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final printers = await widget.client.discoverPrinters();
    if (mounted) setState(() {
      _printers = printers;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Printers',
            style: GoogleFonts.poppins(color: kTextPrimary)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: kTextPrimary),
              onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccent))
          : _printers.isEmpty
              ? Center(
                  child: Text('No printers found',
                      style: GoogleFonts.poppins(color: kTextSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _printers.length,
                  itemBuilder: (ctx, i) {
                    final p = _printers[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kBgCard.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kAccent.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.print, color: kAccent, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(p.name,
                                    style: GoogleFonts.poppins(
                                        color: kTextPrimary,
                                        fontWeight: FontWeight.w600)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: p.status == 'idle'
                                      ? kGreen.withOpacity(0.15)
                                      : kOrange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(p.status,
                                    style: GoogleFonts.poppins(
                                        color: p.status == 'idle'
                                            ? kGreen
                                            : kOrange,
                                        fontSize: 11)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(p.model,
                              style: GoogleFonts.poppins(
                                  color: kTextSecondary, fontSize: 12)),
                          Text(p.location,
                              style: GoogleFonts.poppins(
                                  color: kTextSecondary, fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home
// ---------------------------------------------------------------------------

class HomePage extends StatefulWidget {
  final NetworkDBusClient client;
  const HomePage({super.key, required this.client});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  EthernetConfig? _eth;
  bool _loadingEth = true;

  @override
  void initState() {
    super.initState();
    _loadEth();
  }

  Future<void> _loadEth() async {
    setState(() => _loadingEth = true);
    final eth = await widget.client.getEthernetStatus();
    if (mounted) setState(() {
      _eth = eth;
      _loadingEth = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Arynox Network',
            style: GoogleFonts.poppins(
                color: kTextPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerCard(),
            const SizedBox(height: 20),
            _navGrid(),
            const SizedBox(height: 20),
            if (_loadingEth)
              const Center(child: CircularProgressIndicator(color: kAccent))
            else if (_eth != null)
              _ethernetCard(),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kAccent.withOpacity(0.3), kBgCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.wifi, color: kAccent, size: 32),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Network Manager',
                      style: GoogleFonts.poppins(
                          color: kTextPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('All services managed',
                      style: GoogleFonts.poppins(
                          color: kTextSecondary, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statusBadge('WiFi', Icons.wifi, kGreen),
              const SizedBox(width: 12),
              _statusBadge('Ethernet', Icons.lan,
                  _eth?.linkUp == true ? kGreen : kRed),
              const SizedBox(width: 12),
              _statusBadge('Bluetooth', Icons.bluetooth, kGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _navGrid() {
    final items = [
      _NavItem('WiFi', Icons.wifi, const Color(0xFF00D68F)),
      _NavItem('Bluetooth', Icons.bluetooth, const Color(0xFF3498DB)),
      _NavItem('VPN', Icons.vpn_lock, const Color(0xFF9B59B6)),
      _NavItem('LAN', Icons.lan, const Color(0xFF2ECC71)),
      _NavItem('Firewall', Icons.shield, const Color(0xFFE74C3C)),
      _NavItem('Proxy', Icons.dns, const Color(0xFFF39C12)),
      _NavItem('SSH', Icons.terminal, const Color(0xFF1ABC9C)),
      _NavItem('Remote Desktop', Icons.monitor, const Color(0xFFE67E22)),
      _NavItem('Printers', Icons.print, const Color(0xFF95A5A6)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        return GestureDetector(
          onTap: () {
            final pages = {
              'WiFi': WifiPage(client: widget.client),
              'Bluetooth': BluetoothPage(client: widget.client),
              'VPN': VPNPage(client: widget.client),
              'LAN': LANPage(client: widget.client),
              'Firewall': FirewallPage(client: widget.client),
              'Proxy': ProxyPage(client: widget.client),
              'SSH': SSHPage(client: widget.client),
              'Remote Desktop': RemoteDesktopPage(client: widget.client),
              'Printers': PrintersPage(client: widget.client),
            };
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => pages[item.label] ??
                      Scaffold(
                        backgroundColor: kBgDark,
                        appBar: AppBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          title: Text(item.label,
                              style: GoogleFonts.poppins(color: kTextPrimary)),
                        ),
                        body: Center(
                          child: Text('Coming soon',
                              style: GoogleFonts.poppins(color: kTextSecondary)),
                        ),
                      )),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: kBgCard.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: item.color.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(item.icon, color: item.color, size: 28),
                ),
                const SizedBox(height: 8),
                Text(item.label,
                    style: GoogleFonts.poppins(
                        color: kTextPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _ethernetCard() {
    final e = _eth!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kBgCard.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kAccent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lan, color: kAccent, size: 28),
              const SizedBox(width: 12),
              Text('Ethernet',
                  style: GoogleFonts.poppins(
                      color: kTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (e.linkUp ? kGreen : kRed).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                    e.linkUp ? 'Connected ${e.speedMbps}Mbps' : 'Disconnected',
                    style: GoogleFonts.poppins(
                        color: e.linkUp ? kGreen : kRed, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ethRow('Interface', e.interface),
          _ethRow('MAC', e.mac),
          _ethRow('IPv4', e.ipv4 ?? 'N/A'),
          _ethRow('Gateway', e.gateway ?? 'N/A'),
          if (e.dns.isNotEmpty) _ethRow('DNS', e.dns.join(', ')),
        ],
      ),
    );
  }

  Widget _ethRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: GoogleFonts.poppins(
                      color: kTextSecondary, fontSize: 12))),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                    color: kTextPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

class _NavItem {
  final String label;
  final IconData icon;
  final Color color;
  const _NavItem(this.label, this.icon, this.color);
}

void main() {
  runApp(const ArynoxNetworkApp());
}

class ArynoxNetworkApp extends StatelessWidget {
  const ArynoxNetworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arynox Network Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kBgDark,
        colorScheme: const ColorScheme.dark(
          primary: kAccent,
          secondary: kAccent,
          surface: kBgDark,
        ),
      ),
      home: HomePage(client: NetworkDBusClient()),
    );
  }
}
