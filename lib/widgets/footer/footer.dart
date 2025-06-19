import 'package:flutter/material.dart';
import 'package:roms_downloader/models/app_models.dart';
import 'package:roms_downloader/utils/formatters.dart';

class Footer extends StatelessWidget {
  final bool downloading;
  final bool loading;
  final DownloadStats downloadStats;
  final int gameCount;
  final int selectedGamesCount;
  final int activeDownloadsCount;

  const Footer({
    super.key,
    required this.downloading,
    required this.loading,
    required this.downloadStats,
    required this.gameCount,
    required this.selectedGamesCount,
    this.activeDownloadsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final showProgressBar = downloading && downloadStats.totalSize > 0;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isLandscape ? 6 : 8,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
                : downloading && downloadStats.activeDownloads > 0
                    ? "Downloading ${activeDownloadsCount > 0 ? activeDownloadsCount : selectedGamesCount} games"
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
                value: downloadStats.totalSize > 0 ? downloadStats.totalDownloaded / downloadStats.totalSize : 0,
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
                  'Total Progress (${activeDownloadsCount > 0 ? activeDownloadsCount : selectedGamesCount} games):',
                  style: TextStyle(
                    fontSize: isLandscape ? 10 : 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${formatBytes(downloadStats.totalDownloaded)} / ${formatBytes(downloadStats.totalSize)}'
                  '${downloadStats.downloadSpeed > 0 ? " @ ${formatSpeed(downloadStats.downloadSpeed)}" : ""}',
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
}
