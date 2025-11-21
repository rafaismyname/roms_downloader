import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/catalog_model.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/models/app_state_model.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';
import 'package:roms_downloader/providers/download_provider.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/providers/task_queue_provider.dart';
import 'package:roms_downloader/services/task_queue_service.dart';
import 'package:roms_downloader/screens/settings_screen.dart';
import 'package:roms_downloader/screens/about_screen.dart';
import 'package:roms_downloader/widgets/header/console_dropdown.dart';
import 'package:roms_downloader/widgets/header/search_field.dart';
import 'package:roms_downloader/widgets/header/filter_modal.dart';

class Header extends ConsumerStatefulWidget {
  final List<Console> consoles;
  final Console? selectedConsole;
  final Function(Console) onConsoleSelect;

  const Header({
    super.key,
    required this.consoles,
    required this.selectedConsole,
    required this.onConsoleSelect,
  });

  @override
  ConsumerState<Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<Header> {
  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final downloadNotifier = ref.read(downloadProvider.notifier);
    final catalogState = ref.watch(catalogProvider);
    final catalogNotifier = ref.read(catalogProvider.notifier);
    final taskQueueState = ref.watch(taskQueueProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 600;
    final isMobile = screenWidth < 480;

    final canAccessSettings = !appState.loading && !taskQueueState.hasRunningTasks;
    final canDownload = !appState.loading && downloadNotifier.hasDownloadableSelectedGames();

    return Container(
      height: !isMobile ? (kToolbarHeight - 5) + MediaQuery.of(context).padding.top : null,
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
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ConsoleDropdown(
                            consoles: widget.consoles,
                            selectedConsole: widget.selectedConsole,
                            isInteractive: !appState.loading,
                            onConsoleSelect: widget.onConsoleSelect,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: SearchField(
                            initialText: catalogState.filterText,
                            isEnabled: !ref.watch(appStateProvider).loading,
                            onChanged: (text) => catalogNotifier.updateFilterText(text),
                          ),
                        ),
                        SizedBox(width: 8),
                        FocusTraversalGroup(
                          descendantsAreFocusable: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: _buildActionWidgets(
                              context: context,
                              appState: appState,
                              catalogState: catalogState,
                              canDownload: canDownload,
                              canAccessSettings: canAccessSettings,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
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
                        isInteractive: !ref.watch(appStateProvider).loading,
                        onConsoleSelect: widget.onConsoleSelect,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: isNarrow ? 4 : 3,
                      child: SearchField(
                        initialText: catalogState.filterText,
                        isEnabled: !ref.watch(appStateProvider).loading,
                        onChanged: (text) => catalogNotifier.updateFilterText(text),
                      ),
                    ),
                    SizedBox(width: 8),
                    FocusTraversalGroup(
                      descendantsAreFocusable: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _buildActionWidgets(
                          context: context,
                          appState: appState,
                          catalogState: catalogState,
                          canDownload: canDownload,
                          canAccessSettings: canAccessSettings,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  List<Widget> _buildActionWidgets({
    required BuildContext context,
    required AppState appState,
    required CatalogState catalogState,
    required bool canDownload,
    required bool canAccessSettings,
  }) {
    final appStateNotifier = ref.read(appStateProvider.notifier);

    return [
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
                final selectedGames = catalogState.games.where((game) => catalogState.selectedGames.contains(game.gameId)).toList();
                TaskQueueService.startDownloads(ref, selectedGames, widget.selectedConsole?.id);
              }
            : null,
        tooltip: 'Download Selected',
      ),
      SizedBox(width: 4),
      _buildActionButton(
        context: context,
        icon: appState.viewMode == ViewMode.grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
        isActive: false,
        onPressed: () => appStateNotifier.toggleViewMode(),
        tooltip: appState.viewMode == ViewMode.grid ? 'List View' : 'Grid View',
      ),
      SizedBox(width: 4),
      PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        tooltip: 'More options',
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
            case 'theme':
              appStateNotifier.toggleThemeMode();
              break;
            case 'about':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AboutScreen(),
                ),
              );
              break;
            case 'exit':
              exit(0);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'theme',
            child: Row(
              children: [
                Icon(
                  appState.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                  size: 18,
                ),
                SizedBox(width: 12),
                Text(appState.themeMode == ThemeMode.dark ? 'Light Mode' : 'Dark Mode'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'settings',
            enabled: canAccessSettings,
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
          if (Platform.isLinux)
            PopupMenuItem(
              value: 'exit',
              child: Row(
                children: [
                  Icon(Icons.exit_to_app, size: 18, color: Theme.of(context).colorScheme.error),
                  SizedBox(width: 12),
                  Text('Exit', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ),
            ),
        ],
      ),
    ];
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    bool isActive = false,
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
      ],
    );
  }
}
