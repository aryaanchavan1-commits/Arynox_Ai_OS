import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as acrylic;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:filesize/filesize.dart';
import 'package:collection/collection.dart';

final arynoxBackground = const Color(0xFF0F1023);
final arynoxCard = const Color(0xFF1A1B2E);
final arynoxAccent = const Color(0xFF6C5CE7);
final arynoxSurface = const Color(0xFF14152B);
final arynoxTextPrimary = const Color(0xFFE8E8F0);
final arynoxTextSecondary = const Color(0xFF8888A0);
final arynoxBorder = const Color(0xFF2A2B42);
final arynoxSuccess = const Color(0xFF00D68F);
final arynoxWarning = const Color(0xFFFFAA00);
final arynoxError = const Color(0xFFFF6B6B);

enum SortField { name, date, size, type }
enum ViewMode { grid, list }

class FileEntry {
  final String path;
  final String name;
  final String extension;
  final int size;
  final bool isDir;
  final bool isHidden;
  final bool isSymlink;
  final String created;
  final String modified;
  final String mimeType;
  final int? childCount;
  final List<String> tags;

  FileEntry({
    required this.path,
    required this.name,
    this.extension = '',
    this.size = 0,
    this.isDir = false,
    this.isHidden = false,
    this.isSymlink = false,
    this.created = '',
    this.modified = '',
    this.mimeType = '',
    this.childCount,
    this.tags = const [],
  });

  String get sizeDisplay => filesize(size);

  factory FileEntry.fromJson(Map<String, dynamic> json) {
    return FileEntry(
      path: json['path'] ?? '',
      name: json['name'] ?? '',
      extension: json['extension'] ?? '',
      size: (json['size'] ?? 0) as int,
      isDir: json['is_dir'] ?? false,
      isHidden: json['is_hidden'] ?? false,
      isSymlink: json['is_symlink'] ?? false,
      created: json['created'] ?? '',
      modified: json['modified'] ?? '',
      mimeType: json['mime_type'] ?? '',
      childCount: json['child_count'] as int?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

class RpcClient {
  Process? _process;
  final _pendingRequests = <int, Completer<Map<String, dynamic>>>{};
  int _requestId = 0;
  StreamSubscription? _subscription;

  Future<void> start() async {
    final exe = Platform.isWindows ? 'target\\debug\\arynox-files.exe' : './target/debug/arynox-files';
    _process = await Process.start(exe, []);
    _subscription = _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleResponse);
  }

  void _handleResponse(String line) {
    if (line.trim().isEmpty) return;
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      final id = json['id'] as int;
      final completer = _pendingRequests.remove(id);
      if (completer != null) {
        completer.complete(json);
      }
    } catch (e) {
      // ignore
    }
  }

  Future<Map<String, dynamic>> call(String method, Map<String, dynamic> params) async {
    final id = _requestId++;
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id] = completer;

    final request = jsonEncode({
      'id': id,
      'method': method,
      'params': params,
    });

    _process?.stdin.writeln(request);
    return completer.future.timeout(const Duration(seconds: 30));
  }

  Future<List<FileEntry>> listDirectory(String path, {bool showHidden = false, SortField sortBy = SortField.name, bool sortDesc = false}) async {
    final sortStr = sortBy.name;
    final result = await call('list_directory', {
      'path': path,
      'show_hidden': showHidden,
      'sort_by': sortStr,
      'sort_desc': sortDesc,
    });
    final entries = (result['result'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    return entries.map((e) => FileEntry.fromJson(e)).toList();
  }

  Future<List<FileEntry>> searchFiles(String query, {String? rootPath, int maxResults = 100}) async {
    final result = await call('search_files', {
      'query': query,
      if (rootPath != null) 'root_path': rootPath,
      'max_results': maxResults,
    });
    final entries = (result['result'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    return entries.map((e) => FileEntry.fromJson(e)).toList();
  }

  Future<void> deleteFile(String path) async {
    await call('delete_file', {'path': path});
  }

  Future<void> renameFile(String source, String destination) async {
    await call('rename_file', {'source': source, 'destination': destination});
  }

  Future<void> copyFile(String source, String destination) async {
    await call('copy_file', {'source': source, 'destination': destination});
  }

  Future<void> moveFile(String source, String destination) async {
    await call('move_file', {'source': source, 'destination': destination});
  }

  Future<void> createDirectory(String path) async {
    await call('create_directory', {'path': path});
  }

  void dispose() {
    _subscription?.cancel();
    _process?.kill();
  }
}

final rpcClientProvider = Provider<RpcClient>((ref) {
  final client = RpcClient();
  ref.onDispose(() => client.dispose());
  return client;
});

final currentPathProvider = StateProvider<String>((ref) => '/');
final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.list);
final sortFieldProvider = StateProvider<SortField>((ref) => SortField.name);
final sortDescProvider = StateProvider<bool>((ref) => false);
final showHiddenProvider = StateProvider<bool>((ref) => false);

final fileListProvider = FutureProvider.family<List<FileEntry>, String>((ref, path) async {
  final client = ref.read(rpcClientClientProvider);
  final sortBy = ref.read(sortFieldProvider);
  final sortDesc = ref.read(sortDescProvider);
  final showHidden = ref.read(showHiddenProvider);
  return client.listDirectory(
    path,
    showHidden: showHidden,
    sortBy: sortBy,
    sortDesc: sortDesc,
  );
});

final searchResultsProvider = FutureProvider.family<List<FileEntry>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final client = ref.read(rpcClientProvider);
  final currentPath = ref.read(currentPathProvider);
  return client.searchFiles(query, rootPath: currentPath);
});

final favoritePathsProvider = StateNotifierProvider<FavoritePathsNotifier, List<String>>((ref) {
  return FavoritePathsNotifier();
});

class FavoritePathsNotifier extends StateNotifier<List<String>> {
  FavoritePathsNotifier() : super([]);

  void toggle(String path) {
    if (state.contains(path)) {
      state = state.where((p) => p != path).toList();
    } else {
      state = [...state, path];
    }
  }

  bool isFavorite(String path) => state.contains(path);
}

final recentFilesProvider = StateNotifierProvider<RecentFilesNotifier, List<String>>((ref) {
  return RecentFilesNotifier();
});

class RecentFilesNotifier extends StateNotifier<List<String>> {
  RecentFilesNotifier() : super([]);

  void add(String path) {
    state = [path, ...state.where((p) => p != path)].take(50).toList();
  }
}

final tagsProvider = StateNotifierProvider<TagsNotifier, Map<String, Set<String>>>((ref) {
  return TagsNotifier();
});

class TagsNotifier extends StateNotifier<Map<String, Set<String>>> {
  TagsNotifier() : super({});

  void addTag(String tag, String path) {
    state = {
      ...state,
      tag: {...(state[tag] ?? {}), path},
    };
  }

  void removeTag(String tag, String path) {
    if (!state.containsKey(tag)) return;
    final updated = Set<String>.from(state[tag]!)..remove(path);
    if (updated.isEmpty) {
      state = Map.from(state)..remove(tag);
    } else {
      state = Map.from(state)..[tag] = updated;
    }
  }

  List<String> getTagsForPath(String path) {
    return state.entries
        .where((e) => e.value.contains(path))
        .map((e) => e.key)
        .toList();
  }
}

final recyclesBinProvider = StateNotifierProvider<RecycleBinNotifier, List<String>>((ref) {
  return RecycleBinNotifier();
});

class RecycleBinNotifier extends StateNotifier<List<String>> {
  RecycleBinNotifier() : super([]);

  void add(String path) => state = [...state, path];
  void restore(String path) => state = state.where((p) => p != path).toList();
  void empty() => state = [];
}

final selectedFileProvider = StateProvider<FileEntry?>((ref) => null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await acrylic.Window.initialize();
  runApp(const ProviderScope(child: ArynoxFileManagerApp()));
}

class ArynoxFileManagerApp extends StatelessWidget {
  const ArynoxFileManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arynox File Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: arynoxBackground,
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: arynoxAccent,
          secondary: arynoxAccent.withOpacity(0.7),
          surface: arynoxSurface,
          background: arynoxBackground,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: arynoxTextPrimary,
          onBackground: arynoxTextPrimary,
        ),
        cardColor: arynoxCard,
        dividerColor: arynoxBorder,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: arynoxTextPrimary, fontWeight: FontWeight.w300),
          headlineMedium: TextStyle(color: arynoxTextPrimary, fontWeight: FontWeight.w400),
          titleLarge: TextStyle(color: arynoxTextPrimary, fontWeight: FontWeight.w500),
          titleMedium: TextStyle(color: arynoxTextPrimary, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: arynoxTextPrimary),
          bodyMedium: TextStyle(color: arynoxTextSecondary),
          labelLarge: TextStyle(color: arynoxTextPrimary, fontWeight: FontWeight.w500),
        ),
        iconTheme: const IconThemeData(color: arynoxTextSecondary),
      ),
      home: const FileManagerHome(),
    );
  }
}

class FileManagerHome extends ConsumerStatefulWidget {
  const FileManagerHome({super.key});

  @override
  ConsumerState<FileManagerHome> createState() => _FileManagerHomeState();
}

class _FileManagerHomeState extends ConsumerState<FileManagerHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _NavigationSidebar(tabController: _tabController),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  searchController: _searchController,
                  isSearching: _isSearching,
                  onSearchToggle: () => setState(() => _isSearching = !_isSearching),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _FileExplorerView(
                        searchController: _searchController,
                        isSearching: _isSearching,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationSidebar extends ConsumerWidget {
  final TabController tabController;

  const _NavigationSidebar({required this.tabController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: arynoxCard.withOpacity(0.6),
        border: Border(right: BorderSide(color: arynoxBorder)),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: _blurFilter(),
          child: Column(
            children: [
              _SidebarHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    _SidebarItem(icon: Icons.home_outlined, label: 'Home', selected: true),
                    _SidebarItem(icon: Icons.history_outlined, label: 'Recent'),
                    _SidebarItem(icon: Icons.star_outline, label: 'Favorites'),
                    _SidebarItem(icon: Icons.label_outline, label: 'Tags'),
                    _SidebarItem(icon: Icons.devices_outlined, label: 'Devices'),
                    const SizedBox(height: 16),
                    _SidebarHeaderText('Cloud'),
                    _SidebarItem(icon: Icons.cloud_outlined, label: 'FTP'),
                    _SidebarItem(icon: Icons.cloud_outlined, label: 'SFTP'),
                    _SidebarItem(icon: Icons.cloud_outlined, label: 'SMB'),
                    _SidebarItem(icon: Icons.cloud_outlined, label: 'WebDAV'),
                    const SizedBox(height: 16),
                    _SidebarHeaderText('Utilities'),
                    _SidebarItem(icon: Icons.recycling_outlined, label: 'Recycle Bin'),
                    _SidebarItem(icon: Icons.history, label: 'Version History'),
                    _SidebarItem(icon: Icons.auto_fix_high_outlined, label: 'Duplicate Finder'),
                    _SidebarItem(icon: Icons.storage_outlined, label: 'Large Files'),
                    _SidebarItem(icon: Icons.archive_outlined, label: 'Archives'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageFilter _blurFilter() => ImageFilter.blur(sigmaX: 20, sigmaY: 20);
}

class _SidebarHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [arynoxAccent, arynoxAccent.withOpacity(0.6)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.folder_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Files', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: arynoxTextPrimary)),
        ],
      ),
    );
  }
}

class _SidebarHeaderText extends StatelessWidget {
  final String text;
  const _SidebarHeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: arynoxTextSecondary, letterSpacing: 1.2)),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _SidebarItem({required this.icon, required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: selected ? arynoxAccent.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 20, color: selected ? arynoxAccent : arynoxTextSecondary),
        title: Text(label, style: TextStyle(fontSize: 13, color: selected ? arynoxAccent : arynoxTextSecondary)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {},
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _TopBar extends ConsumerWidget {
  final TextEditingController searchController;
  final bool isSearching;
  final VoidCallback onSearchToggle;

  const _TopBar({
    required this.searchController,
    required this.isSearching,
    required this.onSearchToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = ref.watch(currentPathProvider);
    final paths = currentPath.split(Platform.pathSeparator).where((s) => s.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: arynoxCard.withOpacity(0.4),
        border: Border(bottom: BorderSide(color: arynoxBorder)),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            children: [
              if (isSearching)
                Expanded(
                  child: _SearchBar(controller: searchController),
                )
              else
                Expanded(
                  child: _BreadcrumbNav(paths: paths, currentPath: currentPath),
                ),
              const SizedBox(width: 8),
              _IconButton(icon: Icons.search, onPressed: onSearchToggle),
              _IconButton(icon: Icons.grid_view_outlined, onPressed: () {
                ref.read(viewModeProvider.notifier).state = ViewMode.grid;
              }),
              _IconButton(icon: Icons.list_outlined, onPressed: () {
                ref.read(viewModeProvider.notifier).state = ViewMode.list;
              }),
              _SortDropdown(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreadcrumbNav extends ConsumerWidget {
  final List<String> paths;
  final String currentPath;

  const _BreadcrumbNav({required this.paths, required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ref.read(currentPathProvider.notifier).state = '/',
            child: const Icon(Icons.home_outlined, size: 18, color: arynoxTextSecondary),
          ),
          const Icon(Icons.chevron_right, size: 16, color: arynoxTextSecondary),
          ...paths.asMap().entries.map((entry) {
            final index = entry.key;
            final part = entry.value;
            final fullPath = Platform.pathSeparator + paths.sublist(0, index + 1).join(Platform.pathSeparator);
            final isLast = index == paths.length - 1;
            return Row(
              children: [
                GestureDetector(
                  onTap: () => ref.read(currentPathProvider.notifier).state = fullPath,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLast ? arynoxAccent.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      part,
                      style: TextStyle(
                        fontSize: 13,
                        color: isLast ? arynoxAccent : arynoxTextSecondary,
                        fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                if (!isLast) const Icon(Icons.chevron_right, size: 16, color: arynoxTextSecondary),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SearchBar extends ConsumerStatefulWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: arynoxSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: arynoxBorder),
      ),
      child: TextField(
        controller: widget.controller,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: arynoxTextPrimary, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Search files with AI...',
          hintStyle: TextStyle(color: arynoxTextSecondary),
          prefixIcon: Icon(Icons.search, color: arynoxAccent, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}

final searchQueryProvider = StateProvider<String>((ref) => '');

class _SortDropdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortBy = ref.watch(sortFieldProvider);
    return PopupMenuButton<SortField>(
      icon: const Icon(Icons.sort_outlined, color: arynoxTextSecondary, size: 20),
      color: arynoxCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: arynoxBorder)),
      onSelected: (field) {
        if (field == sortBy) {
          ref.read(sortDescProvider.notifier).state = !ref.read(sortDescProvider);
        } else {
          ref.read(sortFieldProvider.notifier).state = field;
          ref.read(sortDescProvider.notifier).state = false;
        }
      },
      itemBuilder: (context) => SortField.values.map((field) {
        final isSelected = field == sortBy;
        return PopupMenuItem(
          value: field,
          child: Row(
            children: [
              Icon(
                isSelected
                    ? (ref.read(sortDescProvider) ? Icons.arrow_downward : Icons.arrow_upward)
                    : Icons.sort,
                size: 16,
                color: isSelected ? arynoxAccent : arynoxTextSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                field.name[0].toUpperCase() + field.name.substring(1),
                style: TextStyle(color: isSelected ? arynoxAccent : arynoxTextPrimary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _IconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: arynoxSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: arynoxBorder),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: arynoxTextSecondary),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }
}

class _FileExplorerView extends ConsumerWidget {
  final TextEditingController searchController;
  final bool isSearching;

  const _FileExplorerView({
    required this.searchController,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = ref.watch(currentPathProvider);
    final query = ref.watch(searchQueryProvider);
    final showSearch = isSearching && query.isNotEmpty;

    return Row(
      children: [
        SizedBox(
          width: 260,
          child: _DirectoryTree(currentPath: currentPath),
        ),
        Container(width: 1, color: arynoxBorder),
        Expanded(
          child: showSearch
              ? _SearchResultsView(query: query)
              : _FileListView(currentPath: currentPath),
        ),
      ],
    );
  }
}

class _DirectoryTree extends ConsumerWidget {
  final String currentPath;

  const _DirectoryTree({required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: arynoxSurface.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('DIRECTORIES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: arynoxTextSecondary, letterSpacing: 1.2)),
          ),
          Expanded(
            child: FutureBuilder<List<FileEntry>>(
              future: ref.read(rpcClientProvider).listDirectory(
                currentPath.startsWith('/') ? currentPath : '/',
                showHidden: false,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: arynoxAccent));
                final dirs = snapshot.data!.where((e) => e.isDir).toList();
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: dirs.length,
                  itemBuilder: (context, index) {
                    final dir = dirs[index];
                    final isSelected = dir.path == currentPath;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? arynoxAccent.withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          dir.name.startsWith('.') ? Icons.folder_special_outlined : Icons.folder_outlined,
                          size: 18,
                          color: isSelected ? arynoxAccent : arynoxWarning,
                        ),
                        title: Text(
                          dir.name,
                          style: TextStyle(fontSize: 13, color: isSelected ? arynoxAccent : arynoxTextPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: dir.childCount != null
                            ? Text('${dir.childCount} items', style: const TextStyle(fontSize: 11, color: arynoxTextSecondary))
                            : null,
                        onTap: () => ref.read(currentPathProvider.notifier).state = dir.path,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FileListView extends ConsumerWidget {
  final String currentPath;

  const _FileListView({required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(viewModeProvider);
    final entriesAsync = ref.watch(fileListProvider(currentPath));

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: arynoxAccent)),
      error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: arynoxError))),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_open_outlined, size: 64, color: arynoxTextSecondary.withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text('This folder is empty', style: TextStyle(color: arynoxTextSecondary, fontSize: 16)),
              ],
            ),
          );
        }

        return viewMode == ViewMode.grid
            ? _GridView(entries: entries, currentPath: currentPath)
            : _ListView(entries: entries, currentPath: currentPath);
      },
    );
  }
}

class _GridView extends ConsumerWidget {
  final List<FileEntry> entries;
  final String currentPath;

  const _GridView({required this.entries, required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _FileGridTile(entry: entry)
            .animate()
            .fadeIn(duration: 300.ms, delay: (index * 30).ms)
            .slideX(begin: 0.1, end: 0, duration: 300.ms)
            .then();
      },
    );
  }
}

class _ListView extends ConsumerWidget {
  final List<FileEntry> entries;
  final String currentPath;

  const _ListView({required this.entries, required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isSelected = ref.watch(selectedFileProvider)?.path == entry.path;
        return _FileListTile(entry: entry, isSelected: isSelected)
            .animate()
            .fadeIn(duration: 300.ms, delay: (index * 20).ms)
            .slideX(begin: 0.05, end: 0, duration: 300.ms)
            .then();
      },
    );
  }
}

class _FileGridTile extends ConsumerWidget {
  final FileEntry entry;

  const _FileGridTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(selectedFileProvider.notifier).state = entry,
      onDoubleTap: () {
        if (entry.isDir) {
          ref.read(currentPathProvider.notifier).state = entry.path;
          ref.read(recentFilesProvider.notifier).add(entry.path);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: arynoxCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: arynoxBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FileIcon(entry: entry, size: 36),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    entry.name,
                    style: const TextStyle(fontSize: 12, color: arynoxTextPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.isDir ? 'Folder' : entry.sizeDisplay,
                  style: const TextStyle(fontSize: 10, color: arynoxTextSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FileListTile extends ConsumerWidget {
  final FileEntry entry;
  final bool isSelected;

  const _FileListTile({required this.entry, required this.isSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: isSelected ? arynoxAccent.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: _FileIcon(entry: entry),
        title: Text(
          entry.name,
          style: TextStyle(fontSize: 14, color: arynoxTextPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            if (!entry.isDir) ...[
              Text(entry.sizeDisplay, style: const TextStyle(fontSize: 12, color: arynoxTextSecondary)),
              const Text('  ·  ', style: TextStyle(color: arynoxTextSecondary)),
            ],
            Text(
              entry.modified.isNotEmpty ? entry.modified.substring(0, 10) : '',
              style: const TextStyle(fontSize: 12, color: arynoxTextSecondary),
            ),
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(width: 8),
              ...entry.tags.map((tag) => Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: arynoxAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag, style: const TextStyle(fontSize: 10, color: arynoxAccent)),
              )),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QuickActionButton(
              icon: ref.watch(favoritePathsProvider).contains(entry.path)
                  ? Icons.star
                  : Icons.star_outline,
              color: arynoxWarning,
              onPressed: () => ref.read(favoritePathsProvider.notifier).toggle(entry.path),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: arynoxTextSecondary, size: 18),
              color: arynoxCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: arynoxBorder)),
              onSelected: (action) => _handleFileAction(context, ref, action),
              itemBuilder: (context) => [
                if (!entry.isDir) const PopupMenuItem(value: 'preview', child: Text('Preview')),
                const PopupMenuItem(value: 'rename', child: Text('Rename')),
                const PopupMenuItem(value: 'copy', child: Text('Copy')),
                const PopupMenuItem(value: 'move', child: Text('Move')),
                const PopupMenuItem(value: 'delete', child: Text('Move to Recycle Bin', style: TextStyle(color: arynoxError))),
                const PopupMenuItem(value: 'delete_perm', child: Text('Delete Permanently', style: TextStyle(color: arynoxError))),
                const PopupMenuItem(value: 'add_tag', child: Text('Add Tag')),
              ],
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () => ref.read(selectedFileProvider.notifier).state = entry,
        onLongPress: () => _showPreviewPanel(context, ref),
      ),
    );
  }

  void _handleFileAction(BuildContext context, WidgetRef ref, String action) async {
    final client = ref.read(rpcClientProvider);
    try {
      switch (action) {
        case 'rename':
          _showRenameDialog(context, ref);
        case 'copy':
          await client.copyFile(entry.path, '${entry.path}.copy');
        case 'move':
          _showMoveDialog(context, ref);
        case 'delete':
          await client.call('move_to_recycle_bin', {'path': entry.path});
          ref.read(recycleBinProvider.notifier).add(entry.path);
        case 'delete_perm':
          await client.deleteFile(entry.path);
        case 'add_tag':
          _showAddTagDialog(context, ref);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: arynoxError));
      }
    }
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: entry.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: arynoxCard,
        title: const Text('Rename', style: TextStyle(color: arynoxTextPrimary)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: arynoxTextPrimary),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: arynoxSurface,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final dir = p.dirname(entry.path);
              final newPath = p.join(dir, controller.text);
              await ref.read(rpcClientProvider).renameFile(entry.path, newPath);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Rename', style: TextStyle(color: arynoxAccent)),
          ),
        ],
      ),
    );
  }

  void _showMoveDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: arynoxCard,
        title: const Text('Move to...', style: TextStyle(color: arynoxTextPrimary)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: arynoxTextPrimary),
          decoration: InputDecoration(
            hintText: 'Enter destination path',
            hintStyle: const TextStyle(color: arynoxTextSecondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: arynoxSurface,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(rpcClientProvider).moveFile(entry.path, controller.text);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Move', style: TextStyle(color: arynoxAccent)),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: arynoxCard,
        title: const Text('Add Tag', style: TextStyle(color: arynoxTextPrimary)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: arynoxTextPrimary),
          decoration: InputDecoration(
            hintText: 'Tag name',
            hintStyle: const TextStyle(color: arynoxTextSecondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: arynoxSurface,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(tagsProvider.notifier).addTag(controller.text, entry.path);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add', style: TextStyle(color: arynoxAccent)),
          ),
        ],
      ),
    );
  }

  void _showPreviewPanel(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilePreviewPanel(entry: entry),
    );
  }
}

class _FilePreviewPanel extends StatelessWidget {
  final FileEntry entry;
  const _FilePreviewPanel({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: arynoxCard.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: arynoxBorder)),
                ),
                child: Row(
                  children: [
                    _FileIcon(entry: entry, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: arynoxTextPrimary)),
                          Text(entry.sizeDisplay, style: const TextStyle(fontSize: 13, color: arynoxTextSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: arynoxTextSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow('Path', entry.path),
                        _InfoRow('Type', entry.mimeType),
                        _InfoRow('Size', entry.sizeDisplay),
                        _InfoRow('Extension', entry.extension),
                        _InfoRow('Created', entry.created.isNotEmpty ? entry.created.substring(0, 19) : '-'),
                        _InfoRow('Modified', entry.modified.isNotEmpty ? entry.modified.substring(0, 19) : '-'),
                        _InfoRow('Permissions', '${entry.isHidden ? "hidden" : "visible"}, ${entry.isSymlink ? "symlink" : "regular"}'),
                        if (entry.tags.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('Tags', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: arynoxTextSecondary)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: entry.tags.map((tag) => Chip(
                              label: Text(tag, style: const TextStyle(fontSize: 11, color: arynoxTextPrimary)),
                              backgroundColor: arynoxAccent.withOpacity(0.2),
                              side: BorderSide.none,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            )).toList(),
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
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 13, color: arynoxTextSecondary, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: arynoxTextPrimary)),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _QuickActionButton({required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16, color: color),
        onPressed: onPressed,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    );
  }
}

class _FileIcon extends StatelessWidget {
  final FileEntry entry;
  final double size;

  const _FileIcon({required this.entry, this.size = 24});

  @override
  Widget build(BuildContext context) {
    if (entry.isDir) {
      return Icon(Icons.folder_outlined, size: size, color: arynoxWarning);
    }
    final ext = entry.extension.toLowerCase();
    switch (ext) {
      case 'dart':
      case 'js':
      case 'ts':
      case 'py':
      case 'rs':
      case 'go':
      case 'java':
        return Icon(Icons.code_outlined, size: size, color: arynoxAccent);
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'svg':
        return Icon(Icons.image_outlined, size: size, color: arynoxSuccess);
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return Icon(Icons.videocam_outlined, size: size, color: const Color(0xFFFF6B9D));
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
        return Icon(Icons.audiotrack_outlined, size: size, color: arynoxWarning);
      case 'pdf':
        return Icon(Icons.picture_as_pdf_outlined, size: size, color: arynoxError);
      case 'zip':
      case 'tar':
      case 'gz':
      case 'rar':
      case '7z':
        return Icon(Icons.archive_outlined, size: size, color: arynoxTextSecondary);
      case 'doc':
      case 'docx':
        return Icon(Icons.description_outlined, size: size, color: const Color(0xFF448AFF));
      case 'xls':
      case 'xlsx':
        return Icon(Icons.table_chart_outlined, size: size, color: const Color(0xFF4CAF50));
      default:
        return Icon(Icons.insert_drive_file_outlined, size: size, color: arynoxTextSecondary);
    }
  }
}

class _SearchResultsView extends ConsumerWidget {
  final String query;

  const _SearchResultsView({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider(query));

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: arynoxAccent)),
      error: (err, _) => Center(child: Text('Search error: $err', style: const TextStyle(color: arynoxError))),
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 64, color: arynoxTextSecondary.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text('No results for "$query"', style: const TextStyle(color: arynoxTextSecondary, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final entry = results[index];
            return _FileListTile(entry: entry, isSelected: false)
                .animate()
                .fadeIn(duration: 300.ms, delay: (index * 20).ms);
          },
        );
      },
    );
  }
}

ImageFilter _blurFilter() => ImageFilter.blur(sigmaX: 20, sigmaY: 20);
