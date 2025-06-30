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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ROMs Downloader',
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        toolbarHeight: 50,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Controls(
              consoles: appState.consoles,
              selectedConsole: appState.selectedConsole,
              onConsoleSelect: appStateNotifier.selectConsole,
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
