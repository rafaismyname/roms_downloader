import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/models/settings_model.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';
import 'package:roms_downloader/providers/settings_provider.dart';
import 'package:roms_downloader/widgets/header/console_dropdown.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final String? initialConsoleId;

  const SettingsScreen({super.key, this.initialConsoleId});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Console? selectedConsole;
  bool showGeneral = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = ref.read(appStateProvider);
      if (widget.initialConsoleId != null) {
        selectedConsole = appState.consoles.firstWhere(
          (c) => c.id == widget.initialConsoleId,
          orElse: () => appState.consoles.first,
        );
        showGeneral = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: true,
                                label: Text('General'),
                                icon: Icon(Icons.settings),
                              ),
                              ButtonSegment(
                                value: false,
                                label: Text('Console'),
                                icon: Icon(Icons.videogame_asset),
                              ),
                            ],
                            selected: {showGeneral},
                            onSelectionChanged: (selection) {
                              setState(() {
                                showGeneral = selection.first;
                                if (!showGeneral && selectedConsole == null) {
                                  selectedConsole = appState.consoles.isNotEmpty ? appState.consoles.first : null;
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    if (!showGeneral) ...[
                      const SizedBox(height: 16),
                      ConsoleDropdown(
                        selectedConsole: selectedConsole,
                        consoles: appState.consoles,
                        isInteractive: true,
                        isCompact: false,
                        onConsoleSelect: (console) {
                          setState(() {
                            selectedConsole = console;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        showGeneral ? 'General Settings' : '${selectedConsole?.name ?? 'Console'} Settings',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),
                      _buildDownloadDirSetting(
                        context,
                        settings,
                        settingsNotifier,
                        showGeneral,
                        selectedConsole,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadDirSetting(
    BuildContext context,
    AppSettings settings,
    SettingsNotifier settingsNotifier,
    bool isGeneral,
    Console? console,
  ) {
    final currentDir = isGeneral
        ? settingsNotifier.getGeneralSetting<String>(AppSettings.downloadDir) ?? ''
        : (console != null
            ? (settingsNotifier.getConsoleSetting<String>(console.id, AppSettings.downloadDir) ??
                settingsNotifier.getGeneralSetting<String>(AppSettings.downloadDir) ??
                '')
            : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.folder_open, size: 20),
            const SizedBox(width: 8),
            Text(
              'Download Directory',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentDir.isEmpty ? 'No directory selected' : currentDir,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: currentDir.isEmpty
                      ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      final newDir = await settingsNotifier.selectDownloadDirectory();
                      if (newDir != null) {
                        if (isGeneral) {
                          await settingsNotifier.setGeneralSetting(AppSettings.downloadDir, newDir);
                        } else if (console != null) {
                          await settingsNotifier.setConsoleSetting(console.id, AppSettings.downloadDir, newDir);
                        }
                      }
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Choose Directory'),
                  ),
                  if (!isGeneral && console != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await settingsNotifier.setConsoleSetting(console.id, AppSettings.downloadDir, null);
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text('Use General'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (!isGeneral && console != null) ...[
          const SizedBox(height: 8),
          Text(
            settingsNotifier.getConsoleSetting<String>(console.id, AppSettings.downloadDir) == null ? 'Using general settings' : 'Console-specific directory',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
          ),
        ],
      ],
    );
  }
}
