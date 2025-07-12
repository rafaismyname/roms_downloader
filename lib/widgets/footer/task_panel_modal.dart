import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/game_state_model.dart';
import 'package:roms_downloader/models/task_queue_model.dart';
import 'package:roms_downloader/providers/game_state_provider.dart';
import 'package:roms_downloader/providers/task_queue_provider.dart';
import 'package:roms_downloader/utils/formatters.dart';
import 'package:roms_downloader/widgets/footer/task_list_view.dart';
import 'package:roms_downloader/widgets/footer/task_empty_state.dart';

class TaskPanelModal extends ConsumerStatefulWidget {
  const TaskPanelModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

    final downloadingGames = gameStateManager.values
        .where((state) => state.status == GameStatus.downloading || state.status == GameStatus.downloadQueued || state.status == GameStatus.downloadPaused)
        .toList();

    final extractingGames =
        gameStateManager.values.where((state) => state.status == GameStatus.extracting || state.status == GameStatus.extractionQueued).toList();

    final queuedTasks = taskQueueState.tasks.where((task) => task.status == TaskQueueStatus.waiting).toList();

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
            padding: EdgeInsets.all(16),
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
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Task Manager',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: Icon(Icons.download),
                text: 'Downloads',
                iconMargin: EdgeInsets.only(bottom: 4),
              ),
              Tab(
                icon: Icon(Icons.archive),
                text: 'Extractions',
                iconMargin: EdgeInsets.only(bottom: 4),
              ),
              Tab(
                icon: Icon(Icons.queue),
                text: 'Queue',
                iconMargin: EdgeInsets.only(bottom: 4),
              ),
              Tab(
                icon: Icon(Icons.history),
                text: 'Completed',
                iconMargin: EdgeInsets.only(bottom: 4),
              ),
            ],
            isScrollable: false,
            labelStyle: TextStyle(fontSize: 12),
            unselectedLabelStyle: TextStyle(fontSize: 12),
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
                TaskQueueView(
                  tasks: queuedTasks,
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
}

class TaskQueueView extends StatelessWidget {
  final List<QueuedTask> tasks;
  final String emptyMessage;
  final IconData emptyIcon;

  const TaskQueueView({
    super.key,
    required this.tasks,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return EmptyStateWidget(
        message: emptyMessage,
        icon: emptyIcon,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (context, index) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          child: ListTile(
            leading: Icon(
              task.type == TaskType.download ? Icons.download : Icons.archive,
              color: getTaskStatusColor(context, task.status),
            ),
            title: Text(
              task.id,
              style: TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: getTaskStatusColor(context, task.status),
                  ),
                ),
                if (task.error != null) ...[
                  SizedBox(height: 4),
                  Text(
                    task.error!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            trailing: Text(
              formatTaskTime(task),
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
        );
      },
    );
  }
}
