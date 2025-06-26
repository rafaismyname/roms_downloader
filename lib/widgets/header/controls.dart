import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/app_state_model.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/models/download_model.dart';
import 'package:roms_downloader/models/catalog_model.dart';
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

    return Container(
      padding: EdgeInsets.all(useCompactLayout ? 8 : 16),
      decoration: useCompactLayout
          ? BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
            )
          : null,
      child: useCompactLayout
          ? _buildCompactContent(context, appState, downloadState, downloadNotifier, catalogState, catalogNotifier)
          : _buildSpacedContent(context, appState, downloadState, downloadNotifier, catalogState, catalogNotifier),
    );
  }

  Widget _buildCompactContent(
      BuildContext context, 
      AppState appState, 
      DownloadState downloadState,
      DownloadNotifier downloadNotifier,
      CatalogState catalogState,
      CatalogNotifier catalogNotifier
  ) {
    final isInteractive = !appState.loading && !downloadState.downloading;
    final canDownload = !appState.loading && downloadNotifier.hasDownloadableSelectedGames();
    return Row(
      children: [
        Expanded(
          flex: 20,
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
          flex: 20,
          child: SearchField(
            initialText: catalogState.filterText,
            isEnabled: isInteractive,
            isCompact: true,
            onChanged: (text) => catalogNotifier.updateFilterText(text),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 20,
          child: DownloadDirectory(
            downloadDir: downloadDir,
            isInteractive: isInteractive,
            onDirectoryChange: onDirectoryChange,
            displayMode: DirectoryDisplayMode.compact,
          ),
        ),
        const SizedBox(width: 8),
        DownloadButton(
          isCompact: true,
          isEnabled: canDownload,
          isDownloading: downloadState.downloading,
          isLoading: appState.loading,
          selectedCount: catalogState.selectedGames.length,
          onPressed: () => downloadNotifier.startSelectedDownloads(downloadDir, selectedConsole?.id),
        ),
      ],
    );
  }

  Widget _buildSpacedContent(
      BuildContext context, 
      AppState appState, 
      DownloadState downloadState,
      DownloadNotifier downloadNotifier,
      CatalogState catalogState,
      CatalogNotifier catalogNotifier
  ) {
    final isInteractive = !appState.loading && !downloadState.downloading;
    final canDownload = !appState.loading && downloadNotifier.hasDownloadableSelectedGames();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildResponsiveRow(
          context,
          firstWidget: ConsoleDropdown(
            consoles: consoles,
            selectedConsole: selectedConsole,
            isInteractive: isInteractive,
            isCompact: false,
            onConsoleSelect: onConsoleSelect,
          ),
          secondWidget: SearchField(
            initialText: catalogState.filterText,
            isEnabled: isInteractive,
            isCompact: false,
            onChanged: (text) => catalogNotifier.updateFilterText(text),
          ),
          firstFlex: 2,
          secondFlex: 3,
          spacing: 16,
        ),
        const SizedBox(height: 12),
        _buildResponsiveRow(
          context,
          firstWidget: DownloadDirectory(
            downloadDir: downloadDir,
            isInteractive: isInteractive,
            onDirectoryChange: onDirectoryChange,
            displayMode: DirectoryDisplayMode.full,
          ),
          secondWidget: DownloadButton(
            isCompact: false,
            isEnabled: canDownload,
            isDownloading: downloadState.downloading,
            isLoading: appState.loading,
            selectedCount: catalogState.selectedGames.length,
            onPressed: () => downloadNotifier.startSelectedDownloads(downloadDir, selectedConsole?.id),
          ),
          firstFlex: 3,
          secondFlex: 2,
          spacing: 16,
        ),
      ],
    );
  }

  Widget _buildResponsiveRow(
    BuildContext context, {
    required Widget firstWidget,
    required Widget secondWidget,
    required int firstFlex,
    required int secondFlex,
    required double spacing,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;

        return isWideScreen
            ? Row(
                children: [
                  Expanded(flex: firstFlex, child: firstWidget),
                  SizedBox(width: spacing),
                  Expanded(flex: secondFlex, child: secondWidget),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  firstWidget,
                  const SizedBox(height: 8),
                  secondWidget,
                ],
              );
      },
    );
  }
}
