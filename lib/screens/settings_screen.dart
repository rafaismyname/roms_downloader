import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';
import 'package:roms_downloader/providers/settings_provider.dart';
import 'package:roms_downloader/widgets/settings/settings_tab_selector.dart';
import 'package:roms_downloader/widgets/settings/settings_content.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final String? initialConsoleId;

  const SettingsScreen({super.key, this.initialConsoleId});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Console? selectedConsole;
  late bool showGeneral;

  @override
  void initState() {
    super.initState();
    showGeneral = widget.initialConsoleId == null;
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    if (widget.initialConsoleId != null && selectedConsole == null && appState.consoles.isNotEmpty) {
      selectedConsole = appState.consoles.firstWhere(
        (c) => c.id == widget.initialConsoleId,
        orElse: () => appState.consoles.first,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(fontSize: 16),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 40,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsTabSelector(
              showGeneral: showGeneral,
              selectedConsole: selectedConsole,
              consoles: appState.consoles,
              onTabChanged: (isGeneral) {
                setState(() {
                  showGeneral = isGeneral;
                  if (!showGeneral && selectedConsole == null) {
                    selectedConsole = appState.consoles.isNotEmpty ? appState.consoles.first : null;
                  }
                });
              },
              onConsoleSelected: (console) {
                setState(() {
                  selectedConsole = console;
                });
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SettingsContent(
                selectedConsole: showGeneral ? null : selectedConsole,
                settingsNotifier: settingsNotifier,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
