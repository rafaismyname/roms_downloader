import 'package:roms_downloader/models/game_metadata_model.dart';

class RomParser {
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
    'UK': 'United Kingdom',
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

  static GameMetadata parseRomTitle(String title) {
    String displayTitle = title;
    Set<DumpQuality> dumpQualities = {};
    Set<RomType> romTypes = {};
    Set<ModificationType> modifications = {};
    Set<DistributionType> distributionTypes = {};
    String revision = '';
    String diskNumber = '';
    List<String> regions = [];
    List<String> languages = [];
    List<String> categories = [];

    displayTitle = title.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');

    final patterns = <RegExp, Function(Match)>{
      RegExp(r'\[!\]'): (match) => dumpQualities.add(DumpQuality.goodDump),
      RegExp(r'\[b(\d*)\]'): (match) => dumpQualities.add(DumpQuality.badDump),
      RegExp(r'\[o(\d*)\]'): (match) => dumpQualities.add(DumpQuality.overdump),
      RegExp(r'\[h(\d*[A-Za-z]*)\]'): (match) => modifications.add(ModificationType.hack),
      RegExp(r'\[t(\d*[A-Za-z]*)\]'): (match) => modifications.add(ModificationType.translation),
      RegExp(r'\[a(\d*)\]'): (match) => distributionTypes.add(DistributionType.alternate),
      RegExp(r'\[f(\d*)\]'): (match) => modifications.add(ModificationType.fixed),
      RegExp(r'\[T[+-][A-Za-z]*(\d*)\]'): (match) => modifications.add(ModificationType.trainer),
      RegExp(r'\[x\]'): (match) => dumpQualities.add(DumpQuality.badDump),
      RegExp(r'\[p(\d*)\]'): (match) => distributionTypes.add(DistributionType.pirate),
      RegExp(r'\[c\]'): (match) => modifications.add(ModificationType.fixed),
      RegExp(r'\[CR [^\]]+\]'): (match) => distributionTypes.add(DistributionType.pirate),
      RegExp(r'\[m(\d*)\]'): (match) => distributionTypes.add(DistributionType.multiCart),
      RegExp(r'\[S\]'): (match) => categories.add('Save'),
      RegExp(r'\[SCES-\d+\]'): (match) => categories.add('Sony Code'),
      RegExp(r'\[SLUS-\d+\]'): (match) => categories.add('Sony Code'),
      RegExp(r'\[SCUS-\d+\]'): (match) => categories.add('Sony Code'),
      RegExp(r'\[.*-\d+.*\]'): (match) => categories.add('Product Code'),
      RegExp(r'\(M(\d+)\)'): (match) => distributionTypes.add(DistributionType.multiCart),
      RegExp(r'\(Unl\)'): (match) => distributionTypes.add(DistributionType.unlicensed),
      RegExp(r'\(Unlicensed\)'): (match) => distributionTypes.add(DistributionType.unlicensed),
      RegExp(r'\(PD\)'): (match) => {distributionTypes.add(DistributionType.unlicensed), regions.add('Public Domain')},
      RegExp(r'\(Demo[^)]*\)'): (match) => romTypes.add(RomType.demo),
      RegExp(r'\(Kiosk Demo\)'): (match) => {romTypes.add(RomType.demo), categories.add('Kiosk')},
      RegExp(r'\(Sample\)'): (match) => romTypes.add(RomType.sample),
      RegExp(r'\(Proto[^)]*\)'): (match) => romTypes.add(RomType.proto),
      RegExp(r'\(Prototype[^)]*\)'): (match) => romTypes.add(RomType.proto),
      RegExp(r'\(Beta[^)]*\)'): (match) => romTypes.add(RomType.beta),
      RegExp(r'\(Beta(?:[^)]*)?\)'): (match) => romTypes.add(RomType.beta),
      RegExp(r'\(Alpha[^)]*\)'): (match) => romTypes.add(RomType.alpha),
      RegExp(r'\(Preview\)'): (match) => romTypes.add(RomType.beta),
      RegExp(r'\(Pre-Release\)'): (match) => romTypes.add(RomType.beta),
      RegExp(r'\(Beta\)'): (match) => romTypes.add(RomType.beta),
      RegExp(r'\(Final\)'): (match) => categories.add('Final'),
      RegExp(r'\(Gold\)'): (match) => categories.add('Gold Master'),
      RegExp(r'\(Master\)'): (match) => categories.add('Master'),
      RegExp(r'\((?:Rev|REV|rev) ([A-Z\d]+)\)'): (match) => revision = match.group(1) ?? '0',
      RegExp(r'\(Revised\)'): (match) => revision = '0',
      RegExp(r'\(Disk ([A-Z\d]+)\)'): (match) => diskNumber = match.group(1)!,
      RegExp(r'\(Disc ([A-Z\d]+)\)'): (match) => diskNumber = match.group(1)!,
      RegExp(r'\[Disc ([A-Z\d]+)\]'): (match) => diskNumber = match.group(1)!,
      RegExp(r'\(Side ([AB])\)'): (match) => diskNumber = match.group(1)!,
      RegExp(r'\(Tape ([AB\d]+)\)'): (match) => diskNumber = match.group(1)!,
      RegExp(r'\(Cart ([AB\d]+)\)'): (match) => diskNumber = match.group(1)!,
      RegExp(r'\(Aftermarket\)'): (match) => distributionTypes.add(DistributionType.aftermarket),
      RegExp(r'\(Homebrew\)'): (match) => distributionTypes.add(DistributionType.aftermarket),
      RegExp(r'\(Pirate\)'): (match) => distributionTypes.add(DistributionType.pirate),
      RegExp(r'\(Multicart[^)]*\)'): (match) => distributionTypes.add(DistributionType.multiCart),
      RegExp(r'\(Multi[^)]*\)'): (match) => distributionTypes.add(DistributionType.multiCart),
      RegExp(r'\(\d+[ -]?in[ -]?\d+\)'): (match) => distributionTypes.add(DistributionType.multiCart),
      RegExp(r'\(Possible Proto\)'): (match) => romTypes.add(RomType.proto),
      RegExp(r'\(Trainer\)'): (match) => modifications.add(ModificationType.trainer),
      RegExp(r'\(SGB Enhanced\)'): (match) => categories.add('SGB Enhanced'),
      RegExp(r'\(NKit[^)]*\)'): (match) => categories.add('NKit'),
      RegExp(r'\(RVZ[^)]*\)'): (match) => categories.add('RVZ'),
      RegExp(r'\(CDI\)'): (match) => categories.add('CDI'),
      RegExp(r'\(GDI\)'): (match) => categories.add('GDI'),
      RegExp(r'\(Decrypted\)'): (match) => categories.add('Decrypted'),
      RegExp(r'\(Encrypted\)'): (match) => categories.add('Encrypted'),
      RegExp(r'\(NTSC\)'): (match) => categories.add('NTSC'),
      RegExp(r'\(PAL\)'): (match) => categories.add('PAL'),
      RegExp(r'\(SECAM\)'): (match) => categories.add('SECAM'),
      RegExp(r'\(50Hz\)'): (match) => categories.add('50Hz'),
      RegExp(r'\(60Hz\)'): (match) => categories.add('60Hz'),
      RegExp(r'\(Color\)'): (match) => categories.add('Color'),
      RegExp(r'\(Colour\)'): (match) => categories.add('Color'),
      RegExp(r'\(Mono\)'): (match) => categories.add('Mono'),
      RegExp(r'\(1 Player\)'): (match) => categories.add('1 Player'),
      RegExp(r'\(2 Players?\)'): (match) => categories.add('2 Players'),
      RegExp(r'\((\d+) Players?\)'): (match) => categories.add('${match.group(1)} Players'),
      RegExp(r'\(Multiplayer\)'): (match) => categories.add('Multiplayer'),
      RegExp(r'\(Cooperative\)'): (match) => categories.add('Cooperative'),
      RegExp(r'\(Co-op\)'): (match) => categories.add('Cooperative'),
      RegExp(r'\(Action Replay\)'): (match) => categories.add('Action Replay'),
      RegExp(r'\(Game Genie\)'): (match) => categories.add('Game Genie'),
      RegExp(r'\(Save States\)'): (match) => categories.add('Save States'),
      RegExp(r'\(High Score Save\)'): (match) => categories.add('High Score Save'),
      RegExp(r'\(Password Save\)'): (match) => categories.add('Password Save'),
      RegExp(r'\(Battery Save\)'): (match) => categories.add('Battery Save'),
      RegExp(r'\(SRAM\)'): (match) => categories.add('SRAM'),
      RegExp(r'\(EEPROM\)'): (match) => categories.add('EEPROM'),
      RegExp(r'\(Flash\)'): (match) => categories.add('Flash'),
      RegExp(r'\(Rumble\)'): (match) => categories.add('Rumble'),
      RegExp(r'\(Tilt Sensor\)'): (match) => categories.add('Tilt Sensor'),
      RegExp(r'\(Light Sensor\)'): (match) => categories.add('Light Sensor'),
      RegExp(r'\(Gyroscope\)'): (match) => categories.add('Gyroscope'),
      RegExp(r'\(Touch\)'): (match) => categories.add('Touch'),
      RegExp(r'\(Voice\)'): (match) => categories.add('Voice'),
      RegExp(r'\(Camera\)'): (match) => categories.add('Camera'),
      RegExp(r'\(PRG\d+\)'): (match) => categories.add('PRG Version'),
    };

    for (final entry in patterns.entries) {
      displayTitle = displayTitle.replaceAllMapped(entry.key, (match) {
        entry.value(match);
        return '';
      });
    }

    final regionPattern = RegExp(r'\(([^)]+)\)');
    final remainingMatches = regionPattern.allMatches(displayTitle).toList();

    for (final match in remainingMatches) {
      final content = match.group(1)!;
      final parts = content.split(RegExp(r'[,+&/]')).map((e) => e.trim()).toList();

      bool isRegionOrLanguage = false;

      for (final part in parts) {
        if (_regionCodes.containsKey(part)) {
          final regionValue = _regionCodes[part]!;
          final splitRegions = _splitRegions(regionValue);
          regions.addAll(splitRegions);
          isRegionOrLanguage = true;
        } else if (_regionCodes.containsValue(part)) {
          final splitRegions = _splitRegions(part);
          regions.addAll(splitRegions);
          isRegionOrLanguage = true;
        } else if (_languageCodes.containsKey(part)) {
          languages.add(_languageCodes[part]!);
          isRegionOrLanguage = true;
        } else if (_languageCodes.containsValue(part)) {
          languages.add(part);
          isRegionOrLanguage = true;
        }
      }

      if (isRegionOrLanguage) {
        displayTitle = displayTitle.replaceAll(match.group(0)!, '');
      }
    }

    final regionToLanguage = {
      'USA': 'English',
      'United Kingdom': 'English',
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

    if (languages.isEmpty && regions.isNotEmpty) {
      for (final region in regions) {
        if (regionToLanguage.containsKey(region)) {
          final language = regionToLanguage[region]!;
          if (!languages.contains(language)) {
            languages.add(language);
          }
        }
      }
    }

    if (regions.isEmpty && languages.isNotEmpty) {
      for (final language in languages) {
        if (languageToRegion.containsKey(language)) {
          final region = languageToRegion[language]!;
          if (!regions.contains(region)) {
            regions.add(region);
          }
        }
      }
    }

    displayTitle = displayTitle
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');

    displayTitle = displayTitle.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (displayTitle.contains(', The - ')) {
      final parts = displayTitle.split(', The - ');
      displayTitle = 'The ${parts[0]} - ${parts[1]}';
    } else if (displayTitle.endsWith(', The')) {
      displayTitle = 'The ${displayTitle.substring(0, displayTitle.length - 5)}';
    }

    return GameMetadata(
      displayTitle: displayTitle,
      dumpQualities: dumpQualities,
      romTypes: romTypes,
      modifications: modifications,
      distributionTypes: distributionTypes,
      revision: revision,
      diskNumber: diskNumber,
      regions: regions,
      languages: languages,
      categories: categories,
    );
  }
}
