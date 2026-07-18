import 'package:flutter/material.dart';

void main() {
  runApp(const ArynoxSoftwareCenter());
}

class ArynoxSoftwareCenter extends StatelessWidget {
  const ArynoxSoftwareCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arynox Software Center',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF0F1023),
      ),
      home: const SoftwareCenterPage(),
    );
  }
}

class AppInfo {
  final String name;
  final String description;
  final String category;
  final double rating;
  const AppInfo(this.name, this.description, this.category, this.rating);
}

class SoftwareCenterPage extends StatelessWidget {
  const SoftwareCenterPage({super.key});

  static const List<AppInfo> apps = [
    AppInfo('Visual Studio Code', 'Code editor', 'Development', 4.7),
    AppInfo('Firefox', 'Web browser', 'Internet', 4.6),
    AppInfo('Spotify', 'Music streaming', 'Multimedia', 4.3),
    AppInfo('Blender', '3D creation suite', 'Multimedia', 4.8),
    AppInfo('LibreOffice', 'Office suite', 'Productivity', 4.4),
    AppInfo('GIMP', 'Image editor', 'Multimedia', 4.1),
    AppInfo('VLC', 'Media player', 'Multimedia', 4.8),
    AppInfo('Steam', 'Gaming platform', 'Games', 4.5),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Software Center'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search apps...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1A1B2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: apps.length,
              itemBuilder: (ctx, i) {
                final app = apps[i];
                return Card(
                  color: const Color(0xFF1A1B2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.indigo.withOpacity(0.2),
                        child: Text(
                          app.name[0],
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        app.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        app.category,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            app.rating.toString(),
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
