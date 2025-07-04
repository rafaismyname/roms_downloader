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

  static GameMetadata parseRomTitle(String title) {
    String normalizedTitle = title;
    String region = '';
    String language = '';
    String version = '';
    Set<DumpQuality> dumpQualities = {};
    Set<RomType> romTypes = {};
    Set<ModificationType> modifications = {};
    Set<DistributionType> distributionTypes = {};
    int revision = 0;
    String diskNumber = '';
    List<String> tags = [];

    String subtitle = '';
    String series = '';
    String publisher = '';
    String collection = '';
    String mediaType = '';
    String releaseDate = '';
    List<String> regions = [];
    List<String> languages = [];
    List<String> categories = [];

    normalizedTitle = title.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');

    final patterns = <RegExp, Function(Match)>{
      RegExp(r'\[!\]'): (match) {
        dumpQualities.add(DumpQuality.goodDump);
        tags.add('Good Dump');
      },
      RegExp(r'\[b(\d*)\]'): (match) {
        dumpQualities.add(DumpQuality.badDump);
        tags.add('Bad Dump');
      },
      RegExp(r'\[o(\d*)\]'): (match) {
        dumpQualities.add(DumpQuality.overdump);
        tags.add('Overdump');
      },
      RegExp(r'\[h(\d*[A-Za-z]*)\]'): (match) {
        modifications.add(ModificationType.hack);
        tags.add('Hack');
      },
      RegExp(r'\[t(\d*[A-Za-z]*)\]'): (match) {
        modifications.add(ModificationType.translation);
        tags.add('Translation');
      },
      RegExp(r'\[a(\d*)\]'): (match) {
        distributionTypes.add(DistributionType.alternate);
        tags.add('Alternate');
      },
      RegExp(r'\[f(\d*)\]'): (match) {
        modifications.add(ModificationType.fixed);
        tags.add('Fixed');
      },
      RegExp(r'\[T[+-][A-Za-z]*(\d*)\]'): (match) {
        modifications.add(ModificationType.trainer);
        tags.add('Trainer');
      },
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
      RegExp(r'\(Alpha[^)]*\)'): (match) => romTypes.add(RomType.alpha),
      RegExp(r'\(Preview\)'): (match) => romTypes.add(RomType.beta),
      RegExp(r'\(Pre-Release\)'): (match) => romTypes.add(RomType.beta),
      RegExp(r'\(Final\)'): (match) => categories.add('Final'),
      RegExp(r'\(Gold\)'): (match) => categories.add('Gold Master'),
      RegExp(r'\(Master\)'): (match) => categories.add('Master'),
      RegExp(r'\(V([\d.]+)\)'): (match) {
        version = match.group(1)!;
        tags.add('Version ${match.group(1)!}');
      },
      RegExp(r'\(Rev ([A-Z\d]+)\)'): (match) {
        final revValue = match.group(1)!;
        revision = int.tryParse(revValue) ?? 0;
        tags.add('Revision $revValue');
      },
      RegExp(r'\(REV ([A-Z\d]+)\)'): (match) {
        final revValue = match.group(1)!;
        revision = int.tryParse(revValue) ?? 0;
        tags.add('Revision $revValue');
      },
      RegExp(r'\(Disk ([A-Z\d]+)\)'): (match) {
        diskNumber = match.group(1)!;
        tags.add('Disk ${match.group(1)!}');
      },
      RegExp(r'\(Disc ([A-Z\d]+)\)'): (match) {
        diskNumber = match.group(1)!;
        tags.add('Disc ${match.group(1)!}');
      },
      RegExp(r'\[Disc ([A-Z\d]+)\]'): (match) {
        diskNumber = match.group(1)!;
        tags.add('Disc ${match.group(1)!}');
      },
      RegExp(r'\(Side ([AB])\)'): (match) => diskNumber = match.group(1)!,
      RegExp(r'\(Tape ([AB\d]+)\)'): (match) => diskNumber = match.group(1)!,
      RegExp(r'\(Cart ([AB\d]+)\)'): (match) => diskNumber = match.group(1)!,
      RegExp(r'\(\d{4}-\d{2}-\d{2}\)'): (match) => releaseDate = match.group(0)!.replaceAll(RegExp(r'[()]'), ''),
      RegExp(r'\((\d{4})\)'): (match) {
        releaseDate = match.group(1)!;
        tags.add('Year ${match.group(1)!}');
      },
      RegExp(r'\(SGB Enhanced\)'): (match) => {distributionTypes.add(DistributionType.enhanced), mediaType = 'SGB Enhanced'},
      RegExp(r'\(NKit[^)]*\)'): (match) => mediaType = 'NKit',
      RegExp(r'\(RVZ[^)]*\)'): (match) => mediaType = 'RVZ',
      RegExp(r'\(CDI\)'): (match) => mediaType = 'CDI',
      RegExp(r'\(GDI\)'): (match) => mediaType = 'GDI',
      RegExp(r'\(Decrypted\)'): (match) => mediaType = 'Decrypted',
      RegExp(r'\(Encrypted\)'): (match) => mediaType = 'Encrypted',
      RegExp(r'\(Aftermarket\)'): (match) => distributionTypes.add(DistributionType.aftermarket),
      RegExp(r'\(Homebrew\)'): (match) => distributionTypes.add(DistributionType.aftermarket),
      RegExp(r'\(Pirate\)'): (match) => distributionTypes.add(DistributionType.pirate),
      RegExp(r'\(Multicart[^)]*\)'): (match) => distributionTypes.add(DistributionType.multiCart),
      RegExp(r'\(Multi[^)]*\)'): (match) => distributionTypes.add(DistributionType.multiCart),
      RegExp(r'\(\d+[ -]?in[ -]?\d+\)'): (match) => distributionTypes.add(DistributionType.multiCart),
      RegExp(r'\(Possible Proto\)'): (match) => romTypes.add(RomType.proto),
      RegExp(r'\(Trainer\)'): (match) => modifications.add(ModificationType.trainer),
      RegExp(r'\([^)]*Collection[^)]*\)'): (match) => {collection = match.group(0)!.replaceAll(RegExp(r'[()]'), ''), categories.add('Collection')},
      RegExp(r'\([^)]*Edition[^)]*\)'): (match) =>
          {distributionTypes.add(DistributionType.specialEdition), collection = match.group(0)!.replaceAll(RegExp(r'[()]'), ''), categories.add('Special Edition')},
      RegExp(r'\([^)]*Pack[^)]*\)'): (match) => {collection = match.group(0)!.replaceAll(RegExp(r'[()]'), ''), categories.add('Pack')},
      RegExp(r'\([^)]*Bundle[^)]*\)'): (match) => {collection = match.group(0)!.replaceAll(RegExp(r'[()]'), ''), categories.add('Bundle')},
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
      normalizedTitle = normalizedTitle.replaceAllMapped(entry.key, (match) {
        entry.value(match);
        return '';
      });
    }

    final regionPattern = RegExp(r'\(([^)]+)\)');
    final remainingMatches = regionPattern.allMatches(normalizedTitle).toList();

    for (final match in remainingMatches) {
      final content = match.group(1)!;
      final parts = content.split(RegExp(r'[,+&/]')).map((e) => e.trim()).toList();

      bool isRegionOrLanguage = false;

      for (final part in parts) {
        if (_regionCodes.containsKey(part)) {
          regions.add(_regionCodes[part]!);
          isRegionOrLanguage = true;
        } else if (_regionCodes.containsValue(part)) {
          regions.add(part);
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
        normalizedTitle = normalizedTitle.replaceAll(match.group(0)!, '');
      }
    }

    // Additional region detection for titles without parentheses
    if (regions.isEmpty) {
      // Check for region keywords in the title itself
      final regionKeywords = {
        'USA': 'USA',
        'Europe': 'Europe',
        'European': 'Europe',
        'Japan': 'Japan',
        'Japanese': 'Japan',
        'Korea': 'Korea',
        'Korean': 'Korea',
        'China': 'China',
        'Chinese': 'China',
        'Brazil': 'Brazil',
        'Australian': 'Australia',
        'Canada': 'Canada',
        'Canadian': 'Canada',
        'World': 'World',
        'Global': 'World',
        'International': 'World',
        'Asia': 'Asia',
        'Asian': 'Asia',
      };

      for (final entry in regionKeywords.entries) {
        if (normalizedTitle.toLowerCase().contains(entry.key.toLowerCase()) || subtitle.toLowerCase().contains(entry.key.toLowerCase())) {
          regions.add(entry.value);
          break;
        }
      }
    }

    // Enhanced language detection for standalone language codes
    if (languages.isEmpty) {
      final languagePatterns = [
        RegExp(r'\b(En|English)\b', caseSensitive: false),
        RegExp(r'\b(Fr|French|Français)\b', caseSensitive: false),
        RegExp(r'\b(De|German|Deutsch)\b', caseSensitive: false),
        RegExp(r'\b(Es|Spanish|Español)\b', caseSensitive: false),
        RegExp(r'\b(It|Italian|Italiano)\b', caseSensitive: false),
        RegExp(r'\b(Ja|Japanese|日本語)\b', caseSensitive: false),
        RegExp(r'\b(Ko|Korean|한국어)\b', caseSensitive: false),
        RegExp(r'\b(Pt|Portuguese|Português)\b', caseSensitive: false),
        RegExp(r'\b(Nl|Dutch|Nederlands)\b', caseSensitive: false),
        RegExp(r'\b(Sv|Swedish|Svenska)\b', caseSensitive: false),
        RegExp(r'\b(Norwegian|Norsk)\b', caseSensitive: false),
        RegExp(r'\b(Da|Danish|Dansk)\b', caseSensitive: false),
        RegExp(r'\b(Fi|Finnish|Suomi)\b', caseSensitive: false),
      ];

      final languageMap = {
        'en': 'English',
        'english': 'English',
        'fr': 'French',
        'french': 'French',
        'français': 'French',
        'de': 'German',
        'german': 'German',
        'deutsch': 'German',
        'es': 'Spanish',
        'spanish': 'Spanish',
        'español': 'Spanish',
        'it': 'Italian',
        'italian': 'Italian',
        'italiano': 'Italian',
        'ja': 'Japanese',
        'japanese': 'Japanese',
        '日本語': 'Japanese',
        'ko': 'Korean',
        'korean': 'Korean',
        '한국어': 'Korean',
        'pt': 'Portuguese',
        'portuguese': 'Portuguese',
        'português': 'Portuguese',
        'nl': 'Dutch',
        'dutch': 'Dutch',
        'nederlands': 'Dutch',
        'sv': 'Swedish',
        'swedish': 'Swedish',
        'svenska': 'Swedish',
        'norwegian': 'Norwegian',
        'norsk': 'Norwegian',
        'da': 'Danish',
        'danish': 'Danish',
        'dansk': 'Danish',
        'fi': 'Finnish',
        'finnish': 'Finnish',
        'suomi': 'Finnish',
      };

      for (final pattern in languagePatterns) {
        final match = pattern.firstMatch(title);
        if (match != null) {
          final langCode = match.group(1)!.toLowerCase();
          if (languageMap.containsKey(langCode)) {
            languages.add(languageMap[langCode]!);
            break;
          }
        }
      }
    }

    if (regions.isNotEmpty) region = regions.first;
    if (languages.isNotEmpty) language = languages.first;

    // Assume language from region if language is not detected
    if (language.isEmpty && region.isNotEmpty) {
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
        'World': 'English',
        'USA/Europe': 'English',
      };

      if (regionToLanguage.containsKey(region)) {
        language = regionToLanguage[region]!;
        languages.add(language);
      }
    }

    // Assume region from language if region is not detected
    if (region.isEmpty && language.isNotEmpty) {
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

      if (languageToRegion.containsKey(language)) {
        region = languageToRegion[language]!;
        regions.add(region);
      }
    }

    // Clean up HTML entities and special characters
    normalizedTitle = normalizedTitle
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');

    subtitle = subtitle
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');

    normalizedTitle = normalizedTitle.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (normalizedTitle.contains(' - ')) {
      final parts = normalizedTitle.split(' - ');
      if (parts.length >= 2) {
        subtitle = parts.sublist(1).join(' - ');
        normalizedTitle = parts[0];

        final seriesPatterns = [
          RegExp(r'^(.+?)\s+(\d+|II|III|IV|V|VI|VII|VIII|IX|X|XI|XII)\s*$'),
          RegExp(r'^(.+?)\s+(Jr|Sr|Junior|Senior)\s*$'),
          RegExp(r'^(.+?)\s+(Part\s+\d+)\s*$'),
          RegExp(r'^(.+?)\s+(Episode\s+\d+)\s*$'),
          RegExp(r'^(.+?)\s+(Chapter\s+\d+)\s*$'),
        ];

        for (final pattern in seriesPatterns) {
          final seriesMatch = pattern.firstMatch(normalizedTitle);
          if (seriesMatch != null) {
            series = seriesMatch.group(1)!;
            break;
          }
        }
      }
    }

    final publisherPatterns = [
      RegExp(
          r'^(Nintendo|Sega|Sony|Microsoft|Capcom|Konami|Square|Enix|Square Enix|Namco|Bandai|Atari|Electronic Arts|EA|Activision|Ubisoft|THQ|Midway|Acclaim|Tecmo|Koei|SNK|Neo Geo|Hudson|Taito|Irem|Data East|Ocean|Psygnosis|Eidos|Core Design|Rare|Free Radical|Rockstar|Take-Two|2K|Bethesda|id Software|Epic|Valve|Blizzard)\b'),
    ];

    for (final pattern in publisherPatterns) {
      final match = pattern.firstMatch(normalizedTitle);
      if (match != null) {
        publisher = match.group(1)!;
        break;
      }
    }

    normalizedTitle = normalizedTitle.replaceAll(RegExp(r'\s+'), ' ').trim();

    categories.addAll(_generateCategories(
      dumpQualities: dumpQualities,
      romTypes: romTypes,
      modifications: modifications,
      distributionTypes: distributionTypes,
      mediaType: mediaType,
      collection: collection,
    ));

    return GameMetadata(
      normalizedTitle: normalizedTitle,
      region: region,
      language: language,
      version: version,
      dumpQualities: dumpQualities,
      romTypes: romTypes,
      modifications: modifications,
      distributionTypes: distributionTypes,
      revision: revision,
      diskNumber: diskNumber,
      tags: tags,
      subtitle: subtitle,
      series: series,
      publisher: publisher,
      collection: collection,
      mediaType: mediaType,
      releaseDate: releaseDate,
      regions: regions,
      languages: languages,
      categories: categories,
    );
  }

  static List<String> _generateCategories({
    required Set<DumpQuality> dumpQualities,
    required Set<RomType> romTypes,
    required Set<ModificationType> modifications,
    required Set<DistributionType> distributionTypes,
    required String mediaType,
    required String collection,
  }) {
    final categories = <String>[];

    // Development status categories
    if (romTypes.contains(RomType.demo)) categories.add('Demo');
    if (romTypes.contains(RomType.sample)) categories.add('Sample');
    if (romTypes.contains(RomType.proto)) categories.add('Prototype');
    if (romTypes.contains(RomType.beta)) categories.add('Beta');
    if (romTypes.contains(RomType.alpha)) categories.add('Alpha');

    // Modification categories
    if (modifications.contains(ModificationType.hack)) categories.add('Hack');
    if (modifications.contains(ModificationType.translation)) categories.add('Translation');

    // Distribution categories
    if (distributionTypes.contains(DistributionType.unlicensed)) categories.add('Unlicensed');
    if (distributionTypes.contains(DistributionType.aftermarket)) categories.add('Aftermarket');
    if (distributionTypes.contains(DistributionType.pirate)) categories.add('Pirate');

    // Special features
    if (distributionTypes.contains(DistributionType.multiCart)) categories.add('Multi-Game');
    if (distributionTypes.contains(DistributionType.enhanced)) categories.add('Enhanced');
    if (distributionTypes.contains(DistributionType.specialEdition)) categories.add('Special Edition');

    // Media type
    if (mediaType.isNotEmpty) {
      categories.add(mediaType);
    }

    // Collection
    if (collection.isNotEmpty) {
      categories.add('Collection');
    }

    return categories;
  }
}
