import 'package:flutter/material.dart';
import 'package:roms_downloader/models/app_models.dart';
import 'package:roms_downloader/widgets/header/console_dropdown.dart';
import 'package:roms_downloader/widgets/header/download_button.dart';
import 'package:roms_downloader/widgets/header/download_directory.dart';
import 'package:roms_downloader/widgets/header/search_field.dart';

class Controls extends StatelessWidget {
  final List<Console> consoles;
  final Console? selectedConsole;
  final String filterText;
  final bool downloading;
  final bool loading;
  final int selectedGamesCount;
  final String downloadDir;
  final Function(Console) onConsoleSelect;
  final Function(String) onFilterChange;
  final VoidCallback onDownloadStart;
  final VoidCallback onDirectoryChange;

  const Controls({
    super.key,
    required this.consoles,
    required this.selectedConsole,
    required this.filterText,
    required this.downloading,
    required this.loading,
    required this.selectedGamesCount,
    required this.downloadDir,
    required this.onConsoleSelect,
    required this.onFilterChange,
    required this.onDownloadStart,
    required this.onDirectoryChange,
  });

  bool get _isInteractive => !downloading && !loading;
  bool get _canDownload => _isInteractive && selectedGamesCount > 0;

  @override
  Widget build(BuildContext context) {
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
      child: useCompactLayout ? _buildCompactContent(context) : _buildSpacedContent(context),
    );
  }

  Widget _buildCompactContent(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 20,
          child: ConsoleDropdown(
            consoles: consoles,
            selectedConsole: selectedConsole,
            isInteractive: _isInteractive,
            isCompact: true,
            onConsoleSelect: onConsoleSelect,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 20,
          child: SearchField(
            initialText: filterText,
            isEnabled: _isInteractive,
            isCompact: true,
            onChanged: onFilterChange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 20,
          child: DownloadDirectory(
            downloadDir: downloadDir,
            isInteractive: _isInteractive,
            onDirectoryChange: onDirectoryChange,
            displayMode: DirectoryDisplayMode.compact,
          ),
        ),
        const SizedBox(width: 8),
        DownloadButton(
          isCompact: true,
          isEnabled: _canDownload,
          isDownloading: downloading,
          isLoading: loading,
          selectedCount: selectedGamesCount,
          onPressed: onDownloadStart,
        ),
      ],
    );
  }

  Widget _buildSpacedContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildResponsiveRow(
          context,
          firstWidget: ConsoleDropdown(
            consoles: consoles,
            selectedConsole: selectedConsole,
            isInteractive: _isInteractive,
            isCompact: false,
            onConsoleSelect: onConsoleSelect,
          ),
          secondWidget: SearchField(
            initialText: filterText,
            isEnabled: _isInteractive,
            isCompact: false,
            onChanged: onFilterChange,
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
            isInteractive: _isInteractive,
            onDirectoryChange: onDirectoryChange,
            displayMode: DirectoryDisplayMode.full,
          ),
          secondWidget: DownloadButton(
            isCompact: false,
            isEnabled: _canDownload,
            isDownloading: downloading,
            isLoading: loading,
            selectedCount: selectedGamesCount,
            onPressed: onDownloadStart,
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
