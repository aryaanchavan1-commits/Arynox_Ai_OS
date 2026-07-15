import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/services/shell_state.dart';
import '../../core/models/app_info.dart';

class ApplicationLauncher extends ConsumerWidget {
  const ApplicationLauncher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchQuery = ref.watch(searchQueryProvider);
    final apps = ref.watch(appRegistryProvider);

    final filteredApps = apps.where((app) {
      if (searchQuery.isEmpty) return true;
      final query = searchQuery.toLowerCase();
      return app.name.toLowerCase().contains(query) ||
          app.description.toLowerCase().contains(query) ||
          app.categories.any((c) => c.toLowerCase().contains(query));
    }).toList();

    final categories = apps
        .expand((app) => app.categories)
        .toSet()
        .toList()
      ..sort();

    return Align(
      alignment: Alignment.bottomCenter,
      child: GlassContainer(
        width: 720,
        height: 520,
        borderRadius: 20,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
                style: TextStyle(
                  color: isDark ? Colors.white : ArynoxColors.textPrimaryLight,
                ),
                decoration: InputDecoration(
                  hintText: 'Search applications...',
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Category chips
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // App grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: filteredApps.length,
                itemBuilder: (context, index) {
                  final app = filteredApps[index];
                  return _LauncherAppItem(app: app);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LauncherAppItem extends StatelessWidget {
  final AppInfo app;

  const _LauncherAppItem({required this.app});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  app.icon,
                  size: 22,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : ArynoxColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                app.name,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : ArynoxColors.textPrimaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
