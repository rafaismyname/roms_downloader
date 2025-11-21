import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';
import 'package:roms_downloader/screens/home_screen.dart';
import 'package:roms_downloader/widgets/common/gamepad_listener.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class RomsDownloaderApp extends ConsumerWidget {
  const RomsDownloaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appStateProvider.select((s) => s.themeMode));
    
    return GamepadListener(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'ROMs Downloader',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF646CFF),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: Color(0xFF213547),
            elevation: 0,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF747BFF),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        ),
        themeMode: themeMode,
        home: const HomeScreen(),
      ),
    );
  }
}
