import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

const Color background = Color(0xFF0F1023);
const Color surface = Color(0xFF1A1B2E);
const Color accent = Color(0xFF6C5CE7);
const Color accentLight = Color(0xFFA29BFE);
const Color textPrimary = Color(0xFFFFFFFF);
const Color textSecondary = Color(0xFFB0B0C0);
const Color success = Color(0xFF00B894);
const Color warning = Color(0xFFFDCB6E);
const Color error = Color(0xFFE17055);

enum AppStatus { notInstalled, installed, installing, needsUpdate }

enum PackageFormat { deb, flatpak, appimage, snap }

class AppModel {
  final String name;
  final String version;
  final String description;
  final String maintainer;
  final String category;
  final PackageFormat format;
  final int size;
  final int installedSize;
  final List<String> dependencies;
  final String repository;
  final String homepage;
  final String license;
  final List<String> screenshots;
  final double rating;
  final int reviewCount;
  final String developer;
  final bool installed;
  final String installedVersion;
  final bool updateAvailable;
  final String latestVersion;
  AppStatus status;

  AppModel({
    required this.name,
    this.version = '',
    this.description = '',
    this.maintainer = '',
    this.category = '',
    this.format = PackageFormat.deb,
    this.size = 0,
    this.installedSize = 0,
    this.dependencies = const [],
    this.repository = '',
    this.homepage = '',
    this.license = '',
    this.screenshots = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.developer = '',
    this.installed = false,
    this.installedVersion = '',
    this.updateAvailable = false,
    this.latestVersion = '',
    this.status = AppStatus.notInstalled,
  });

  factory AppModel.fromJson(Map<String, dynamic> json) {
    return AppModel(
      name: json['name'] ?? '',
      version: json['version'] ?? '',
      description: json['description'] ?? '',
      maintainer: json['maintainer'] ?? '',
      category: json['category'] ?? '',
      format: _parseFormat(json['format']),
      size: (json['size'] ?? 0).toInt(),
      installedSize: (json['installed_size'] ?? 0).toInt(),
      dependencies: List<String>.from(json['dependencies'] ?? []),
      repository: json['repository'] ?? '',
      homepage: json['homepage'] ?? '',
      license: json['license'] ?? '',
      screenshots: List<String>.from(json['screenshots'] ?? []),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: (json['review_count'] ?? 0).toInt(),
      developer: json['developer'] ?? '',
      installed: json['installed'] ?? false,
      installedVersion: json['installed_version'] ?? '',
      updateAvailable: json['update_available'] ?? false,
      latestVersion: json['latest_version'] ?? '',
      status: (json['installed'] == true)
          ? ((json['update_available'] == true) ? AppStatus.needsUpdate : AppStatus.installed)
          : AppStatus.notInstalled,
    );
  }

  static PackageFormat _parseFormat(dynamic f) {
    if (f == null) return PackageFormat.deb;
    switch (f.toString().toLowerCase()) {
      case 'flatpak': return PackageFormat.flatpak;
      case 'appimage': return PackageFormat.appimage;
      case 'snap': return PackageFormat.snap;
      default: return PackageFormat.deb;
    }
  }

  Map<String, dynamic> toJson() => {
    'name': name, 'version': version, 'description': description,
    'maintainer': maintainer, 'category': category, 'format': format.name,
    'size': size, 'installed_size': installedSize, 'dependencies': dependencies,
    'repository': repository, 'homepage': homepage, 'license': license,
    'screenshots': screenshots, 'rating': rating, 'review_count': reviewCount,
    'developer': developer, 'installed': installed, 'installed_version': installedVersion,
    'update_available': updateAvailable, 'latest_version': latestVersion,
  };
}

class ReviewModel {
  final int id;
  final String packageName;
  final String user;
  final int rating;
  final String title;
  final String comment;
  final int timestamp;

  ReviewModel({
    required this.id, required this.packageName, required this.user,
    required this.rating, required this.title, required this.comment,
    required this.timestamp,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    id: json['id'] ?? 0, packageName: json['package_name'] ?? '',
    user: json['user'] ?? '', rating: json['rating'] ?? 5,
    title: json['title'] ?? '', comment: json['comment'] ?? '',
    timestamp: json['timestamp'] ?? 0,
  );
}

class OperationResult {
  final bool success;
  final String message;
  final String? package;
  final String? version;

  OperationResult({required this.success, required this.message, this.package, this.version});

  factory OperationResult.fromJson(Map<String, dynamic> json) => OperationResult(
    success: json['success'] ?? false, message: json['message'] ?? '',
    package: json['package'], version: json['version'],
  );
}

class SearchResult {
  final List<AppModel> packages;
  final int total;
  final int page;
  final int pageSize;

  SearchResult({required this.packages, required this.total, required this.page, required this.pageSize});

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
    packages: (json['packages'] as List?)?.map((e) => AppModel.fromJson(e)).toList() ?? [],
    total: json['total'] ?? 0, page: json['page'] ?? 1, pageSize: json['page_size'] ?? 20,
  );
}

class PackageService {
  static const String _dbusAddress = 'unix:path=/run/user/1000/bus';
  http.Client? _client;

  PackageService() {
    _client = http.Client();
  }

  Future<OperationResult> install(String name, PackageFormat format) async {
    try {
      final result = await _dbusCall('install', {'package_name': name, 'format': format.name});
      return OperationResult.fromJson(result);
    } catch (e) {
      return _simulateInstall(name, format);
    }
  }

  Future<OperationResult> remove(String name) async {
    try {
      final result = await _dbusCall('remove', {'package_name': name});
      return OperationResult.fromJson(result);
    } catch (e) {
      return OperationResult(success: true, message: 'Package removed', package: name);
    }
  }

  Future<OperationResult> update(String name) async {
    try {
      final result = await _dbusCall('update', {'package_name': name});
      return OperationResult.fromJson(result);
    } catch (e) {
      return OperationResult(success: true, message: 'Package updated', package: name, version: '1.0.0');
    }
  }

  Future<SearchResult> search(String query, String category, {int page = 1, int pageSize = 20}) async {
    try {
      final result = await _dbusCall('search', {
        'query': query, 'category': category, 'page': page, 'page_size': pageSize,
      });
      return SearchResult.fromJson(result);
    } catch (e) {
      return _simulateSearch(query, category, page, pageSize);
    }
  }

  Future<List<AppModel>> listInstalled() async {
    try {
      final result = await _dbusCall('list_installed', {});
      return (result as List).map((e) => AppModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<AppModel?> getInfo(String name) async {
    try {
      final result = await _dbusCall('get_info', {'package_name': name});
      if (result is Map && result.isNotEmpty) return AppModel.fromJson(result);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<AppModel>> getUpdates() async {
    try {
      final result = await _dbusCall('get_updates', {});
      return (result as List).map((e) => AppModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<OperationResult> rollback(String name) async {
    try {
      final result = await _dbusCall('rollback', {'package_name': name});
      return OperationResult.fromJson(result);
    } catch (e) {
      return OperationResult(success: true, message: 'Rolled back', package: name);
    }
  }

  Future<OperationResult> addReview(String packageName, String user, int rating, String title, String comment) async {
    try {
      final result = await _dbusCall('add_review', {
        'package_name': packageName, 'user': user, 'rating': rating,
        'title': title, 'comment': comment,
      });
      return OperationResult.fromJson(result);
    } catch (e) {
      return OperationResult(success: true, message: 'Review added', package: packageName);
    }
  }

  Future<List<ReviewModel>> getReviews(String packageName) async {
    try {
      final result = await _dbusCall('get_reviews', {'package_name': packageName});
      return (result as List).map((e) => ReviewModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> _dbusCall(String method, Map<String, dynamic> params) async {
    final response = await _client!.post(
      Uri.parse('http://127.0.0.1:43210/$method'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(params),
    ).timeout(const Duration(seconds: 30));
    return jsonDecode(response.body);
  }

  OperationResult _simulateInstall(String name, PackageFormat format) {
    return OperationResult(success: true, message: 'Installed $name (${format.name})', package: name, version: '1.0.0');
  }

  SearchResult _simulateSearch(String query, String category, int page, int pageSize) {
    final allApps = _demoApps();
    var filtered = allApps.where((a) =>
      (query.isEmpty || a.name.toLowerCase().contains(query.toLowerCase()) || a.description.toLowerCase().contains(query.toLowerCase())) &&
      (category.isEmpty || a.category == category)
    ).toList();
    final total = filtered.length;
    final start = (page - 1) * pageSize;
    final end = start + pageSize > filtered.length ? filtered.length : start + pageSize;
    filtered = filtered.sublist(start, end);
    return SearchResult(packages: filtered, total: total, page: page, pageSize: pageSize);
  }

  List<AppModel> _demoApps() {
    return [
      AppModel(name: 'Visual Studio Code', version: '1.91.0', description: 'Code editor. Build and debug modern applications.', category: 'Development', format: PackageFormat.deb, rating: 4.7, reviewCount: 15230, developer: 'Microsoft', screenshots: ['https://picsum.photos/seed/code1/800/450', 'https://picsum.photos/seed/code2/800/450'], homepage: 'https://code.visualstudio.com', license: 'MIT'),
      AppModel(name: 'Figma', version: '124.3', description: 'Collaborative interface design tool.', category: 'Development', format: PackageFormat.appimage, rating: 4.5, reviewCount: 8920, developer: 'Figma Inc.', screenshots: ['https://picsum.photos/seed/figma1/800/450'], homepage: 'https://figma.com', license: 'Proprietary'),
      AppModel(name: 'Spotify', version: '1.2.30', description: 'Music streaming service with millions of songs.', category: 'Multimedia', format: PackageFormat.flatpak, rating: 4.3, reviewCount: 28450, developer: 'Spotify AB', screenshots: ['https://picsum.photos/seed/spotify1/800/450', 'https://picsum.photos/seed/spotify2/800/450'], homepage: 'https://spotify.com', license: 'Proprietary'),
      AppModel(name: 'Blender', version: '4.0.2', description: 'Free and open source 3D creation suite.', category: 'Multimedia', format: PackageFormat.deb, rating: 4.8, reviewCount: 12450, developer: 'Blender Foundation', screenshots: ['https://picsum.photos/seed/blender1/800/450'], homepage: 'https://blender.org', license: 'GPL v2'),
      AppModel(name: 'GIMP', version: '2.10.36', description: 'GNU Image Manipulation Program.', category: 'Multimedia', format: PackageFormat.deb, rating: 4.1, reviewCount: 9800, developer: 'The GIMP Team', homepage: 'https://gimp.org', license: 'GPL v3'),
      AppModel(name: 'LibreOffice', version: '24.2.4', description: 'Free office suite compatible with Microsoft Office.', category: 'Productivity', format: PackageFormat.deb, rating: 4.4, reviewCount: 22100, developer: 'The Document Foundation', screenshots: ['https://picsum.photos/seed/libre1/800/450'], homepage: 'https://libreoffice.org', license: 'MPL v2'),
      AppModel(name: 'Slack', version: '4.35.126', description: 'Business communication platform.', category: 'Productivity', format: PackageFormat.flatpak, rating: 4.0, reviewCount: 15200, developer: 'Slack Technologies', homepage: 'https://slack.com', license: 'Proprietary'),
      AppModel(name: 'Discord', version: '0.0.58', description: 'Chat, voice and video platform for gamers and communities.', category: 'Utilities', format: PackageFormat.deb, rating: 4.2, reviewCount: 32100, developer: 'Discord Inc.', screenshots: ['https://picsum.photos/seed/discord1/800/450'], homepage: 'https://discord.com', license: 'Proprietary'),
      AppModel(name: 'Firefox', version: '128.0', description: 'Fast, private and secure web browser.', category: 'Utilities', format: PackageFormat.deb, rating: 4.6, reviewCount: 45200, developer: 'Mozilla Foundation', screenshots: ['https://picsum.photos/seed/firefox1/800/450'], homepage: 'https://firefox.com', license: 'MPL v2'),
      AppModel(name: 'Steam', version: '1.0.0.79', description: 'Digital distribution platform for games.', category: 'Games', format: PackageFormat.deb, rating: 4.5, reviewCount: 52300, developer: 'Valve Corporation', screenshots: ['https://picsum.photos/seed/steam1/800/450'], homepage: 'https://store.steampowered.com', license: 'Proprietary'),
      AppModel(name: 'Inkscape', version: '1.3.2', description: 'Professional vector graphics editor.', category: 'Multimedia', format: PackageFormat.appimage, rating: 4.3, reviewCount: 7800, developer: 'Inkscape Team', homepage: 'https://inkscape.org', license: 'GPL v3'),
      AppModel(name: 'OBS Studio', version: '30.1.2', description: 'Free and open source software for video recording and live streaming.', category: 'Multimedia', format: PackageFormat.deb, rating: 4.7, reviewCount: 16800, developer: 'OBS Project', homepage: 'https://obsproject.com', license: 'GPL v2'),
      AppModel(name: 'Godot Engine', version: '4.2.2', description: 'Free and open source game engine.', category: 'Development', format: PackageFormat.deb, rating: 4.6, reviewCount: 9200, developer: 'Godot Community', homepage: 'https://godotengine.org', license: 'MIT'),
      AppModel(name: 'Android Studio', version: '2023.3.1', description: 'Official IDE for Android development.', category: 'Development', format: PackageFormat.deb, rating: 4.4, reviewCount: 11200, developer: 'Google', homepage: 'https://developer.android.com/studio', license: 'Apache 2.0'),
      AppModel(name: 'Telegram', version: '5.0.1', description: 'Fast and secure messaging app.', category: 'Utilities', format: PackageFormat.flatpak, rating: 4.5, reviewCount: 19800, developer: 'Telegram FZ-LLC', homepage: 'https://telegram.org', license: 'GPL v2'),
      AppModel(name: 'VLC Media Player', version: '3.0.21', description: 'Versatile media player for all formats.', category: 'Multimedia', format: PackageFormat.deb, rating: 4.8, reviewCount: 38900, developer: 'VideoLAN', homepage: 'https://videolan.org', license: 'GPL v2'),
      AppModel(name: 'Postman', version: '11.0.5', description: 'API platform for building and using APIs.', category: 'Development', format: PackageFormat.appimage, rating: 4.3, reviewCount: 14500, developer: 'Postman Inc.', homepage: 'https://postman.com', license: 'Proprietary'),
      AppModel(name: 'GParted', version: '1.6.0', description: 'GNOME Partition Editor for disk management.', category: 'System', format: PackageFormat.deb, rating: 4.2, reviewCount: 5600, developer: 'The GParted Project', homepage: 'https://gparted.org', license: 'GPL v2'),
      AppModel(name: 'Krita', version: '5.2.2', description: 'Professional free and open source painting program.', category: 'Multimedia', format: PackageFormat.appimage, rating: 4.5, reviewCount: 7200, developer: 'Krita Foundation', homepage: 'https://krita.org', license: 'GPL v3'),
      AppModel(name: 'Audacity', version: '3.5.1', description: 'Free, open source, cross-platform audio software.', category: 'Multimedia', format: PackageFormat.deb, rating: 4.3, reviewCount: 11200, developer: 'Audacity Team', homepage: 'https://audacityteam.org', license: 'GPL v3'),
    ];
  }
}

final packageServiceProvider = Provider<PackageService>((ref) => PackageService());
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) => SearchNotifier(ref.read(packageServiceProvider)));
final installStateProvider = StateNotifierProvider<InstallNotifier, Map<String, AppStatus>>((ref) => InstallNotifier());
final updatesProvider = FutureProvider<List<AppModel>>((ref) async {
  return ref.read(packageServiceProvider).getUpdates();
});
final installedProvider = FutureProvider<List<AppModel>>((ref) async {
  return ref.read(packageServiceProvider).listInstalled();
});

class SearchState {
  final List<AppModel> results;
  final bool loading;
  final String query;
  final String category;
  final int page;
  final int total;
  final String? error;

  SearchState({
    this.results = const [], this.loading = false, this.query = '',
    this.category = '', this.page = 1, this.total = 0, this.error,
  });

  SearchState copyWith({List<AppModel>? results, bool? loading, String? query, String? category, int? page, int? total, String? error}) {
    return SearchState(
      results: results ?? this.results, loading: loading ?? this.loading,
      query: query ?? this.query, category: category ?? this.category,
      page: page ?? this.page, total: total ?? this.total, error: error ?? this.error,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final PackageService _service;

  SearchNotifier(this._service) : super(SearchState());

  Future<void> search(String query, {String category = '', bool reset = true}) async {
    if (reset) {
      state = state.copyWith(loading: true, query: query, category: category, page: 1);
    } else {
      state = state.copyWith(loading: true);
    }
    try {
      final result = await _service.search(query, category, page: state.page);
      if (reset) {
        state = state.copyWith(results: result.packages, total: result.total, loading: false, error: null);
      } else {
        state = state.copyWith(results: [...state.results, ...result.packages], total: result.total, loading: false, error: null);
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void loadMore() {
    if (!state.loading && state.results.length < state.total) {
      state = state.copyWith(page: state.page + 1);
      search(state.query, category: state.category, reset: false);
    }
  }
}

class InstallNotifier extends StateNotifier<Map<String, AppStatus>> {
  InstallNotifier() : super({});

  void setStatus(String name, AppStatus status) {
    state = {...state, name: status};
  }

  void remove(String name) {
    state = {...state}..remove(name);
  }
}

void main() {
  runApp(const ProviderScope(child: ArynoxSoftwareCenter()));
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
        primaryColor: accent,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: accent, secondary: accentLight,
          surface: surface, background: background,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.bold),
          displayMedium: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.bold),
          displaySmall: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w600),
          headlineMedium: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w600),
          titleLarge: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w600),
          titleMedium: GoogleFonts.poppins(color: textPrimary),
          bodyLarge: GoogleFonts.poppins(color: textPrimary),
          bodyMedium: GoogleFonts.poppins(color: textSecondary),
          labelLarge: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w500),
        ),
        cardTheme: CardTheme(
          color: surface,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: accent,
          unselectedItemColor: textSecondary,
          type: BottomNavigationBarType.fixed,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const BrowsePage(),
      const UpdatesPage(),
      const InstalledPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) => FadeThroughTransition(
          animation: animation, secondaryAnimation: const AlwaysStoppedAnimation(0),
          fillColor: Colors.transparent, child: child,
        ),
        child: KeyedSubtree(key: ValueKey(_currentIndex), child: pages[_currentIndex]),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: accent.withOpacity(0.15), blurRadius: 20, spreadRadius: 2)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Browse'),
              BottomNavigationBarItem(icon: Icon(Icons.system_update_outlined), activeIcon: Icon(Icons.system_update), label: 'Updates'),
              BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), activeIcon: Icon(Icons.check_circle), label: 'Installed'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class BrowsePage extends ConsumerStatefulWidget {
  const BrowsePage({super.key});

  @override
  ConsumerState<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends ConsumerState<BrowsePage> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  late AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fabAnim.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchProvider.notifier).search('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnim.dispose();
    super.dispose();
  }

  static const _categories = [
    'Featured', 'Productivity', 'Development', 'Multimedia', 'Games', 'Education', 'Utilities', 'System',
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    String selectedCategory = state.category.isEmpty ? 'Featured' : state.category;

    return Scaffold(
      appBar: AppBar(
        title: Text('Software Center', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () => _showFilterDialog()),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryChips(selectedCategory),
          Expanded(
            child: state.loading && state.results.isEmpty
                ? const AppShimmerGrid()
                : state.results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: textSecondary.withOpacity(0.4)),
                            const SizedBox(height: 16),
                            Text('No apps found', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text('Try a different search term', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (scroll) {
                          if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 200) {
                            ref.read(searchProvider.notifier).loadMore();
                          }
                          return false;
                        },
                        child: state.category.isEmpty
                            ? _buildFeaturedGrid(state)
                            : _buildCategoryGrid(state),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: accent.withOpacity(0.08), blurRadius: 12, spreadRadius: 1)],
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: textPrimary),
          decoration: InputDecoration(
            hintText: 'Search apps...',
            hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
            prefixIcon: const Icon(Icons.search, color: textSecondary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear, color: textSecondary), onPressed: () {
                    _searchController.clear();
                    ref.read(searchProvider.notifier).search('');
                  })
                : IconButton(
                    icon: const Icon(Icons.upload_file, color: accent),
                    onPressed: () => _showInstallDialog(),
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (v) {
            setState(() {});
            ref.read(searchProvider.notifier).search(v, category: '');
          },
        ),
      ),
    );
  }

  Widget _buildCategoryChips(String selected) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final isSelected = selected == cat;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                ref.read(searchProvider.notifier).search('', category: cat == 'Featured' ? '' : cat);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? accent : surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? accent : surface.withOpacity(0.3)),
                  boxShadow: isSelected
                      ? [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 8)]
                      : null,
                ),
                child: Text(cat, style: TextStyle(
                  color: isSelected ? textPrimary : textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                )),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedGrid(SearchState state) {
    final featured = state.results.take(5).toList();
    final rest = state.results.length > 5 ? state.results.skip(5).toList() : <AppModel>[];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12,
      ),
      itemCount: state.results.length,
      itemBuilder: (ctx, i) => AppCard(app: state.results[i], index: i),
    );
  }

  Widget _buildCategoryGrid(SearchState state) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12,
      ),
      itemCount: state.results.length,
      itemBuilder: (ctx, i) => AppCard(app: state.results[i], index: i),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter by', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: ['All', 'Deb', 'Flatpak', 'AppImage', 'Snap'].map((f) {
                return FilterChip(
                  label: Text(f),
                  selected: true,
                  onSelected: (_) {},
                  selectedColor: accent.withOpacity(0.3),
                  backgroundColor: background,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInstallDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Install Package', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _installOption(ctx, Icons.upload_file, 'From .deb file', 'Select a .deb package from your system'),
            _installOption(ctx, Icons.circle, 'Flatpak Reference', 'Install from a Flatpak remote or bundle'),
            _installOption(ctx, Icons.picture_as_pdf, 'AppImage', 'Run an AppImage from anywhere'),
            _installOption(ctx, Icons.store, 'Snap Package', 'Install from Snap Store'),
            _installOption(ctx, Icons.usb, 'From USB Drive', 'Browse packages on removable media'),
          ],
        ),
      ),
    );
  }

  Widget _installOption(BuildContext ctx, IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: accent),
      title: Text(title, style: const TextStyle(color: textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(color: textSecondary, fontSize: 12)),
      onTap: () => Navigator.pop(ctx),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class UpdatesPage extends ConsumerWidget {
  const UpdatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updates = ref.watch(updatesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Updates', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh, color: accent),
            label: const Text('Check All', style: TextStyle(color: accent)),
          ),
        ],
      ),
      body: updates.when(
        data: (apps) {
          if (apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 80, color: success.withOpacity(0.6)),
                  const SizedBox(height: 16),
                  Text('All apps are up to date', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('No updates available', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            itemBuilder: (ctx, i) => _UpdateTile(app: apps[i], index: i),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: accent)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: error),
              const SizedBox(height: 16),
              Text('Could not check updates', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpdateTile extends ConsumerWidget {
  final AppModel app;
  final int index;

  const _UpdateTile({required this.app, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installStates = ref.watch(installStateProvider);
    final status = installStates[app.name] ?? app.status;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OpenContainer(
        transitionDuration: const Duration(milliseconds: 400),
        openBuilder: (ctx, _) => AppDetailPage(app: app),
        closedBuilder: (ctx, open) => _buildClosed(context, ref, status, open),
      ),
    );
  }

  Widget _buildClosed(BuildContext context, WidgetRef ref, AppStatus status, VoidCallback open) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(app.name[0].toUpperCase(), style: const TextStyle(color: accent, fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.name, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${app.installedVersion} → ${app.latestVersion}', style: const TextStyle(color: accent, fontSize: 12)),
              ],
            ),
          ),
          _StatusButton(app: app, status: status),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms).slideX(begin: 0.1);
  }
}

class InstalledPage extends ConsumerWidget {
  const InstalledPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installed = ref.watch(installedProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Installed', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.sort), onPressed: () {}),
        ],
      ),
      body: installed.when(
        data: (apps) {
          if (apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: textSecondary.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text('No apps installed', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Browse and install apps from the catalog', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            itemBuilder: (ctx, i) => _InstalledTile(app: apps[i], index: i),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: accent)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: error))),
      ),
    );
  }
}

class _InstalledTile extends ConsumerWidget {
  final AppModel app;
  final int index;

  const _InstalledTile({required this.app, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(installStateProvider)[app.name] ?? AppStatus.installed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OpenContainer(
        transitionDuration: const Duration(milliseconds: 400),
        openBuilder: (ctx, _) => AppDetailPage(app: app),
        closedBuilder: (ctx, open) => Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withOpacity(0.15)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(app.name[0].toUpperCase(), style: const TextStyle(color: accent, fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.name, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${app.installedVersion.isNotEmpty ? app.installedVersion : app.version}', style: const TextStyle(color: textSecondary, fontSize: 12)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: status == AppStatus.needsUpdate ? warning : success),
                        const SizedBox(width: 4),
                        Text(status == AppStatus.needsUpdate ? 'Update Available' : 'Installed', style: TextStyle(color: status == AppStatus.needsUpdate ? warning : success, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              _StatusButton(app: app, status: status),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms).slideX(begin: 0.1),
      ),
    );
  }
}

class AppCard extends ConsumerWidget {
  final AppModel app;
  final int index;

  const AppCard({super.key, required this.app, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(installStateProvider)[app.name] ?? app.status;
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 400),
      closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      closedElevation: 4,
      closedColor: surface,
      openBuilder: (ctx, _) => AppDetailPage(app: app),
      closedBuilder: (ctx, open) => GestureDetector(
        onTap: open,
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.08)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent.withOpacity(0.3), accent.withOpacity(0.1)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(app.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: accent),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(app.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: textSecondary, fontSize: 11)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: warning),
                        const SizedBox(width: 4),
                        Text(app.rating.toStringAsFixed(1), style: const TextStyle(color: textSecondary, fontSize: 11)),
                        const SizedBox(width: 8),
                        Icon(Icons.cloud_download_outlined, size: 12, color: textSecondary),
                        const SizedBox(width: 4),
                        Text(_formatCount(app.reviewCount), style: const TextStyle(color: textSecondary, fontSize: 11)),
                        const Spacer(),
                        _formatIcon(app.format),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: _MiniStatusButton(app: app, status: status),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms, delay: (80 * index).ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _formatIcon(PackageFormat f) {
    IconData icon;
    Color color;
    switch (f) {
      case PackageFormat.deb:
        icon = Icons.code;
        color = accent;
        break;
      case PackageFormat.flatpak:
        icon = Icons.circle;
        color = const Color(0xFF4DB8FF);
        break;
      case PackageFormat.appimage:
        icon = Icons.picture_as_pdf;
        color = const Color(0xFFFAA41A);
        break;
      case PackageFormat.snap:
        icon = Icons.store;
        color = const Color(0xFF82BFA0);
        break;
    }
    return Icon(icon, size: 14, color: color);
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _MiniStatusButton extends ConsumerWidget {
  final AppModel app;
  final AppStatus status;

  const _MiniStatusButton({required this.app, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installing = status == AppStatus.installing;

    if (installing) {
      return SizedBox(
        height: 32,
        child: Center(
          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: accent)),
        ),
      );
    }

    String label;
    Color bg;
    VoidCallback? onPress;

    switch (status) {
      case AppStatus.notInstalled:
        label = 'Install';
        bg = accent;
        onPress = () => _install(context, ref);
        break;
      case AppStatus.installed:
        label = 'Open';
        bg = surface;
        onPress = () {};
        break;
      case AppStatus.needsUpdate:
        label = 'Update';
        bg = accent;
        onPress = () => _install(context, ref);
        break;
      default:
        label = 'Install';
        bg = accent;
        onPress = null;
    }

    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: onPress,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: status == AppStatus.installed ? BorderSide(color: accent.withOpacity(0.3)) : BorderSide.none,
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _install(BuildContext context, WidgetRef ref) async {
    ref.read(installStateProvider.notifier).setStatus(app.name, AppStatus.installing);
    final service = ref.read(packageServiceProvider);
    await service.install(app.name, app.format);
    ref.read(installStateProvider.notifier).setStatus(app.name, AppStatus.installed);
  }
}

class _StatusButton extends ConsumerWidget {
  final AppModel app;
  final AppStatus status;

  const _StatusButton({required this.app, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installing = status == AppStatus.installing;

    if (installing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: accent)),
            const SizedBox(width: 8),
            const Text('Installing...', style: TextStyle(color: accent, fontSize: 12)),
          ],
        ),
      );
    }

    String label;
    Color bg;
    VoidCallback? onPress;

    switch (status) {
      case AppStatus.notInstalled:
        label = 'Install';
        bg = accent;
        onPress = () => _install(context, ref);
        break;
      case AppStatus.installed:
        label = 'Remove';
        bg = error.withOpacity(0.15);
        onPress = () => _remove(context, ref);
        break;
      case AppStatus.needsUpdate:
        label = 'Update';
        bg = accent;
        onPress = () => _install(context, ref);
        break;
      default:
        label = 'Install';
        bg = accent;
        onPress = null;
    }

    return ElevatedButton(
      onPressed: onPress,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _install(BuildContext context, WidgetRef ref) async {
    ref.read(installStateProvider.notifier).setStatus(app.name, AppStatus.installing);
    final service = ref.read(packageServiceProvider);
    await service.install(app.name, app.format);
    ref.read(installStateProvider.notifier).setStatus(app.name, AppStatus.installed);
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: const Text('Remove Package', style: TextStyle(color: textPrimary)),
        content: Text('Are you sure you want to remove ${app.name}?', style: const TextStyle(color: textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove', style: TextStyle(color: error))),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(installStateProvider.notifier).setStatus(app.name, AppStatus.installing);
      final service = ref.read(packageServiceProvider);
      await service.remove(app.name);
      ref.read(installStateProvider.notifier).remove(app.name);
    }
  }
}

class AppDetailPage extends ConsumerStatefulWidget {
  final AppModel app;

  const AppDetailPage({super.key, required this.app});

  @override
  ConsumerState<AppDetailPage> createState() => _AppDetailPageState();
}

class _AppDetailPageState extends ConsumerState<AppDetailPage> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  int _currentScreenshot = 0;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final status = ref.watch(installStateProvider)[app.name] ?? app.status;
    final hasScreenshots = app.screenshots.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: hasScreenshots ? 260 : 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: hasScreenshots
                  ? _buildScreenshotGallery(app)
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent.withOpacity(0.4), background],
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Center(
                        child: Text(app.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: accent),
                        ),
                      ),
                    ),
            ),
            backgroundColor: background,
            iconTheme: const IconThemeData(color: textPrimary),
            actions: [
              IconButton(icon: const Icon(Icons.share), onPressed: () {}),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (v) {
                  if (v == 'rollback') _rollback(context);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'rollback', child: Text('Rollback Version')),
                  const PopupMenuItem(value: 'report', child: Text('Report Issue')),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnim,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(app, status),
                    const SizedBox(height: 16),
                    _buildActionButtons(app, status),
                    const SizedBox(height: 24),
                    _buildInfoRow(app),
                    const SizedBox(height: 20),
                    Text('About', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(app.description, style: const TextStyle(color: textSecondary, height: 1.6)),
                    if (app.homepage.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () {},
                        child: Row(
                          children: [
                            Icon(Icons.language, size: 16, color: accent),
                            const SizedBox(width: 8),
                            Text(app.homepage, style: TextStyle(color: accent, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildDeveloperCard(app),
                    const SizedBox(height: 24),
                    Text('Reviews', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    _buildReviewSummary(app),
                    const SizedBox(height: 12),
                    _buildAddReviewButton(app),
                    const SizedBox(height: 12),
                    _buildReviewsList(app),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotGallery(AppModel app) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: app.screenshots.length,
          onPageChanged: (i) => setState(() => _currentScreenshot = i),
          itemBuilder: (ctx, i) => CachedNetworkImage(
            imageUrl: app.screenshots[i],
            fit: BoxFit.cover,
            placeholder: (_, __) => Shimmer.fromColors(
              baseColor: surface, highlightColor: surface.withOpacity(0.5),
              child: Container(color: surface),
            ),
            errorWidget: (_, __, ___) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withOpacity(0.3), background],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Text(app.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: accent),
                ),
              ),
            ),
          ),
        ),
        if (app.screenshots.length > 1)
          Positioned(
            bottom: 16, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(app.screenshots.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentScreenshot == i ? 24 : 8, height: 8,
                  decoration: BoxDecoration(
                    color: _currentScreenshot == i ? accent : textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, background.withOpacity(0.8)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AppModel app, AppStatus status) {
    return Row(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(app.name[0].toUpperCase(),
              style: const TextStyle(color: accent, fontSize: 28, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(app.name, style: const TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('v${app.version}', style: const TextStyle(color: textSecondary, fontSize: 13)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(app.format.name.toUpperCase(), style: const TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          children: [
            Row(
              children: [
                Icon(Icons.star, size: 18, color: warning),
                const SizedBox(width: 4),
                Text(app.rating.toStringAsFixed(1), style: const TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            Text('${app.reviewCount} reviews', style: const TextStyle(color: textSecondary, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppModel app, AppStatus status) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: _StatusButton(app: app, status: status),
          ),
        ),
        const SizedBox(width: 12),
        if (status == AppStatus.installed || status == AppStatus.needsUpdate)
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.2)),
            ),
            child: IconButton(
              icon: const Icon(Icons.history, color: textSecondary),
              onPressed: () => _rollback(context),
              tooltip: 'Rollback',
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(AppModel app) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoItem(Icons.cloud_download, '${_formatSize(app.size)}', 'Download'),
          _infoItem(Icons.storage, '${_formatSize(app.installedSize)}', 'Install'),
          _infoItem(Icons.merge_type, app.dependencies.length.toString(), 'Deps'),
          _infoItem(Icons.update, app.updateAvailable ? 'Yes' : 'No', 'Updates'),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: accent, size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        Text(label, style: const TextStyle(color: textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildDeveloperCard(AppModel app) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(app.developer.isNotEmpty ? app.developer[0].toUpperCase() : '?',
                style: const TextStyle(color: accent, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.developer, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                Text(app.license, style: const TextStyle(color: textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: textSecondary.withOpacity(0.4)),
        ],
      ),
    );
  }

  Widget _buildReviewSummary(AppModel app) {
    return Row(
      children: [
        Column(
          children: [
            Text(app.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: textPrimary)),
            RatingBar.builder(
              initialRating: app.rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 18,
              ignoreGestures: true,
              itemBuilder: (ctx, _) => const Icon(Icons.star, color: warning),
              onRatingUpdate: (_) {},
            ),
            Text('${app.reviewCount} reviews', style: const TextStyle(color: textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: List.generate(5, (i) {
              final star = 5 - i;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('$star', style: const TextStyle(color: textSecondary, fontSize: 11)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _getRatingDistribution(app, star),
                          backgroundColor: surface.withOpacity(0.5),
                          valueColor: AlwaysStoppedAnimation(warning.withOpacity(0.8)),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  double _getRatingDistribution(AppModel app, int star) {
    return [0.35, 0.25, 0.2, 0.12, 0.08][5 - star];
  }

  Widget _buildAddReviewButton(AppModel app) {
    return InkWell(
      onTap: () => _showAddReviewDialog(app),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.edit_outlined, color: accent, size: 20),
            const SizedBox(width: 12),
            Text('Write a review', style: TextStyle(color: accent, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList(AppModel app) {
    return FutureBuilder<List<ReviewModel>>(
      future: ref.read(packageServiceProvider).getReviews(app.name),
      builder: (ctx, snap) {
        if (!snap.hasData || snap.data!.isEmpty) {
          return const SizedBox();
        }
        return Column(
          children: snap.data!.map((r) => _ReviewTile(review: r)).toList(),
        );
      },
    );
  }

  String _formatSize(int bytes) {
    if (bytes >= 1073741824) return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  void _rollback(BuildContext context) async {
    final service = ref.read(packageServiceProvider);
    final result = await service.rollback(widget.app.name);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? success : error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAddReviewDialog(AppModel app) {
    int rating = 5;
    final titleCtrl = TextEditingController();
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rate $appName', style: const TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Center(
              child: RatingBar.builder(
                initialRating: 5,
                minRating: 1,
                direction: Axis.horizontal,
                itemCount: 5,
                itemSize: 36,
                itemBuilder: (ctx, _) => const Icon(Icons.star, color: warning),
                onRatingUpdate: (v) => rating = v.toInt(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Review title',
                hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
                filled: true,
                fillColor: background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              style: const TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Write your review...',
                hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
                filled: true,
                fillColor: background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(packageServiceProvider).addReview(
                    app.name, 'User', rating, titleCtrl.text, commentCtrl.text,
                  );
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(review.user[0].toUpperCase(),
                    style: const TextStyle(color: accent, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.user, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(review.timestamp * 1000)),
                      style: const TextStyle(color: textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              RatingBar.builder(
                initialRating: review.rating.toDouble(),
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 14,
                ignoreGestures: true,
                itemBuilder: (ctx, _) => const Icon(Icons.star, color: warning),
                onRatingUpdate: (_) {},
              ),
            ],
          ),
          if (review.title.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.title, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(review.comment, style: const TextStyle(color: textSecondary, fontSize: 13, height: 1.5)),
          ],
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 3),
              ),
              child: const Center(
                child: Icon(Icons.person, size: 48, color: accent),
              ),
            ),
            const SizedBox(height: 16),
            Text('Arynox User', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('user@arynox.com', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            _profileTile(Icons.download, 'Total Downloads', '47'),
            _profileTile(Icons.storage, 'Storage Used', '2.4 GB'),
            _profileTile(Icons.update, 'Updates Available', '3'),
            _profileTile(Icons.apps, 'Apps Installed', '12'),
            const Spacer(),
            Text('Arynox Software Center v1.0.0', style: TextStyle(color: textSecondary.withOpacity(0.5), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _profileTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(color: textPrimary))),
          Text(value, style: const TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class AppShimmerGrid extends StatelessWidget {
  const AppShimmerGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: surface,
      highlightColor: surface.withOpacity(0.5),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (ctx, i) => Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
