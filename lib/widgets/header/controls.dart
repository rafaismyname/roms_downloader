import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';
import 'package:roms_downloader/providers/download_provider.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/providers/extraction_provider.dart';
import 'package:roms_downloader/providers/settings_provider.dart';
import 'package:roms_downloader/screens/settings_screen.dart';
import 'package:roms_downloader/widgets/header/console_dropdown.dart';
import 'package:roms_downloader/widgets/header/download_button.dart';
import 'package:roms_downloader/widgets/header/search_field.dart';

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
    final settingsNotifier = ref.read(settingsProvider.notifier);

    final isInteractive = !appState.loading && !downloadState.downloading && !extractionState.isExtracting;
    final canDownload = !appState.loading && downloadNotifier.hasDownloadableSelectedGames();

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 9,
                child: ConsoleDropdown(
                  consoles: consoles,
                  selectedConsole: selectedConsole,
                  isInteractive: isInteractive,
                  isCompact: true,
                  onConsoleSelect: onConsoleSelect,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: isInteractive
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsScreen(
                                initialConsoleId: selectedConsole?.id,
                              ),
                            ),
                          );
                        }
                      : null,
                  tooltip: 'Console Settings',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 9,
                child: SearchField(
                  initialText: catalogState.filterText,
                  isEnabled: isInteractive,
                  isCompact: true,
                  onChanged: (text) => catalogNotifier.updateFilterText(text),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: DownloadButton(
                  isEnabled: canDownload,
                  isDownloading: downloadState.downloading,
                  isLoading: appState.loading,
                  isCompact: true,
                  onPressed: () async {
                    final downloadDir = settingsNotifier.getDownloadDir(selectedConsole?.id);
                    await downloadNotifier.startSelectedDownloads(downloadDir, selectedConsole?.id);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
