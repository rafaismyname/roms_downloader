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
    const bool disableAnimations = bool.fromEnvironment('DISABLE_ANIMATIONS');

    final pageTransitionsTheme = disableAnimations
        ? const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: NoTransitionsBuilder(),
              TargetPlatform.iOS: NoTransitionsBuilder(),
              TargetPlatform.linux: NoTransitionsBuilder(),
              TargetPlatform.macOS: NoTransitionsBuilder(),
              TargetPlatform.windows: NoTransitionsBuilder(),
            },
          )
        : null;

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
          focusColor: Colors.blueAccent.withValues(alpha: 0.2),
          highlightColor: Colors.blueAccent.withValues(alpha: 0.1),
          hoverColor: Colors.blueAccent.withValues(alpha: 0.05),
          listTileTheme: ListTileThemeData(
            selectedColor: const Color(0xFF646CFF),
            selectedTileColor: const Color(0xFF646CFF).withValues(alpha: 0.1),
          ),
          pageTransitionsTheme: pageTransitionsTheme,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF747BFF),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF1A1A1A),
          focusColor: Colors.blueAccent.withValues(alpha: 0.4),
          highlightColor: Colors.blueAccent.withValues(alpha: 0.2),
          hoverColor: Colors.blueAccent.withValues(alpha: 0.1),
          listTileTheme: ListTileThemeData(
            selectedColor: const Color(0xFF747BFF),
            selectedTileColor: const Color(0xFF747BFF).withValues(alpha: 0.1),
          ),
          pageTransitionsTheme: pageTransitionsTheme,
        ),
        themeMode: themeMode,
        builder: (context, child) {
          final Widget finalChild = child ?? const SizedBox.shrink();

          if (disableAnimations) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: finalChild,
            );
          }

          return finalChild;
        },
        home: const HomeScreen(),
      ),
    );
  }
}

class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
