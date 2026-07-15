import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/shell_state.dart';

class WorkspaceArea extends ConsumerWidget {
  const WorkspaceArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWs = ref.watch(currentWorkspaceProvider);
    final wsCount = ref.watch(workspaceCountProvider);

    return Column(
      children: [
        // Workspace indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(wsCount, (index) {
              return GestureDetector(
                onTap: () => ref.read(currentWorkspaceProvider.notifier).state = index,
                child: Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == currentWs
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              );
            }),
          ),
        ),

        // Window area (placeholder - compositor renders here)
        const Expanded(
          child: Center(
            child: Text(
              'Workspace Area',
              style: TextStyle(color: Colors.white24),
            ),
          ),
        ),
      ],
    );
  }
}
