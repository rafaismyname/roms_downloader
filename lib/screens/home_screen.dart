import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/app_state_model.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';
import 'package:roms_downloader/widgets/header/header.dart';
import 'package:roms_downloader/widgets/game_list/game_list.dart';
import 'package:roms_downloader/widgets/game_grid/game_grid.dart';
import 'package:roms_downloader/widgets/footer/footer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final FocusNode _mainFocusNode = FocusNode();

  @override
  void dispose() {
    _mainFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final appStateNotifier = ref.read(appStateProvider.notifier);

    // Request focus when content is loaded and we're not loading anymore
    if (Platform.isLinux && !appState.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mainFocusNode.canRequestFocus && !_mainFocusNode.hasFocus && FocusManager.instance.primaryFocus == null) {
          _mainFocusNode.requestFocus();
        }
      });
    }

    return Scaffold(
      body: Column(
        children: [
          Header(
            consoles: appState.consolesList,
            selectedConsole: appState.selectedConsole,
            onConsoleSelect: appStateNotifier.selectConsole,
          ),
          Expanded(
            child: Focus(
              focusNode: _mainFocusNode,
              autofocus: Platform.isLinux,
              child: appState.loading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading (this can take a while)...'),
                        ],
                      ),
                    )
                  : appState.viewMode == ViewMode.grid
                      ? GameGrid()
                      : GameList(),
            ),
          ),
          Footer(),
        ],
      ),
    );
  }
}
