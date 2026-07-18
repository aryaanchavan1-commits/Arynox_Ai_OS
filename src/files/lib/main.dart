import 'package:flutter/material.dart';
import 'dart:io';

void main() {
  runApp(const ArynoxFilesApp());
}

class ArynoxFilesApp extends StatelessWidget {
  const ArynoxFilesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arynox File Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF0F1023),
      ),
      home: const FileManagerPage(),
    );
  }
}

class FileManagerPage extends StatefulWidget {
  const FileManagerPage({super.key});

  @override
  State<FileManagerPage> createState() => _FileManagerPageState();
}

class _FileManagerPageState extends State<FileManagerPage> {
  String _currentPath = '/';
  List<FileSystemEntity> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    setState(() => _loading = true);
    try {
      final dir = Directory(_currentPath);
      final list = dir.listSync();
      list.sort((a, b) {
        if (a is Directory && b is! Directory) return -1;
        if (a is! Directory && b is Directory) return 1;
        return a.path.compareTo(b.path);
      });
      setState(() {
        _entries = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDirectory,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1A1B2E),
            child: Row(
              children: [
                const Icon(Icons.folder, color: Colors.indigo, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentPath,
                    style: const TextStyle(color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _entries.length,
                    itemBuilder: (ctx, i) {
                      final entity = _entries[i];
                      final name = entity.path.split(Platform.pathSeparator).last;
                      final isDir = entity is Directory;
                      return ListTile(
                        leading: Icon(
                          isDir ? Icons.folder : Icons.insert_drive_file,
                          color: isDir ? Colors.amber : Colors.indigo,
                        ),
                        title: Text(name,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: isDir
                            ? null
                            : Text(
                                _formatSize(_getFileSize(entity)),
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                        onTap: isDir
                            ? () {
                                setState(() => _currentPath = entity.path);
                                _loadDirectory();
                              }
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  int _getFileSize(FileSystemEntity entity) {
    try {
      return File(entity.path).lengthSync();
    } catch (_) {
      return 0;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
