import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/game_state_model.dart';
import 'package:roms_downloader/models/task_queue_model.dart';
import 'package:roms_downloader/providers/game_state_provider.dart';
import 'package:roms_downloader/providers/task_queue_provider.dart';
import 'package:roms_downloader/widgets/footer/task_list_view.dart';
import 'package:roms_downloader/widgets/footer/task_queue_view.dart';

class TaskPanelModal extends ConsumerStatefulWidget {
  const TaskPanelModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width * 0.9,
        minHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      builder: (context) => const TaskPanelModal(),
    );
  }

  @override
  ConsumerState<TaskPanelModal> createState() => _TaskPanelModalState();
}

class _TaskPanelModalState extends ConsumerState<TaskPanelModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameStateManager = ref.watch(gameStateManagerProvider);
    final taskQueueState = ref.watch(taskQueueProvider);

    final downloadingGames =
        gameStateManager.values.where((state) => state.status == GameStatus.downloading || state.status == GameStatus.downloadPaused).toList();

    final extractingGames = gameStateManager.values.where((state) => state.status == GameStatus.extracting).toList();

    final queuedGames =
        gameStateManager.values.where((state) => state.status == GameStatus.downloadQueued || state.status == GameStatus.extractionQueued).toList();

    final completedTasks = taskQueueState.tasks
        .where((task) => task.status == TaskQueueStatus.completed || task.status == TaskQueueStatus.failed || task.status == TaskQueueStatus.cancelled)
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.task_alt,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Task Manager',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabButton(0, 'Downloads', Icons.download, downloadingGames.length),
                SizedBox(width: 12),
                _buildTabButton(1, 'Extractions', Icons.archive, extractingGames.length),
                SizedBox(width: 12),
                _buildTabButton(2, 'Queue', Icons.queue, queuedGames.length),
                SizedBox(width: 12),
                _buildTabButton(3, 'Completed', Icons.history, completedTasks.length),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TaskListView(
                  games: downloadingGames,
                  emptyMessage: 'No active downloads',
                  emptyIcon: Icons.download_outlined,
                ),
                TaskListView(
                  games: extractingGames,
                  emptyMessage: 'No active extractions',
                  emptyIcon: Icons.archive_outlined,
                ),
                TaskListView(
                  games: queuedGames,
                  emptyMessage: 'No queued tasks',
                  emptyIcon: Icons.queue_outlined,
                ),
                TaskQueueView(
                  tasks: completedTasks,
                  emptyMessage: 'No completed tasks',
                  emptyIcon: Icons.history_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon, int count) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (count > 0) ...[
              SizedBox(width: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
