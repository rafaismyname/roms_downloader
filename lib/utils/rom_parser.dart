import 'package:roms_downloader/models/game_metadata.dart';

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
    bool isGoodDump = false;
    bool isBadDump = false;
    bool isOverdump = false;
    bool isHack = false;
    bool isTranslation = false;
    bool isAlternate = false;
    bool isFixed = false;
    bool isTrainer = false;
    bool isUnlicensed = false;
    bool isDemo = false;
    bool isSample = false;
    bool isProto = false;
    bool isBeta = false;
    bool isAlpha = false;
    int revision = 0;
    String diskNumber = '';
    List<String> tags = [];

    String subtitle = '';
    String series = '';
    String publisher = '';
    String collection = '';
    String mediaType = '';
    bool isEnhanced = false;
    bool isSpecialEdition = false;
    bool isAftermarket = false;
    bool isPirate = false;
    bool isMultiCart = false;
    String releaseDate = '';
    List<String> regions = [];
    List<String> languages = [];
    List<String> categories = [];

    normalizedTitle = title.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');

    final patterns = <RegExp, Function(Match)>{
      RegExp(r'\[!\]'): (match) {
        isGoodDump = true;
        tags.add('Good Dump');
      },
      RegExp(r'\[b(\d*)\]'): (match) {
        isBadDump = true;
        tags.add('Bad Dump');
      },
      RegExp(r'\[o(\d*)\]'): (match) {
        isOverdump = true;
        tags.add('Overdump');
      },
      RegExp(r'\[h(\d*[A-Za-z]*)\]'): (match) {
        isHack = true;
        tags.add('Hack');
      },
      RegExp(r'\[t(\d*[A-Za-z]*)\]'): (match) {
        isTranslation = true;
        tags.add('Translation');
      },
      RegExp(r'\[a(\d*)\]'): (match) {
        isAlternate = true;
        tags.add('Alternate');
      },
      RegExp(r'\[f(\d*)\]'): (match) {
        isFixed = true;
        tags.add('Fixed');
      },
      RegExp(r'\[T[+-][A-Za-z]*(\d*)\]'): (match) {
        isTrainer = true;
        tags.add('Trainer');
      },
      RegExp(r'\[x\]'): (match) => isBadDump = true,
      RegExp(r'\[p(\d*)\]'): (match) => isPirate = true,
      RegExp(r'\[c\]'): (match) => isFixed = true,
      RegExp(r'\[CR [^\]]+\]'): (match) => isPirate = true,
      RegExp(r'\[m(\d*)\]'): (match) => isMultiCart = true,
      RegExp(r'\[S\]'): (match) => categories.add('Save'),
      RegExp(r'\[SCES-\d+\]'): (match) => categories.add('Sony Code'),
      RegExp(r'\[SLUS-\d+\]'): (match) => categories.add('Sony Code'),
      RegExp(r'\[SCUS-\d+\]'): (match) => categories.add('Sony Code'),
      RegExp(r'\[.*-\d+.*\]'): (match) => categories.add('Product Code'),
      RegExp(r'\(M(\d+)\)'): (match) => isMultiCart = true,
      RegExp(r'\(Unl\)'): (match) => isUnlicensed = true,
      RegExp(r'\(Unlicensed\)'): (match) => isUnlicensed = true,
      RegExp(r'\(PD\)'): (match) => {isUnlicensed = true, regions.add('Public Domain')},
      RegExp(r'\(Demo[^)]*\)'): (match) => isDemo = true,
      RegExp(r'\(Kiosk Demo\)'): (match) => {isDemo = true, categories.add('Kiosk')},
      RegExp(r'\(Sample\)'): (match) => isSample = true,
      RegExp(r'\(Proto[^)]*\)'): (match) => isProto = true,
      RegExp(r'\(Prototype[^)]*\)'): (match) => isProto = true,
      RegExp(r'\(Beta[^)]*\)'): (match) => isBeta = true,
      RegExp(r'\(Alpha[^)]*\)'): (match) => isAlpha = true,
      RegExp(r'\(Preview\)'): (match) => isBeta = true,
      RegExp(r'\(Pre-Release\)'): (match) => isBeta = true,
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
      RegExp(r'\(SGB Enhanced\)'): (match) => {isEnhanced = true, mediaType = 'SGB Enhanced'},
      RegExp(r'\(NKit[^)]*\)'): (match) => mediaType = 'NKit',
      RegExp(r'\(RVZ[^)]*\)'): (match) => mediaType = 'RVZ',
      RegExp(r'\(CDI\)'): (match) => mediaType = 'CDI',
      RegExp(r'\(GDI\)'): (match) => mediaType = 'GDI',
      RegExp(r'\(Decrypted\)'): (match) => mediaType = 'Decrypted',
      RegExp(r'\(Encrypted\)'): (match) => mediaType = 'Encrypted',
      RegExp(r'\(Aftermarket\)'): (match) => isAftermarket = true,
      RegExp(r'\(Homebrew\)'): (match) => isAftermarket = true,
      RegExp(r'\(Pirate\)'): (match) => isPirate = true,
      RegExp(r'\(Multicart[^)]*\)'): (match) => isMultiCart = true,
      RegExp(r'\(Multi[^)]*\)'): (match) => isMultiCart = true,
      RegExp(r'\(\d+[ -]?in[ -]?\d+\)'): (match) => isMultiCart = true,
      RegExp(r'\(Possible Proto\)'): (match) => isProto = true,
      RegExp(r'\(Trainer\)'): (match) => isTrainer = true,
      RegExp(r'\([^)]*Collection[^)]*\)'): (match) => {collection = match.group(0)!.replaceAll(RegExp(r'[()]'), ''), categories.add('Collection')},
      RegExp(r'\([^)]*Edition[^)]*\)'): (match) =>
          {isSpecialEdition = true, collection = match.group(0)!.replaceAll(RegExp(r'[()]'), ''), categories.add('Special Edition')},
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
      isDemo: isDemo,
      isSample: isSample,
      isProto: isProto,
      isBeta: isBeta,
      isAlpha: isAlpha,
      isHack: isHack,
      isTranslation: isTranslation,
      isUnlicensed: isUnlicensed,
      isAftermarket: isAftermarket,
      isPirate: isPirate,
      isMultiCart: isMultiCart,
      isEnhanced: isEnhanced,
      isSpecialEdition: isSpecialEdition,
      mediaType: mediaType,
      collection: collection,
    ));

    return GameMetadata(
      normalizedTitle: normalizedTitle,
      region: region,
      language: language,
      version: version,
      isGoodDump: isGoodDump,
      isBadDump: isBadDump,
      isOverdump: isOverdump,
      isHack: isHack,
      isTranslation: isTranslation,
      isAlternate: isAlternate,
      isFixed: isFixed,
      isTrainer: isTrainer,
      isUnlicensed: isUnlicensed,
      isDemo: isDemo,
      isSample: isSample,
      isProto: isProto,
      isBeta: isBeta,
      isAlpha: isAlpha,
      revision: revision,
      diskNumber: diskNumber,
      tags: tags,
      subtitle: subtitle,
      series: series,
      publisher: publisher,
      collection: collection,
      mediaType: mediaType,
      isEnhanced: isEnhanced,
      isSpecialEdition: isSpecialEdition,
      isAftermarket: isAftermarket,
      isPirate: isPirate,
      isMultiCart: isMultiCart,
      releaseDate: releaseDate,
      regions: regions,
      languages: languages,
      categories: categories,
    );
  }

  static List<String> _generateCategories({
    required bool isDemo,
    required bool isSample,
    required bool isProto,
    required bool isBeta,
    required bool isAlpha,
    required bool isHack,
    required bool isTranslation,
    required bool isUnlicensed,
    required bool isAftermarket,
    required bool isPirate,
    required bool isMultiCart,
    required bool isEnhanced,
    required bool isSpecialEdition,
    required String mediaType,
    required String collection,
  }) {
    final categories = <String>[];

    // Development status categories
    if (isDemo) categories.add('Demo');
    if (isSample) categories.add('Sample');
    if (isProto) categories.add('Prototype');
    if (isBeta) categories.add('Beta');
    if (isAlpha) categories.add('Alpha');

    // Modification categories
    if (isHack) categories.add('Hack');
    if (isTranslation) categories.add('Translation');

    // Distribution categories
    if (isUnlicensed) categories.add('Unlicensed');
    if (isAftermarket) categories.add('Aftermarket');
    if (isPirate) categories.add('Pirate');

    // Special features
    if (isMultiCart) categories.add('Multi-Game');
    if (isEnhanced) categories.add('Enhanced');
    if (isSpecialEdition) categories.add('Special Edition');

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
