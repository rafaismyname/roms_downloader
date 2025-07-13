import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';
import 'package:roms_downloader/providers/download_provider.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/providers/extraction_provider.dart';
import 'package:roms_downloader/services/task_queue_service.dart';
import 'package:roms_downloader/screens/settings_screen.dart';
import 'package:roms_downloader/widgets/header/console_dropdown.dart';
import 'package:roms_downloader/widgets/header/download_button.dart';
import 'package:roms_downloader/widgets/header/search_field.dart';
import 'package:roms_downloader/widgets/header/filter_modal.dart';

class Controls extends ConsumerWidget {
  final List<Console> consoles;
  final Console? selectedConsole;
  final Function(Console) onConsoleSelect;

  const Controls({
    super.key,
    required this.consoles,
    required this.selectedConsole,
    required this.onConsoleSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final downloadState = ref.watch(downloadProvider);
    final downloadNotifier = ref.read(downloadProvider.notifier);
    final catalogState = ref.watch(catalogProvider);
    final catalogNotifier = ref.read(catalogProvider.notifier);
    final extractionState = ref.watch(extractionProvider);

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenHeight = MediaQuery.of(context).size.height;
    final isShort = isLandscape && screenHeight < 600;

    final isSettingsInteractive = !appState.loading && !downloadState.downloading && !extractionState.isExtracting;
    final canDownload = !appState.loading && downloadNotifier.hasDownloadableSelectedGames();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: isShort ? 30 : 36,
            child: Row(
              children: [
                Expanded(
                  flex: 9,
                  child: ConsoleDropdown(
                    consoles: consoles,
                    selectedConsole: selectedConsole,
                    isInteractive: !appState.loading,
                    onConsoleSelect: onConsoleSelect,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.center,
                    icon: const Icon(Icons.settings),
                    onPressed: isSettingsInteractive
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SettingsScreen(consoleId: selectedConsole?.id),
                              ),
                            );
                          }
                        : null,
                    tooltip: 'Console Settings',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: isShort ? 28 : 32,
            child: Row(
              children: [
                Expanded(
                  flex: 7,
                  child: SearchField(
                    initialText: catalogState.filterText,
                    onChanged: (text) => catalogNotifier.updateFilterText(text),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: double.infinity,
                    child: IconButton(
                      icon: Icon(
                        catalogState.filter.isActive ? Icons.filter_alt : Icons.filter_alt_outlined,
                        color: catalogState.filter.isActive ? Theme.of(context).colorScheme.primary : null,
                      ),
                      onPressed: () => FilterModal.show(context),
                      tooltip: 'Filters',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 1,
                  child: DownloadButton(
                    isEnabled: canDownload,
                    isDownloading: downloadState.downloading,
                    isLoading: appState.loading,
                    onPressed: () {
                      final selectedGames = catalogState.games.where((game) => catalogState.selectedGames.contains(game.taskId)).toList();
                      TaskQueueService.startDownloads(ref, selectedGames, selectedConsole?.id);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
