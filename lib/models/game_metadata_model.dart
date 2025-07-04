enum DumpQuality { goodDump, badDump, overdump }

enum RomType { demo, sample, proto, beta, alpha }

enum ModificationType { hack, translation, fixed, trainer }

enum DistributionType { enhanced, specialEdition, alternate, unlicensed, aftermarket, pirate, multiCart }

class GameMetadata {
  final String displayTitle;
  final String collection;
  final int revision;
  final List<String> regions;
  final List<String> languages;
  final String mediaType;
  final String diskNumber;
  final Set<DumpQuality> dumpQualities;
  final Set<RomType> romTypes;
  final Set<ModificationType> modifications;
  final Set<DistributionType> distributionTypes;
  final List<String> categories;

  const GameMetadata({
    required this.displayTitle,
    this.dumpQualities = const {},
    this.romTypes = const {},
    this.modifications = const {},
    this.distributionTypes = const {},
    this.revision = 0,
    this.diskNumber = '',
    this.collection = '',
    this.mediaType = '',
    this.regions = const [],
    this.languages = const [],
    this.categories = const [],
  });

  factory GameMetadata.fromJson(Map<String, dynamic> json) {
    Set<T> parseFlags<T>(String key, Map<String, T> flagMap) {
      final flags = <T>{};

      if (json[key] is List) {
        final list = List<String>.from(json[key] ?? []);
        for (final flag in list) {
          final value = flagMap[flag];
          if (value != null) {
            flags.add(value);
          }
        }
      }

      return flags;
    }

    final dumpQualityMap = {
      'goodDump': DumpQuality.goodDump,
      'badDump': DumpQuality.badDump,
      'overdump': DumpQuality.overdump,
    };

    final romTypeMap = {
      'demo': RomType.demo,
      'sample': RomType.sample,
      'proto': RomType.proto,
      'beta': RomType.beta,
      'alpha': RomType.alpha,
    };

    final modificationMap = {
      'hack': ModificationType.hack,
      'translation': ModificationType.translation,
      'fixed': ModificationType.fixed,
      'trainer': ModificationType.trainer,
    };

    final distributionMap = {
      'enhanced': DistributionType.enhanced,
      'specialEdition': DistributionType.specialEdition,
      'alternate': DistributionType.alternate,
      'unlicensed': DistributionType.unlicensed,
      'aftermarket': DistributionType.aftermarket,
      'pirate': DistributionType.pirate,
      'multiCart': DistributionType.multiCart,
    };

    return GameMetadata(
      displayTitle: json['displayTitle'] ?? '',
      dumpQualities: parseFlags('dumpQualities', dumpQualityMap),
      romTypes: parseFlags('romTypes', romTypeMap),
      modifications: parseFlags('modifications', modificationMap),
      distributionTypes: parseFlags('distributionTypes', distributionMap),
      revision: json['revision'] ?? 0,
      diskNumber: json['diskNumber'] ?? '',
      collection: json['collection'] ?? '',
      mediaType: json['mediaType'] ?? '',
      regions: List<String>.from(json['regions'] ?? []),
      languages: List<String>.from(json['languages'] ?? []),
      categories: List<String>.from(json['categories'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayTitle': displayTitle,
      'dumpQualities': dumpQualities.map((e) => e.name).toList(),
      'romTypes': romTypes.map((e) => e.name).toList(),
      'modifications': modifications.map((e) => e.name).toList(),
      'distributionTypes': distributionTypes.map((e) => e.name).toList(),
      'revision': revision,
      'diskNumber': diskNumber,
      'collection': collection,
      'mediaType': mediaType,
      'regions': regions,
      'languages': languages,
      'categories': categories,
    };
  }

  List<String> get allFlags {
    final flags = <String>[];
    flags.addAll(dumpQualities.map((e) => e.name));
    flags.addAll(romTypes.map((e) => e.name));
    flags.addAll(modifications.map((e) => e.name));
    flags.addAll(distributionTypes.map((e) => e.name));
    return flags;
  }
}
