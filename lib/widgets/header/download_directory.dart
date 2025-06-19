import 'package:flutter/material.dart';

enum DirectoryDisplayMode { compact, full }

class DownloadDirectory extends StatelessWidget {
  final String downloadDir;
  final bool isInteractive;
  final VoidCallback onDirectoryChange;
  final DirectoryDisplayMode displayMode;

  const DownloadDirectory({
    super.key,
    required this.downloadDir,
    required this.onDirectoryChange,
    this.isInteractive = true,
    this.displayMode = DirectoryDisplayMode.full,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = displayMode == DirectoryDisplayMode.compact;

    final container = Container(
      height: isCompact ? 32 : null,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: isCompact ? 0.5 : 1.0,
        ),
      ),
      child: isCompact
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isInteractive ? onDirectoryChange : null,
                borderRadius: BorderRadius.circular(4),
                child: _buildContent(context, isCompact),
              ),
            )
          : _buildContent(context, isCompact),
    );

    return container;
  }

  Widget _buildContent(BuildContext context, bool isCompact) {
    return Padding(
      padding: isCompact
          ? const EdgeInsets.symmetric(horizontal: 8)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.folder_open,
            size: isCompact ? 16 : 24,
            color: isInteractive ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              isCompact ? _getTruncatedPath(downloadDir) : downloadDir,
              style: TextStyle(
                fontFamily: isCompact ? null : 'monospace',
                fontSize: isCompact ? 11 : 13,
                color: isInteractive ? Theme.of(context).colorScheme.onSurface : Theme.of(context).disabledColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          if (!isCompact) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: isInteractive ? onDirectoryChange : null,
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Change...', style: TextStyle(fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }

  String _getTruncatedPath(String path) =>
      path.length > 30 ? '${path.substring(0, 15)}...${path.substring(path.length - 15)}' : path;
}
