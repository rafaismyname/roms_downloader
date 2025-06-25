import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:roms_downloader/models/download_model.dart';
import 'package:roms_downloader/providers/download_provider.dart';

class Footer extends ConsumerWidget {
  final bool loading;
  final int gameCount;

  const Footer({
    super.key,
    required this.loading,
    required this.gameCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadProvider);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final activeDownloads = downloadState.taskStatus.values.where((status) => status == TaskStatus.running || status == TaskStatus.enqueued).length;

    final overallProgress = _calculateOverallProgress(downloadState);
    final showProgressBar = downloadState.downloading && downloadState.selectedTasks.isNotEmpty;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isLandscape ? 6 : 8,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: isLandscape ? 0.5 : 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            loading
                ? "Loading catalog..."
                : downloadState.downloading && activeDownloads > 0
                    ? "Downloading $activeDownloads games"
                    : "$gameCount games available",
            style: TextStyle(
              fontSize: isLandscape ? 12 : 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (showProgressBar) ...[
            SizedBox(height: isLandscape ? 6 : 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: overallProgress,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                color: Theme.of(context).colorScheme.primary,
                minHeight: isLandscape ? 20 : 24,
              ),
            ),
            SizedBox(height: isLandscape ? 2 : 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Progress ($activeDownloads games):',
                  style: TextStyle(
                    fontSize: isLandscape ? 10 : 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${(overallProgress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: isLandscape ? 10 : 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  double _calculateOverallProgress(DownloadState downloadState) {
    final progressValues = downloadState.taskProgress.values.where((p) => p > 0);
    if (progressValues.isEmpty) return 0.0;

    final sum = progressValues.reduce((a, b) => a + b);
    return sum / progressValues.length;
  }
}
