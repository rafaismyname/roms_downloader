import 'package:roms_downloader/models/game_metadata_model.dart';

class TitleMetadataParser {
  static final Map<String, String> _regionCodes = {
    'U': 'USA',
    'USA': 'USA',
    'US': 'USA',
    'E': 'Europe',
    'EUR': 'Europe',
    'Europe': 'Europe',
    'J': 'Japan',
    'JPN': 'Japan',
    'Japan': 'Japan',
    'A': 'Australia',
    'AUS': 'Australia',
    'Australia': 'Australia',
    'K': 'Korea',
    'KOR': 'Korea',
    'Korea': 'Korea',
    'C': 'China',
    'CHN': 'China',
    'China': 'China',
    'B': 'Brazil',
    'BRA': 'Brazil',
    'Brazil': 'Brazil',
    'F': 'France',
    'FRA': 'France',
    'France': 'France',
    'G': 'Germany',
    'GER': 'Germany',
    'Germany': 'Germany',
    'I': 'Italy',
    'ITA': 'Italy',
    'Italy': 'Italy',
    'S': 'Spain',
    'SPA': 'Spain',
    'Spain': 'Spain',
    'Sw': 'Sweden',
    'SWE': 'Sweden',
    'Sweden': 'Sweden',
    'N': 'Netherlands',
    'NLD': 'Netherlands',
    'Netherlands': 'Netherlands',
    'PD': 'Public Domain',
    'UE': 'USA/Europe',
    'JU': 'Japan/USA',
    'JE': 'Japan/Europe',
    'JUE': 'Japan/USA/Europe',
    'W': 'World',
    'World': 'World',
    'UK': 'UK',
    'Asia': 'Asia',
    'Taiwan': 'Taiwan',
    'R': 'Russia',
    'RUS': 'Russia',
    'Russia': 'Russia',
    'P': 'Portugal',
    'POR': 'Portugal',
    'Norway': 'Norway',
    'Denmark': 'Denmark',
    'Portugal': 'Portugal',
    'Poland': 'Europe',
    'Greece': 'Europe',
    'Scandinavia': 'Europe',
    'United Arab Emirates': 'Asia',
    'Canada': 'Canada',
    'Latin America': 'Latin America',
    'India': 'Asia',
    'United Kingdom': 'UK',
    'Hong Kong': 'China',
    'Unknown': 'Unknown',
  };

  static final Map<String, String> _languageCodes = {
    'En': 'English',
    'English': 'English',
    'Fr': 'French',
    'French': 'French',
    'De': 'German',
    'German': 'German',
    'Es': 'Spanish',
    'Spanish': 'Spanish',
    'It': 'Italian',
    'Italian': 'Italian',
    'Pt': 'Portuguese',
    'Portuguese': 'Portuguese',
    'Nl': 'Dutch',
    'Dutch': 'Dutch',
    'Sv': 'Swedish',
    'Swedish': 'Swedish',
    'Norwegian': 'Norwegian',
    'Da': 'Danish',
    'Danish': 'Danish',
    'Fi': 'Finnish',
    'Finnish': 'Finnish',
    'Ja': 'Japanese',
    'Japanese': 'Japanese',
    'Ko': 'Korean',
    'Korean': 'Korean',
    'Zh': 'Chinese',
    'Chinese': 'Chinese',
    'Ru': 'Russian',
    'Russian': 'Russian',
    'Pl': 'Polish',
    'Polish': 'Polish',
    'Cz': 'Czech',
    'Czech': 'Czech',
    'Hu': 'Hungarian',
    'Hungarian': 'Hungarian',
    'Tr': 'Turkish',
    'Turkish': 'Turkish',
    'Ar': 'Arabic',
    'Arabic': 'Arabic',
    'He': 'Hebrew',
    'Hebrew': 'Hebrew',
    'Th': 'Thai',
    'Thai': 'Thai',
  };

  static List<String> _splitRegions(String regionString) {
    return regionString.split('/').map((region) => region.trim()).where((region) => region.isNotEmpty).toList();
  }

  static final List<_PatternHandler> _patterns = [
    _PatternHandler(RegExp(r'\[!\]'), (match, context) => context.dumpQualities.add(DumpQuality.goodDump)),
    _PatternHandler(RegExp(r'\[b(\d*)\]'), (match, context) => context.dumpQualities.add(DumpQuality.badDump)),
    _PatternHandler(RegExp(r'\[o(\d*)\]'), (match, context) => context.dumpQualities.add(DumpQuality.overdump)),
    _PatternHandler(RegExp(r'\[h(\d*[A-Za-z]*)\]'), (match, context) => context.modifications.add(ModificationType.hack)),
    _PatternHandler(RegExp(r'\[t(\d*[A-Za-z]*)\]'), (match, context) => context.modifications.add(ModificationType.translation)),
    _PatternHandler(RegExp(r'\[a(\d*)\]'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\[f(\d*)\]'), (match, context) => context.modifications.add(ModificationType.fixed)),
    _PatternHandler(RegExp(r'\[T[+-][A-Za-z]*(\d*)\]'), (match, context) => context.modifications.add(ModificationType.trainer)),
    _PatternHandler(RegExp(r'^\d{5,8}\s*[-–]?\s*Disc(?:,|\b)', caseSensitive: false), (match, context) => context.romTypes.add(RomType.bios)),
    _PatternHandler(RegExp(r'^\d{5,8}\s*[-–]?\s*CAT(?:-|\b)', caseSensitive: false), (match, context) => context.romTypes.add(RomType.bios)),
    _PatternHandler(RegExp(r'^(?:DISC,\s*CAT)', caseSensitive: false), (match, context) => context.romTypes.add(RomType.bios)),
    _PatternHandler(RegExp(r'\[BIOS\]'), (match, context) => context.romTypes.add(RomType.bios)),
    _PatternHandler(RegExp(r'\[x\]'), (match, context) => context.dumpQualities.add(DumpQuality.badDump)),
    _PatternHandler(RegExp(r'\[p(\d*)\]'), (match, context) => context.distributionTypes.add(DistributionType.pirate)),
    _PatternHandler(RegExp(r'\[c\]'), (match, context) => context.modifications.add(ModificationType.fixed)),
    _PatternHandler(RegExp(r'\[CR [^\]]+\]'), (match, context) => context.distributionTypes.add(DistributionType.pirate)),
    _PatternHandler(RegExp(r'\[m(\d*)\]'), (match, context) => context.distributionTypes.add(DistributionType.multiCart)),
    _PatternHandler(RegExp(r'\[S\]'), (match, context) => context.categories.add('Save')),
    _PatternHandler(RegExp(r'\[(?:(?:SCPS|SCPM|SLPS|SLPM|SCUS|SLUS|SCES|SCED|SLES|SLED|PAPX|PBPX)-\d+)\]'), (match, context) => context.categories.add('Sony Code')),
    _PatternHandler(RegExp(r'\[.*-\d+.*\]'), (match, context) => context.categories.add('Product Code')),
    _PatternHandler(RegExp(r'\(M(\d+)\)'), (match, context) => context.distributionTypes.add(DistributionType.multiCart)),
    _PatternHandler(RegExp(r'\(Unl\)'), (match, context) => context.distributionTypes.add(DistributionType.unlicensed)),
    _PatternHandler(RegExp(r'\(Unlicensed\)'), (match, context) => context.distributionTypes.add(DistributionType.unlicensed)),
    _PatternHandler(RegExp(r'\(iam8bit\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(Animal Crossing\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(Piko Interactive\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(Capcom Town\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(e-Reader Edition\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(Kiosk\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(Switch\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(Retro-Bit\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(Retro-Bit Generations\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(Genesis Mini\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(Sega Channel\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\Classic(s)? Collection\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(LodgeNet\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(HAL Laboratory\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(Broke Studio\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(Metal Gear Solid Collection\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(The Cowabunga Collection\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(Switch Online\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(Wii Virtual Console\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(Wii U Virtual Console\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(GameCube\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(GameCube Edition\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(Limited Run Games\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(Strictly Limited Games\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(Columbus Circle\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(Sega Reactor\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(Evercade\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'\(Arcade\)'), (match, context) { context.distributionTypes.add(DistributionType.alternate); context.categories.add('Arcade'); }),
    _PatternHandler(RegExp(r'\(Debug\)'), (match, context) => context.modifications.add(ModificationType.hack)),
    _PatternHandler(RegExp(r'\(Save Data\)'), (match, context) { context.modifications.add(ModificationType.hack); context.categories.add('Save'); }),
    _PatternHandler(RegExp(r'\(PD\)'), (match, context) { context.distributionTypes.add(DistributionType.unlicensed); context.regions.add('Public Domain'); }),
    _PatternHandler(RegExp(r'\(Demo[^)]*\)'), (match, context) => context.romTypes.add(RomType.demo)),
    _PatternHandler(RegExp(r'\(Kiosk Demo\)'), (match, context) { context.romTypes.add(RomType.demo); context.categories.add('Kiosk'); }),
    _PatternHandler(RegExp(r'\(Wi-Fi Kiosk\)'), (match, context) { context.distributionTypes.add(DistributionType.alternate); context.categories.add('Kiosk'); }),
    _PatternHandler(RegExp(r'\(Auto Demo\)'), (match, context) => context.romTypes.add(RomType.demo)),
    _PatternHandler(RegExp(r'\(Tech Demo\)'), (match, context) => context.romTypes.add(RomType.demo)),
    _PatternHandler(RegExp(r'Demo Action Pack'), (match, context) => context.romTypes.add(RomType.demo)),
    _PatternHandler(RegExp(r'Demo Pack'), (match, context) => context.romTypes.add(RomType.demo)),
    _PatternHandler(RegExp(r'\(Sample\)'), (match, context) => context.romTypes.add(RomType.sample)),
    _PatternHandler(RegExp(r'\(Program\)'), (match, context) => context.modifications.add(ModificationType.hack)),
    _PatternHandler(RegExp(r'\(Proto[^)]*\)'), (match, context) => context.romTypes.add(RomType.proto)),
    _PatternHandler(RegExp(r'\(Prototype[^)]*\)'), (match, context) => context.romTypes.add(RomType.proto)),
    _PatternHandler(RegExp(r'\(Putative Proto\)'), (match, context) => context.romTypes.add(RomType.proto)),
    _PatternHandler(RegExp(r'\(Beta[^)]*\)'), (match, context) => context.romTypes.add(RomType.beta)),
    _PatternHandler(RegExp(r'\(Beta(?:[^)]*)?\)'), (match, context) => context.romTypes.add(RomType.beta)),
    _PatternHandler(RegExp(r'\(Alpha[^)]*\)'), (match, context) => context.romTypes.add(RomType.alpha)),
    _PatternHandler(RegExp(r'\(Preview\)'), (match, context) => context.romTypes.add(RomType.beta)),
    _PatternHandler(RegExp(r'\(Pre-Release\)'), (match, context) => context.romTypes.add(RomType.beta)),
    _PatternHandler(RegExp(r'\(Test Program\)'), (match, context) => context.romTypes.add(RomType.proto)),
    _PatternHandler(RegExp(r'Auto Erase Disc'), (match, context) => context.romTypes.add(RomType.bios)),
    _PatternHandler(RegExp(r'\(Final\)'), (match, context) => context.categories.add('Final')),
    _PatternHandler(RegExp(r'\(Gold\)'), (match, context) => context.categories.add('Gold Master')),
    _PatternHandler(RegExp(r'\(Master\)'), (match, context) => context.categories.add('Master')),
    _PatternHandler(RegExp(r'\((?:Rev|REV|rev) ([A-Z\d]+)\)'), (match, context) => context.revision = match.group(1) ?? '0'),
    _PatternHandler(RegExp(r'\((\d+)S\)'), (match, context) => context.revision = '${match.group(1)}S'),
    _PatternHandler(RegExp(r'\(Revised\)'), (match, context) => context.revision = '1'),
    _PatternHandler(RegExp(r'\(RE\)'), (match, context) => context.revision = '1'),
    _PatternHandler(RegExp(r'\(v([\d\.]+)\)'), (match, context) => context.revision = match.group(1) ?? '0'),
    _PatternHandler(RegExp(r'\(Version ([\d\.]+)\)', caseSensitive: false), (match, context) => context.revision = match.group(1) ?? '0'),
    _PatternHandler(RegExp(r'\(Disk ([A-Z\d]+)\)'), (match, context) => context.diskNumber = match.group(1)!),
    _PatternHandler(RegExp(r'\(Disc ([A-Z\d]+)\)'), (match, context) => context.diskNumber = match.group(1)!),
    _PatternHandler(RegExp(r'\[Disc ([A-Z\d]+)\]'), (match, context) => context.diskNumber = match.group(1)!),
    _PatternHandler(RegExp(r'\(Side ([AB])\)'), (match, context) => context.diskNumber = match.group(1)!),
    _PatternHandler(RegExp(r'\(Tape ([AB\d]+)\)'), (match, context) => context.diskNumber = match.group(1)!),
    _PatternHandler(RegExp(r'\(Cart ([AB\d]+)\)'), (match, context) => context.diskNumber = match.group(1)!),
    _PatternHandler(RegExp(r'\(Aftermarket\)'), (match, context) => context.distributionTypes.add(DistributionType.aftermarket)),
    _PatternHandler(RegExp(r'\(Homebrew\)'), (match, context) => context.distributionTypes.add(DistributionType.aftermarket)),
    _PatternHandler(RegExp(r'\(Pirate\)'), (match, context) => context.distributionTypes.add(DistributionType.pirate)),
    _PatternHandler(RegExp(r'\(Multicart[^)]*\)'), (match, context) => context.distributionTypes.add(DistributionType.multiCart)),
    _PatternHandler(RegExp(r'\(Multi[^)]*\)'), (match, context) => context.distributionTypes.add(DistributionType.multiCart)),
    _PatternHandler(RegExp(r'\(\d+[ -]?in[ -]?\d+\)'), (match, context) => context.distributionTypes.add(DistributionType.multiCart)),
    _PatternHandler(RegExp(r'\(Possible Proto\)'), (match, context) => context.romTypes.add(RomType.proto)),
    _PatternHandler(RegExp(r'\(Trainer\)'), (match, context) => context.modifications.add(ModificationType.trainer)),
    _PatternHandler(RegExp(r'\(Virtual Console\)'), (match, context) => context.distributionTypes.add(DistributionType.alternate)),
    _PatternHandler(RegExp(r'^\d+\.\d+\s+IDU.*', caseSensitive: false), (match, context) => context.romTypes.add(RomType.bios)),
    _PatternHandler(RegExp(r'^Cleaning Kit for .+', caseSensitive: false), (match, context) => context.romTypes.add(RomType.bios)),
    _PatternHandler(RegExp(r'Test Cartridge', caseSensitive: false), (match, context) => context.romTypes.add(RomType.bios)),
    _PatternHandler(RegExp(r'\(SGB Enhanced\)'), (match, context) => context.categories.add('SGB Enhanced')),
    _PatternHandler(RegExp(r'\(NKit[^)]*\)'), (match, context) => context.categories.add('NKit')),
    _PatternHandler(RegExp(r'\(RVZ[^)]*\)'), (match, context) => context.categories.add('RVZ')),
    _PatternHandler(RegExp(r'\(GDI\)'), (match, context) => context.categories.add('GDI')),
    _PatternHandler(RegExp(r'\(CDI\)'), (match, context) => context.categories.add('CDI')),
    _PatternHandler(RegExp(r'\(NDSi Enhanced\)'), (match, context) => context.categories.add('Enhanced')),
    _PatternHandler(RegExp(r'\(Decrypted\)'), (match, context) => context.categories.add('Decrypted')),
    _PatternHandler(RegExp(r'\(Encrypted\)'), (match, context) => context.categories.add('Encrypted')),
    _PatternHandler(RegExp(r'\(NTSC\)'), (match, context) => context.categories.add('NTSC')),
    _PatternHandler(RegExp(r'\(PAL\)'), (match, context) => context.categories.add('PAL')),
    _PatternHandler(RegExp(r'\(SECAM\)'), (match, context) => context.categories.add('SECAM')),
    _PatternHandler(RegExp(r'\(50Hz\)'), (match, context) => context.categories.add('50Hz')),
    _PatternHandler(RegExp(r'\(60Hz\)'), (match, context) => context.categories.add('60Hz')),
    _PatternHandler(RegExp(r'\(Color\)'), (match, context) => context.categories.add('Color')),
    _PatternHandler(RegExp(r'\(Colour\)'), (match, context) => context.categories.add('Color')),
    _PatternHandler(RegExp(r'\(Mono\)'), (match, context) => context.categories.add('Mono')),
    _PatternHandler(RegExp(r'\(1 Player\)'), (match, context) => context.categories.add('1 Player')),
    _PatternHandler(RegExp(r'\(2 Players?\)'), (match, context) => context.categories.add('2 Players')),
    _PatternHandler(RegExp(r'\((\d+) Players?\)'), (match, context) => context.categories.add('${match.group(1)} Players')),
    _PatternHandler(RegExp(r'\(Multiplayer\)'), (match, context) => context.categories.add('Multiplayer')),
    _PatternHandler(RegExp(r'\(Cooperative\)'), (match, context) => context.categories.add('Cooperative')),
    _PatternHandler(RegExp(r'\(Co-op\)'), (match, context) => context.categories.add('Cooperative')),
    _PatternHandler(RegExp(r'\(Action Replay\)'), (match, context) => context.categories.add('Action Replay')),
    _PatternHandler(RegExp(r'\(Game Genie\)'), (match, context) => context.categories.add('Game Genie')),
    _PatternHandler(RegExp(r'\(Save States\)'), (match, context) => context.categories.add('Save States')),
    _PatternHandler(RegExp(r'\(High Score Save\)'), (match, context) => context.categories.add('High Score Save')),
    _PatternHandler(RegExp(r'\(Password Save\)'), (match, context) => context.categories.add('Password Save')),
    _PatternHandler(RegExp(r'\(Battery Save\)'), (match, context) => context.categories.add('Battery Save')),
    _PatternHandler(RegExp(r'\(SRAM\)'), (match, context) => context.categories.add('SRAM')),
    _PatternHandler(RegExp(r'\(EEPROM\)'), (match, context) => context.categories.add('EEPROM')),
    _PatternHandler(RegExp(r'\(Flash\)'), (match, context) => context.categories.add('Flash')),
    _PatternHandler(RegExp(r'\(Rumble\)'), (match, context) => context.categories.add('Rumble')),
    _PatternHandler(RegExp(r'\(Competition Cart\)'), (match, context) => context.categories.add('Competition')),
    _PatternHandler(RegExp(r'\(Competition Cart, Nintendo Power mail-order\)'), (match, context) => context.categories.add('Competition')),
    _PatternHandler(RegExp(r'\(Tilt Sensor\)'), (match, context) => context.categories.add('Tilt Sensor')),
    _PatternHandler(RegExp(r'\(Light Sensor\)'), (match, context) => context.categories.add('Light Sensor')),
    _PatternHandler(RegExp(r'\(Gyroscope\)'), (match, context) => context.categories.add('Gyroscope')),
    _PatternHandler(RegExp(r'\(Touch\)'), (match, context) => context.categories.add('Touch')),
    _PatternHandler(RegExp(r'\(Voice\)'), (match, context) => context.categories.add('Voice')),
    _PatternHandler(RegExp(r'\(GB Compatible\)'), (match, context) => context.categories.add('GB Compatible')),
    _PatternHandler(RegExp(r'\(Camera\)'), (match, context) => context.categories.add('Camera')),
    _PatternHandler(RegExp(r'\(PRG\d+\)'), (match, context) => context.categories.add('PRG Version')),
  ];

  static final RegExp _regionPattern = RegExp(r'\(([^)]+)\)');
  static final RegExp _htmlEntitiesPattern = RegExp(r'&(?:amp|lt|gt|quot|#39|nbsp);');
  static final RegExp _whitespacePattern = RegExp(r'\s+');
  static final RegExp _extensionPattern = RegExp(r'\.[a-zA-Z0-9]+$');
  static final RegExp _theCommaPattern = RegExp(r', The - ');
  static final RegExp _theEndingPattern = RegExp(r', The$');
  static final RegExp _underscoreDashPattern = RegExp(r'[_-]');

  static final Map<String, String> _htmlEntities = {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&nbsp;': ' ',
  };

  static GameMetadata parseRomTitle(String title) {
    final context = _ParseContext();
    
    String displayTitle = title.replaceAll(_extensionPattern, '');

    final List<int> matchPositions = [];

    for (int i = 0; i < _patterns.length; i++) {
      final pattern = _patterns[i];
      final matches = pattern.regex.allMatches(displayTitle);
      for (final match in matches) {
        pattern.handler(match, context);
        matchPositions.add(match.start);
        matchPositions.add(match.end);
      }
    }

    matchPositions.sort();
    final buffer = StringBuffer();
    int lastEnd = 0;
    for (int i = 0; i < matchPositions.length; i += 2) {
      if (i + 1 < matchPositions.length) {
        buffer.write(displayTitle.substring(lastEnd, matchPositions[i]));
        lastEnd = matchPositions[i + 1];
      }
    }
    buffer.write(displayTitle.substring(lastEnd));
    displayTitle = buffer.toString();

    final regionMatches = _regionPattern.allMatches(displayTitle).toList();
    final List<int> regionMatchPositions = [];

    for (final match in regionMatches) {
      final content = match.group(1)!;
      final parts = content.split(RegExp(r'[,+&/]'));

      bool isRegionOrLanguage = false;

      for (final part in parts) {
        final trimmedPart = part.trim();
        if (trimmedPart.isNotEmpty) {
          final regionValue = _regionCodes[trimmedPart];
          if (regionValue != null) {
            final splitRegions = _splitRegions(regionValue);
            context.regions.addAll(splitRegions);
            isRegionOrLanguage = true;
          } else if (_regionCodes.containsValue(trimmedPart)) {
            final splitRegions = _splitRegions(trimmedPart);
            context.regions.addAll(splitRegions);
            isRegionOrLanguage = true;
          }
          
          final languageValue = _languageCodes[trimmedPart];
          if (languageValue != null) {
            context.languages.add(languageValue);
            isRegionOrLanguage = true;
          } else if (_languageCodes.containsValue(trimmedPart)) {
            context.languages.add(trimmedPart);
            isRegionOrLanguage = true;
          }
        }
      }

      if (isRegionOrLanguage) {
        regionMatchPositions.add(match.start);
        regionMatchPositions.add(match.end);
      }
    }

    if (regionMatchPositions.isNotEmpty) {
      regionMatchPositions.sort();
      final buffer = StringBuffer();
      int lastEnd = 0;
      for (int i = 0; i < regionMatchPositions.length; i += 2) {
        if (i + 1 < regionMatchPositions.length) {
          buffer.write(displayTitle.substring(lastEnd, regionMatchPositions[i]));
          lastEnd = regionMatchPositions[i + 1];
        }
      }
      buffer.write(displayTitle.substring(lastEnd));
      displayTitle = buffer.toString();
    }

    final regionToLanguage = {
      'USA': 'English',
      'UK': 'English',
      'Australia': 'English',
      'Canada': 'English',
      'Europe': 'English',
      'France': 'French',
      'Germany': 'German',
      'Spain': 'Spanish',
      'Italy': 'Italian',
      'Portugal': 'Portuguese',
      'Netherlands': 'Dutch',
      'Sweden': 'Swedish',
      'Brazil': 'Portuguese',
      'Russia': 'Russian',
      'Japan': 'Japanese',
      'Korea': 'Korean',
      'China': 'Chinese',
      'Taiwan': 'Chinese',
      'Poland': 'Polish',
      'Latin America': 'Spanish',
    };

    final languageToRegion = {
      'English': 'USA',
      'French': 'France',
      'German': 'Germany',
      'Spanish': 'Spain',
      'Italian': 'Italy',
      'Portuguese': 'Portugal',
      'Dutch': 'Netherlands',
      'Swedish': 'Sweden',
      'Norwegian': 'Europe',
      'Danish': 'Europe',
      'Finnish': 'Europe',
      'Japanese': 'Japan',
      'Korean': 'Korea',
      'Chinese': 'China',
      'Russian': 'Russia',
      'Polish': 'Europe',
      'Czech': 'Europe',
      'Hungarian': 'Europe',
      'Turkish': 'Europe',
      'Arabic': 'Asia',
      'Hebrew': 'Asia',
      'Thai': 'Asia',
    };

    if (context.languages.isEmpty && context.regions.isNotEmpty) {
      for (final region in context.regions) {
        final language = regionToLanguage[region];
        if (language != null && !context.languages.contains(language)) {
          context.languages.add(language);
        }
      }
    }

    if (context.regions.isEmpty && context.languages.isNotEmpty) {
      for (final language in context.languages) {
        final region = languageToRegion[language];
        if (region != null && !context.regions.contains(region)) {
          context.regions.add(region);
        }
      }
    }

    displayTitle = displayTitle.replaceAllMapped(_htmlEntitiesPattern, (match) {
      return _htmlEntities[match.group(0)] ?? match.group(0)!;
    });

    displayTitle = displayTitle.replaceAll(_whitespacePattern, ' ').trim();

    if (_theCommaPattern.hasMatch(displayTitle)) {
      final parts = displayTitle.split(', The - ');
      displayTitle = 'The ${parts[0]} - ${parts[1]}';
    } else if (_theEndingPattern.hasMatch(displayTitle)) {
      displayTitle = 'The ${displayTitle.substring(0, displayTitle.length - 5)}';
    }

    if (displayTitle.isEmpty && context.romTypes.contains(RomType.bios)) {
      final filename = title.substring(0, title.lastIndexOf('.'));
      displayTitle = filename.replaceAll(_underscoreDashPattern, ' ').trim();
    }

    return GameMetadata(
      displayTitle: displayTitle,
      dumpQualities: context.dumpQualities,
      romTypes: context.romTypes,
      modifications: context.modifications,
      distributionTypes: context.distributionTypes,
      revision: context.revision,
      diskNumber: context.diskNumber,
      regions: context.regions,
      languages: context.languages,
      categories: context.categories,
    );
  }
}

class _PatternHandler {
  final RegExp regex;
  final void Function(Match, _ParseContext) handler;
  
  const _PatternHandler(this.regex, this.handler);
}

class _ParseContext {
  final Set<DumpQuality> dumpQualities = {};
  final Set<RomType> romTypes = {};
  final Set<ModificationType> modifications = {};
  final Set<DistributionType> distributionTypes = {};
  String revision = '';
  String diskNumber = '';
  final List<String> regions = [];
  final List<String> languages = [];
  final List<String> categories = [];
}
