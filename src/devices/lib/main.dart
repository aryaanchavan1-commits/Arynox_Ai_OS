import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dbus/dbus.dart';
import 'package:provider/provider.dart';
import 'package:flutter_glassmorphism/flutter_glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kBgPrimary = Color(0xFF0F1023);
const Color kBgSecondary = Color(0xFF1A1B2E);
const Color kAccent = Color(0xFF6C5CE7);
const Color kAccentLight = Color(0xFFA29BFE);
const Color kSuccess = Color(0xFF00B894);
const Color kWarning = Color(0xFFFDCB6E);
const Color kError = Color(0xFFE17055);
const Color kTextPrimary = Color(0xFFF5F6FA);
const Color kTextSecondary = Color(0xFFB2B3C6);

const String kDbusName = 'org.arynox.DeviceManager';
const String kDbusPath = '/org/arynox/DeviceManager';
const String kDbusInterface = 'org.arynox.DeviceManager';

class Device {
  final String id;
  final String name;
  final String deviceType;
  final String vendor;
  final String model;
  final String driver;
  final String status;
  final Map<String, String> properties;

  Device({
    required this.id,
    required this.name,
    required this.deviceType,
    required this.vendor,
    required this.model,
    required this.driver,
    required this.status,
    required this.properties,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      deviceType: json['device_type'] as String? ?? 'unknown',
      vendor: json['vendor'] as String? ?? '',
      model: json['model'] as String? ?? '',
      driver: json['driver'] as String? ?? '',
      status: json['status'] as String? ?? 'disconnected',
      properties: Map<String, String>.from(json['properties'] as Map? ?? {}),
    );
  }

  bool get isConnected => status == 'connected';

  IconData get icon {
    switch (deviceType) {
      case 'usb_drive':
      case 'external_ssd_hdd':
      case 'storage_device':
      case 'storage_partition':
        return Icons.storage;
      case 'bluetooth':
        return Icons.bluetooth;
      case 'wifi':
      case 'wwan':
        return Icons.wifi;
      case 'ethernet':
      case 'network_adapter':
        return Icons.lan;
      case 'printer':
        return Icons.print;
      case 'barcode_scanner':
        return Icons.qr_code_scanner;
      case 'keyboard':
        return Icons.keyboard;
      case 'mouse':
        return Icons.mouse;
      case 'touchscreen':
      case 'touchpad':
        return Icons.touch_app;
      case 'drawing_tablet':
        return Icons.draw;
      case 'game_controller':
        return Icons.videogame_asset;
      case 'hdmi_display':
      case 'display':
        return Icons.monitor;
      case 'projector':
        return Icons.projector;
      case 'docking_station':
        return Icons.dock;
      case 'webcam':
      case 'camera':
      case 'video_device':
        return Icons.videocam;
      case 'microphone':
        return Icons.mic;
      case 'speaker':
      case 'headphones':
      case 'audio_device':
        return Icons.headphones;
      case 'fingerprint_reader':
        return Icons.fingerprint;
      case 'nfc_reader':
        return Icons.nfc;
      case 'serial_device':
        return Icons.usb;
      case 'hid_device':
      case 'input_device':
        return Icons.input;
      case 'usb_device':
      case 'usb_interface':
        return Icons.usb;
      case 'smart_card':
        return Icons.credit_card;
      case 'sensor':
        return Icons.sensors;
      case 'thermal_device':
        return Icons.thermostat;
      case 'power_supply':
        return Icons.power;
      case 'pci_device':
        return Icons.memory;
      case 'hub':
        return Icons.usb;
      default:
        return Icons.devices_other;
    }
  }

  String get typeLabel {
    switch (deviceType) {
      case 'usb_drive':
        return 'USB Drive';
      case 'external_ssd_hdd':
        return 'External SSD/HDD';
      case 'storage_device':
      case 'storage_partition':
        return 'Storage';
      case 'bluetooth':
        return 'Bluetooth';
      case 'wifi':
        return 'WiFi';
      case 'wwan':
        return 'WWAN';
      case 'ethernet':
      case 'network_adapter':
        return 'Ethernet';
      case 'printer':
        return 'Printer';
      case 'barcode_scanner':
        return 'Barcode Scanner';
      case 'thermal_device':
        return 'Thermal Device';
      case 'keyboard':
        return 'Keyboard';
      case 'mouse':
        return 'Mouse';
      case 'touchscreen':
        return 'Touchscreen';
      case 'touchpad':
        return 'Touchpad';
      case 'drawing_tablet':
        return 'Drawing Tablet';
      case 'game_controller':
        return 'Game Controller';
      case 'hdmi_display':
      case 'display':
        return 'Display';
      case 'projector':
        return 'Projector';
      case 'docking_station':
        return 'Docking Station';
      case 'webcam':
      case 'camera':
      case 'video_device':
        return 'Camera';
      case 'microphone':
        return 'Microphone';
      case 'speaker':
        return 'Speaker';
      case 'headphones':
        return 'Headphones';
      case 'audio_device':
        return 'Audio Device';
      case 'fingerprint_reader':
        return 'Fingerprint Reader';
      case 'nfc_reader':
        return 'NFC Reader';
      case 'serial_device':
        return 'Serial Device';
      case 'hid_device':
      case 'input_device':
        return 'HID Device';
      case 'usb_device':
      case 'usb_interface':
        return 'USB Device';
      case 'smart_card':
        return 'Smart Card Reader';
      case 'sensor':
        return 'Sensor';
      case 'power_supply':
        return 'Power Supply';
      case 'pci_device':
        return 'PCI Device';
      case 'hub':
        return 'USB Hub';
      case 'misc_device':
        return 'Misc Device';
      case 'scsi_device':
        return 'SCSI Device';
      case 'platform_device':
        return 'Platform Device';
      case 'led_device':
        return 'LED';
      case 'regulator':
        return 'Regulator';
      case 'wakeup_source':
        return 'Wakeup Source';
      case 'remoteproc_device':
        return 'Remote Processor';
      case 'rpmsg_device':
        return 'RPMsg Device';
      case 'tee_device':
        return 'TEE Device';
      case 'mei_device':
        return 'MEI Device';
      case 'dma_device':
        return 'DMA';
      case 'memstick_device':
        return 'Memory Stick';
      case 'mmc_device':
        return 'MMC Device';
      case 'firewire_device':
        return 'FireWire';
      case 'drm_minor':
        return 'Display';
      default:
        return 'Unknown Device';
    }
  }
}

class DeviceCategory {
  final String name;
  final IconData icon;
  final List<Device> devices;

  DeviceCategory({
    required this.name,
    required this.icon,
    required this.devices,
  });
}

class DeviceManagerService extends ChangeNotifier {
  List<Device> _devices = [];
  bool _connected = false;
  StreamSubscription? _subscription;

  List<Device> get devices => _devices;
  bool get connected => _connected;

  List<DeviceCategory> get categorizedDevices {
    final map = <String, List<Device>>{};
    for (final device in _devices) {
      map.putIfAbsent(device.typeLabel, () => []).add(device);
    }
    final categories = <String, IconData>{
      'USB Drive': Icons.storage,
      'External SSD/HDD': Icons.storage,
      'Storage': Icons.storage,
      'Keyboard': Icons.keyboard,
      'Mouse': Icons.mouse,
      'Touchscreen': Icons.touch_app,
      'Touchpad': Icons.touch_app,
      'Drawing Tablet': Icons.draw,
      'Game Controller': Icons.videogame_asset,
      'Display': Icons.monitor,
      'Projector': Icons.projector,
      'Docking Station': Icons.dock,
      'Camera': Icons.videocam,
      'Webcam': Icons.videocam,
      'Microphone': Icons.mic,
      'Speaker': Icons.speaker,
      'Headphones': Icons.headphones,
      'Audio Device': Icons.headphones,
      'Printer': Icons.print,
      'Barcode Scanner': Icons.qr_code_scanner,
      'Fingerprint Reader': Icons.fingerprint,
      'NFC Reader': Icons.nfc,
      'Bluetooth': Icons.bluetooth,
      'WiFi': Icons.wifi,
      'WWAN': Icons.wifi,
      'Ethernet': Icons.lan,
      'Network Adapter': Icons.lan,
      'Serial Device': Icons.usb,
      'USB Device': Icons.usb,
      'USB Hub': Icons.usb,
      'HID Device': Icons.input,
      'Smart Card Reader': Icons.credit_card,
      'Sensor': Icons.sensors,
      'Thermal Device': Icons.thermostat,
      'Power Supply': Icons.power,
      'PCI Device': Icons.memory,
      'SCSI Device': Icons.storage,
      'Platform Device': Icons.developer_board,
      'LED': Icons.lightbulb_outline,
      'Regulator': Icons.settings,
      'Wakeup Source': Icons.power_settings_new,
      'Remote Processor': Icons.memory,
      'RPMsg Device': Icons.memory,
      'TEE Device': Icons.security,
      'MEI Device': Icons.developer_board,
      'DMA': Icons.memory,
      'Memory Stick': Icons.sd_storage,
      'MMC Device': Icons.sd_storage,
      'FireWire': Icons.cable,
      'Thermal Device': Icons.thermostat,
      'Misc Device': Icons.devices_other,
      'Unknown Device': Icons.devices_other,
    };

    return map.entries.map((e) {
      return DeviceCategory(
        name: e.key,
        icon: categories[e.key] ?? Icons.devices_other,
        devices: e.value,
      );
    }).toList()
      ..sort((a, b) => a.devices.length.compareTo(b.devices.length) * -1);
  }

  Future<void> connect() async {
    try {
      final client = DBusClient.session();
      final object = DBusRemoteObject(
        client,
        name: kDbusName,
        path: DBusObjectPath(kDbusPath),
      );

      final result = await object.callMethod(
        DBusInterface(kDbusInterface),
        DBusMember('ListDevices'),
        DBusMethodCallParameters(),
      );

      final jsonStr = result.returnValues.first.asString();
      final list = jsonDecode(jsonStr) as List;
      _devices = list.map((e) => Device.fromJson(e as Map<String, dynamic>)).toList();
      _connected = true;
      notifyListeners();

      _subscription = client.registerSignalHandler(
        DBusInterface(kDbusInterface),
        DBusMember('DeviceEvent'),
        DBusObjectPath(kDbusPath),
        (signal) {
          if (signal.values.isNotEmpty) {
            final signalJson = signal.values.first.asString();
            final event = jsonDecode(signalJson) as Map<String, dynamic>;
            final action = event['action'] as String?;
            final deviceData = event['device'] as Map<String, dynamic>?;
            if (deviceData != null) {
              final device = Device.fromJson(deviceData);
              if (action == 'add' || action == 'bind') {
                _devices.removeWhere((d) => d.id == device.id);
                _devices.add(device);
              } else if (action == 'remove' || action == 'unbind') {
                _devices.removeWhere((d) => d.id == device.id);
              } else {
                _devices.removeWhere((d) => d.id == device.id);
                _devices.add(device);
              }
              notifyListeners();
            }
          }
        },
      );
    } catch (e) {
      _connected = false;
      notifyListeners();
    }
  }

  Future<String?> getDeviceInfo(String id) async {
    try {
      final client = DBusClient.session();
      final object = DBusRemoteObject(
        client,
        name: kDbusName,
        path: DBusObjectPath(kDbusPath),
      );

      final result = await object.callMethod(
        DBusInterface(kDbusInterface),
        DBusMember('GetDeviceInfo'),
        DBusMethodCallParameters()..addString(id),
      );

      return result.returnValues.first.asString();
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.width,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: width ?? double.infinity,
      height: height ?? 120,
      borderRadius: 16,
      blur: 20,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          kBgSecondary.withValues(alpha: 0.4),
          kBgSecondary.withValues(alpha: 0.1),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.05),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => DeviceManagerService()..connect(),
      child: const ArynoxDeviceManagerApp(),
    ),
  );
}

class ArynoxDeviceManagerApp extends StatelessWidget {
  const ArynoxDeviceManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arynox Device Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBgPrimary,
        colorScheme: ColorScheme.dark(
          primary: kAccent,
          secondary: kAccentLight,
          surface: kBgSecondary,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ).copyWith(
          bodySmall: GoogleFonts.poppins(color: kTextSecondary, fontSize: 12),
          bodyMedium: GoogleFonts.poppins(color: kTextPrimary, fontSize: 14),
          bodyLarge: GoogleFonts.poppins(color: kTextPrimary, fontSize: 16),
          titleSmall: GoogleFonts.poppins(color: kTextSecondary, fontSize: 13, fontWeight: FontWeight.w500),
          titleMedium: GoogleFonts.poppins(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          titleLarge: GoogleFonts.poppins(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.w700),
          headlineMedium: GoogleFonts.poppins(color: kTextPrimary, fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
      home: const DeviceManagerHome(),
    );
  }
}

class DeviceManagerHome extends StatelessWidget {
  const DeviceManagerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildDeviceList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kBgSecondary.withValues(alpha: 0.8),
            kBgPrimary,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.devices_rounded, color: kAccent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Manager',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Consumer<DeviceManagerService>(
                  builder: (_, service, __) => Text(
                    '${service.devices.length} device${service.devices.length == 1 ? '' : 's'} detected',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Consumer<DeviceManagerService>(
            builder: (_, service, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: service.connected ? kSuccess.withValues(alpha: 0.15) : kError.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: service.connected ? kSuccess : kError,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    service.connected ? 'Live' : 'Offline',
                    style: TextStyle(
                      color: service.connected ? kSuccess : kError,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context) {
    return Consumer<DeviceManagerService>(
      builder: (_, service, __) {
        if (!service.connected && service.devices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.usb_rounded, size: 64, color: kTextSecondary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('Device Manager Offline', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Could not connect to the device daemon', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 24),
                GlassmorphicContainer(
                  width: 160,
                  height: 48,
                  borderRadius: 12,
                  blur: 20,
                  alignment: Alignment.center,
                  border: 1,
                  linearGradient: LinearGradient(
                    colors: [kAccent.withValues(alpha: 0.3), kAccent.withValues(alpha: 0.1)],
                  ),
                  borderGradient: LinearGradient(
                    colors: [kAccent.withValues(alpha: 0.5), kAccentLight.withValues(alpha: 0.2)],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => service.connect(),
                      child: const Center(
                        child: Text('Retry', style: TextStyle(color: kAccentLight, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (service.devices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.devices_rounded, size: 64, color: kTextSecondary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('No Devices Found', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Connect a device to get started', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: service.categorizedDevices.length,
          itemBuilder: (_, i) => _DeviceCategoryCard(category: service.categorizedDevices[i]),
        );
      },
    );
  }
}

class _DeviceCategoryCard extends StatelessWidget {
  final DeviceCategory category;

  const _DeviceCategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
          child: Row(
            children: [
              Icon(category.icon, size: 16, color: kAccentLight),
              const SizedBox(width: 8),
              Text(category.name, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kBgSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${category.devices.length}', style: TextStyle(fontSize: 11, color: kTextSecondary)),
              ),
            ],
          ),
        ),
        ...category.devices.map((d) => _DeviceTile(device: d)),
      ],
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final Device device;

  const _DeviceTile({required this.device});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: device.isConnected
                    ? kAccent.withValues(alpha: 0.12)
                    : kTextSecondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                device.icon,
                color: device.isConnected ? kAccent : kTextSecondary.withValues(alpha: 0.5),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (device.vendor.isNotEmpty) ...[
                        Text(device.vendor, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(width: 8),
                        Container(width: 3, height: 3, decoration: BoxDecoration(color: kTextSecondary, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        device.driver.isNotEmpty ? device.driver : 'No driver',
                        style: TextStyle(
                          fontSize: 11,
                          color: device.driver.isNotEmpty ? kAccentLight : kTextSecondary.withValues(alpha: 0.5),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _DeviceActions(device: device),
          ],
        ),
      ),
    );
  }
}

class _DeviceActions extends StatelessWidget {
  final Device device;

  const _DeviceActions({required this.device});

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];

    if (device.deviceType == 'usb_drive' ||
        device.deviceType == 'external_ssd_hdd' ||
        device.deviceType == 'storage_device') {
      actions.add(_ActionButton(
        icon: Icons.eject,
        color: kWarning,
        tooltip: 'Eject',
        onTap: () => _ejectDevice(device),
      ));
    }

    if (device.deviceType == 'bluetooth') {
      actions.add(_ActionButton(
        icon: device.isConnected ? Icons.bluetooth_disabled : Icons.bluetooth,
        color: device.isConnected ? kError : kSuccess,
        tooltip: device.isConnected ? 'Disconnect' : 'Connect',
        onTap: () => _toggleBluetooth(device),
      ));
    }

    actions.add(_ActionButton(
      icon: Icons.info_outline,
      color: kAccentLight,
      tooltip: 'Details',
      onTap: () => _showDetails(context, device),
    ));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions,
    );
  }

  void _ejectDevice(Device device) {
    ScaffoldMessenger.of(_getContext()).showSnackBar(
      SnackBar(
        content: Text('Ejecting ${device.name}...'),
        backgroundColor: kBgSecondary,
      ),
    );
  }

  void _toggleBluetooth(Device device) {
    ScaffoldMessenger.of(_getContext()).showSnackBar(
      SnackBar(
        content: Text('${device.isConnected ? "Disconnecting" : "Connecting"} ${device.name}...'),
        backgroundColor: kBgSecondary,
      ),
    );
  }

  BuildContext _getContext() {
    return _contextKey.currentContext!;
  }

  static final GlobalKey _contextKey = GlobalKey();

  void _showDetails(BuildContext outerContext, Device device) {
    showModalBottomSheet(
      context: outerContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _DeviceDetailsSheet(device: device),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

class _DeviceDetailsSheet extends StatelessWidget {
  final Device device;

  const _DeviceDetailsSheet({required this.device});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kBgSecondary.withValues(alpha: 0.95),
              kBgPrimary.withValues(alpha: 0.98),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kTextSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: device.isConnected
                        ? kAccent.withValues(alpha: 0.15)
                        : kTextSecondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    device.icon,
                    color: device.isConnected ? kAccent : kTextSecondary.withValues(alpha: 0.5),
                    size: 36,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        device.typeLabel,
                        style: TextStyle(color: kAccentLight, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: device.isConnected
                        ? kSuccess.withValues(alpha: 0.15)
                        : kError.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: device.isConnected ? kSuccess : kError,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        device.isConnected ? 'Connected' : 'Disconnected',
                        style: TextStyle(
                          color: device.isConnected ? kSuccess : kError,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _DetailRow(label: 'Device ID', value: device.id),
            if (device.vendor.isNotEmpty) _DetailRow(label: 'Vendor', value: device.vendor),
            if (device.model.isNotEmpty) _DetailRow(label: 'Model', value: device.model),
            _DetailRow(label: 'Driver', value: device.driver.isNotEmpty ? device.driver : 'No driver'),
            if (device.properties.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Properties', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...device.properties.entries.map((e) => _DetailRow(label: e.key, value: e.value)),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: kTextSecondary, fontSize: 13), overflow: TextOverflow.ellipsis),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: TextStyle(color: kTextPrimary, fontSize: 13, fontFamily: 'monospace'),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
