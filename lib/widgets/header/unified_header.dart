import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';
import 'package:roms_downloader/providers/download_provider.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/providers/extraction_provider.dart';
import 'package:roms_downloader/services/task_queue_service.dart';
import 'package:roms_downloader/screens/settings_screen.dart';
import 'package:roms_downloader/screens/about_screen.dart';
import 'package:roms_downloader/widgets/header/console_dropdown.dart';
import 'package:roms_downloader/widgets/header/search_field.dart';
import 'package:roms_downloader/widgets/header/filter_modal.dart';

class UnifiedHeader extends ConsumerStatefulWidget {
  final List<Console> consoles;
  final Console? selectedConsole;
  final Function(Console) onConsoleSelect;

  const UnifiedHeader({
    super.key,
    required this.consoles,
    required this.selectedConsole,
    required this.onConsoleSelect,
  });

  @override
  ConsumerState<UnifiedHeader> createState() => _UnifiedHeaderState();
}

class _UnifiedHeaderState extends ConsumerState<UnifiedHeader> {
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _filterFocusNode = FocusNode();
  final FocusNode _downloadFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _filterFocusNode.dispose();
    _downloadFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final downloadState = ref.watch(downloadProvider);
    final downloadNotifier = ref.read(downloadProvider.notifier);
    final catalogState = ref.watch(catalogProvider);
    final catalogNotifier = ref.read(catalogProvider.notifier);
    final extractionState = ref.watch(extractionProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 600;

    final isSettingsInteractive = !appState.loading && !downloadState.downloading && !extractionState.isExtracting;
    final canDownload = !appState.loading && downloadNotifier.hasDownloadableSelectedGames();

    return Container(
      height: Platform.isAndroid ? 76 : 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              if (!isNarrow) ...[
                Image.asset('assets/icon.png', width: 35),
                SizedBox(width: 16),
              ],
              Expanded(
                flex: isNarrow ? 3 : 2,
                child: ConsoleDropdown(
                  consoles: widget.consoles,
                  selectedConsole: widget.selectedConsole,
                  isInteractive: !appState.loading,
                  onConsoleSelect: widget.onConsoleSelect,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: isNarrow ? 4 : 3,
                child: SearchField(
                  initialText: catalogState.filterText,
                  isEnabled: !appState.loading,
                  onChanged: (text) => catalogNotifier.updateFilterText(text),
                ),
              ),
              SizedBox(width: 8),
              _buildActionButton(
                context: context,
                icon: catalogState.filter.isActive ? Icons.filter_alt : Icons.filter_alt_outlined,
                isActive: catalogState.filter.isActive,
                onPressed: () => FilterModal.show(context),
                tooltip: 'Filters',
              ),
              SizedBox(width: 4),
              _buildActionButton(
                context: context,
                icon: Icons.download_rounded,
                isActive: canDownload,
                onPressed: canDownload
                    ? () {
                        final selectedGames = catalogState.games.where((game) => catalogState.selectedGames.contains(game.taskId)).toList();
                        TaskQueueService.startDownloads(ref, selectedGames, widget.selectedConsole?.id);
                      }
                    : null,
                tooltip: 'Download Selected',
                showBadge: downloadState.downloading,
              ),
              SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                tooltip: 'More options',
                enabled: isSettingsInteractive,
                onSelected: (value) {
                  switch (value) {
                    case 'settings':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(consoleId: widget.selectedConsole?.id),
                        ),
                      );
                      break;
                    case 'about':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AboutScreen(),
                        ),
                      );
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 18),
                        SizedBox(width: 12),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'about',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 18),
                        SizedBox(width: 12),
                        Text('About'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    bool isActive = false,
    bool showBadge = false,
  }) {
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : onPressed != null
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              size: 20,
            ),
            onPressed: onPressed,
            tooltip: tooltip,
            padding: EdgeInsets.zero,
          ),
        ),
        if (showBadge)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
