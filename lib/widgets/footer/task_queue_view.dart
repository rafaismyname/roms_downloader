import 'package:flutter/material.dart';
import 'package:roms_downloader/models/task_queue_model.dart';
import 'package:roms_downloader/utils/formatters.dart';
import 'package:roms_downloader/widgets/footer/task_empty_state.dart';

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
