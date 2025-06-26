import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';
import 'package:roms_downloader/widgets/header/controls.dart';
import 'package:roms_downloader/widgets/game_list/game_list.dart';
import 'package:roms_downloader/widgets/footer/footer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final appStateNotifier = ref.read(appStateProvider.notifier);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ROMs Downloader',
          style: TextStyle(
            fontSize: isLandscape ? 15 : 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        toolbarHeight: isLandscape ? 30 : kToolbarHeight,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Controls(
              consoles: appState.consoles,
              selectedConsole: appState.selectedConsole,
              downloadDir: appState.downloadDir,
              onConsoleSelect: appStateNotifier.selectConsole,
              onDirectoryChange: appStateNotifier.handleDirectoryChange,
            ),
            Expanded(
              child: appState.loading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading...'),
                        ],
                      ),
                    )
                  : GameList(),
            ),
            Footer(),
          ],
        ),
      ),
    );
  }
}
