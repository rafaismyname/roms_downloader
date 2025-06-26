import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';
import 'package:roms_downloader/providers/download_provider.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/widgets/header/console_dropdown.dart';
import 'package:roms_downloader/widgets/header/download_button.dart';
import 'package:roms_downloader/widgets/header/download_directory.dart';
import 'package:roms_downloader/widgets/header/search_field.dart';

class Controls extends ConsumerWidget {
  final List<Console> consoles;
  final Console? selectedConsole;
  final String downloadDir;
  final Function(Console) onConsoleSelect;
  final VoidCallback onDirectoryChange;

  const Controls({
    super.key,
    required this.consoles,
    required this.selectedConsole,
    required this.downloadDir,
    required this.onConsoleSelect,
    required this.onDirectoryChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final downloadState = ref.watch(downloadProvider);
    final downloadNotifier = ref.read(downloadProvider.notifier);
    final catalogState = ref.watch(catalogProvider);
    final catalogNotifier = ref.read(catalogProvider.notifier);

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isDesktop = Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.linux;
    final useCompactLayout = isLandscape && !isDesktop;

    final isInteractive = !appState.loading && !downloadState.downloading;
    final canDownload = !appState.loading && downloadNotifier.hasDownloadableSelectedGames();

    return Container(
        padding: EdgeInsets.all(useCompactLayout ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildResponsiveRow(
              context,
              widgets: [
                ConsoleDropdown(
                  consoles: consoles,
                  selectedConsole: selectedConsole,
                  isInteractive: isInteractive,
                  isCompact: true,
                  onConsoleSelect: onConsoleSelect,
                ),
                SearchField(
                  initialText: catalogState.filterText,
                  isEnabled: isInteractive,
                  isCompact: true,
                  onChanged: (text) => catalogNotifier.updateFilterText(text),
                ),
                DownloadDirectory(
                  downloadDir: downloadDir,
                  isInteractive: isInteractive,
                  onDirectoryChange: onDirectoryChange,
                  displayMode: DirectoryDisplayMode.compact,
                ),
                DownloadButton(
                  isEnabled: canDownload,
                  isDownloading: downloadState.downloading,
                  isLoading: appState.loading,
                  isCompact: true,
                  onPressed: () => downloadNotifier.startSelectedDownloads(downloadDir, selectedConsole?.id),
                ),
              ],
              flexValues: [4, 3, 3, 1],
              spacing: 8,
            ),
          ],
        ));
  }

  Widget _buildResponsiveRow(
    BuildContext context, {
    required List<Widget> widgets,
    List<int>? flexValues,
    double spacing = 8,
    double breakpoint = 600,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > breakpoint;

        if (isWideScreen) {
          final List<Widget> rowChildren = [];
          for (int i = 0; i < widgets.length; i++) {
            if (i > 0) {
              rowChildren.add(SizedBox(width: spacing));
            }
            final flex = flexValues != null && i < flexValues.length ? flexValues[i] : 1;
            rowChildren.add(Expanded(flex: flex, child: widgets[i]));
          }
          return Row(children: rowChildren);
        } else {
          final List<Widget> columnChildren = [];
          for (int i = 0; i < widgets.length; i++) {
            if (i > 0) {
              columnChildren.add(const SizedBox(height: 8));
            }
            columnChildren.add(widgets[i]);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: columnChildren,
          );
        }
      },
    );
  }
}
