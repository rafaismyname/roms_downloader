import 'dart:io';

class HandheldDetector {
  static bool _isHandheld = false;
  static String? _detectedPlatform;
  static String? _defaultRomsPath;

  /// Initialize handheld detection
  static Future<void> initialize() async {
    if (Platform.isLinux) {
      await _detectLinuxHandheld();
    }
  }

  /// Check if running on a handheld device
  static bool get isHandheld => _isHandheld;

  /// Get the detected handheld platform
  static String? get detectedPlatform => _detectedPlatform;

  /// Get the default ROMs path for this platform
  static String? get defaultRomsPath => _defaultRomsPath;

  /// Detect Linux handheld environments
  static Future<void> _detectLinuxHandheld() async {
    try {
      // Check for environment variables set by our startup script
      final handheldMode = Platform.environment['FLUTTER_HANDHELD_MODE'];
      final defaultPath = Platform.environment['ROMS_DEFAULT_PATH'];

      if (handheldMode == '1') {
        _isHandheld = true;
        _defaultRomsPath = defaultPath;
      }

      // Check for common handheld Linux distro indicators
      final indicators = [
        '/storage/.config', // Batocera
        '/storage/roms',    // Batocera
        '/roms',           // RockNIX/JELOS
        '/storage',        // General retro distros
        '/opt/retropie',   // RetroPie
        '/userdata',       // Batocera userdata
      ];

      for (final indicator in indicators) {
        if (await Directory(indicator).exists()) {
          _isHandheld = true;
          
          // Determine platform based on file structure
          if (await Directory('/storage/roms').exists()) {
            _detectedPlatform = 'Batocera';
            _defaultRomsPath ??= '/storage/roms';
          } else if (await Directory('/roms').exists()) {
            _detectedPlatform = 'RockNIX/JELOS';
            _defaultRomsPath ??= '/roms';
          } else if (await Directory('/opt/retropie').exists()) {
            _detectedPlatform = 'RetroPie';
            _defaultRomsPath ??= '/home/pi/RetroPie/roms';
          }
          break;
        }
      }

      // Check for Steam Deck
      if (await File('/etc/os-release').exists()) {
        final osRelease = await File('/etc/os-release').readAsString();
        if (osRelease.contains('SteamOS') || osRelease.contains('steam')) {
          _isHandheld = true;
          _detectedPlatform = 'Steam Deck';
          _defaultRomsPath ??= '/home/deck/ROMs';
        }
      }

      // Check for handheld-specific hardware
      if (await File('/proc/device-tree/model').exists()) {
        final model = await File('/proc/device-tree/model').readAsString();
        if (model.contains('ANBERNIC') || 
            model.contains('Powkiddy') || 
            model.contains('GPD') ||
            model.contains('AYA') ||
            model.contains('ONEXPLAYER')) {
          _isHandheld = true;
          _detectedPlatform ??= 'Handheld Device';
        }
      }
    } catch (e) {
      // Fail silently - detection is optional
      print('Handheld detection failed: $e');
    }
  }

  /// Get handheld-optimized settings
  static Map<String, dynamic> getOptimizedSettings() {
    if (!_isHandheld) return {};

    return {
      'touch_friendly': true,
      'larger_buttons': true,
      'auto_scroll': true,
      'low_memory_mode': true,
      'default_download_path': _defaultRomsPath,
      'platform_name': _detectedPlatform,
    };
  }

  /// Check if we should use touch-friendly UI
  static bool get shouldUseTouchFriendlyUI => _isHandheld;

  /// Get recommended memory settings for handheld devices
  static Map<String, int> get memorySettings => _isHandheld ? {
    'max_concurrent_downloads': 2,
    'cache_size_mb': 50,
    'image_cache_size': 100,
  } : {
    'max_concurrent_downloads': 4,
    'cache_size_mb': 200,
    'image_cache_size': 500,
  };
}
