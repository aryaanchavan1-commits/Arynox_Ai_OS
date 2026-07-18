import 'package:flutter/material.dart';

void main() {
  runApp(const ArynoxDeviceManagerApp());
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
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF0F1023),
      ),
      home: const DeviceManagerPage(),
    );
  }
}

class Device {
  final String name;
  final String type;
  final bool connected;
  final IconData icon;

  const Device(this.name, this.type, this.connected, this.icon);
}

class DeviceManagerPage extends StatelessWidget {
  const DeviceManagerPage({super.key});

  static const List<Device> devices = [
    Device('Samsung SSD 980 PRO', 'Storage', true, Icons.storage),
    Device('Logitech MX Master 3', 'Mouse', true, Icons.mouse),
    Device('Dell U2723QE', 'Display', true, Icons.monitor),
    Device('Integrated Webcam', 'Camera', true, Icons.videocam),
    Device('Realtek Audio', 'Audio', true, Icons.headphones),
    Device('Intel Wi-Fi 6E', 'Network', true, Icons.wifi),
    Device('Bluetooth Adapter', 'Bluetooth', false, Icons.bluetooth),
    Device('USB 3.0 Hub', 'USB', true, Icons.usb),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Manager'),
        leading: const Icon(Icons.devices),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: devices.length,
        itemBuilder: (ctx, i) {
          final d = devices[i];
          return Card(
            color: const Color(0xFF1A1B2E),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: d.connected
                    ? Colors.indigo.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                child: Icon(d.icon, color: d.connected ? Colors.indigo : Colors.grey),
              ),
              title: Text(d.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(d.type, style: const TextStyle(color: Colors.white54)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: d.connected
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  d.connected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: d.connected ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
