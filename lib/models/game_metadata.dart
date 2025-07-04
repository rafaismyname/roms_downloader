class GameMetadata {
  // Core identification
  final String normalizedTitle;
  final String subtitle;
  final String series;
  final String collection;
  
  // Release information
  final String publisher;
  final String releaseDate;
  final String version;
  final int revision;
  
  // Regional and language data
  final String region;
  final String language;
  final List<String> regions;
  final List<String> languages;
  
  // Media information
  final String mediaType;
  final String diskNumber;
  
  // Dump quality flags
  final bool isGoodDump;
  final bool isBadDump;
  final bool isOverdump;
  
  // ROM type flags
  final bool isDemo;
  final bool isSample;
  final bool isProto;
  final bool isBeta;
  final bool isAlpha;
  
  // Modification flags
  final bool isHack;
  final bool isTranslation;
  final bool isFixed;
  final bool isTrainer;
  
  // Edition and distribution flags
  final bool isEnhanced;
  final bool isSpecialEdition;
  final bool isAlternate;
  final bool isUnlicensed;
  final bool isAftermarket;
  final bool isPirate;
  final bool isMultiCart;
  
  // Additional metadata
  final List<String> tags;
  final List<String> categories;

  const GameMetadata({
    required this.normalizedTitle,
    this.region = '',
    this.language = '',
    this.version = '',
    this.isGoodDump = false,
    this.isBadDump = false,
    this.isOverdump = false,
    this.isHack = false,
    this.isTranslation = false,
    this.isAlternate = false,
    this.isFixed = false,
    this.isTrainer = false,
    this.isUnlicensed = false,
    this.isDemo = false,
    this.isSample = false,
    this.isProto = false,
    this.isBeta = false,
    this.isAlpha = false,
    this.revision = 0,
    this.diskNumber = '',
    this.tags = const [],
    
    // Enhanced fields
    this.subtitle = '',
    this.series = '',
    this.publisher = '',
    this.collection = '',
    this.mediaType = '',
    this.isEnhanced = false,
    this.isSpecialEdition = false,
    this.isAftermarket = false,
    this.isPirate = false,
    this.isMultiCart = false,
    this.releaseDate = '',
    this.regions = const [],
    this.languages = const [],
    this.categories = const [],
  });

  factory GameMetadata.fromJson(Map<String, dynamic> json) {
    return GameMetadata(
      normalizedTitle: json['normalizedTitle'] ?? '',
      region: json['region'] ?? '',
      language: json['language'] ?? '',
      version: json['version'] ?? '',
      isGoodDump: json['isGoodDump'] ?? false,
      isBadDump: json['isBadDump'] ?? false,
      isOverdump: json['isOverdump'] ?? false,
      isHack: json['isHack'] ?? false,
      isTranslation: json['isTranslation'] ?? false,
      isAlternate: json['isAlternate'] ?? false,
      isFixed: json['isFixed'] ?? false,
      isTrainer: json['isTrainer'] ?? false,
      isUnlicensed: json['isUnlicensed'] ?? false,
      isDemo: json['isDemo'] ?? false,
      isSample: json['isSample'] ?? false,
      isProto: json['isProto'] ?? false,
      isBeta: json['isBeta'] ?? false,
      isAlpha: json['isAlpha'] ?? false,
      revision: json['revision'] ?? 0,
      diskNumber: json['diskNumber'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      
      // Enhanced fields
      subtitle: json['subtitle'] ?? '',
      series: json['series'] ?? '',
      publisher: json['publisher'] ?? '',
      collection: json['collection'] ?? '',
      mediaType: json['mediaType'] ?? '',
      isEnhanced: json['isEnhanced'] ?? false,
      isSpecialEdition: json['isSpecialEdition'] ?? false,
      isAftermarket: json['isAftermarket'] ?? false,
      isPirate: json['isPirate'] ?? false,
      isMultiCart: json['isMultiCart'] ?? false,
      releaseDate: json['releaseDate'] ?? '',
      regions: List<String>.from(json['regions'] ?? []),
      languages: List<String>.from(json['languages'] ?? []),
      categories: List<String>.from(json['categories'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'normalizedTitle': normalizedTitle,
      'region': region,
      'language': language,
      'version': version,
      'isGoodDump': isGoodDump,
      'isBadDump': isBadDump,
      'isOverdump': isOverdump,
      'isHack': isHack,
      'isTranslation': isTranslation,
      'isAlternate': isAlternate,
      'isFixed': isFixed,
      'isTrainer': isTrainer,
      'isUnlicensed': isUnlicensed,
      'isDemo': isDemo,
      'isSample': isSample,
      'isProto': isProto,
      'isBeta': isBeta,
      'isAlpha': isAlpha,
      'revision': revision,
      'diskNumber': diskNumber,
      'tags': tags,
      'subtitle': subtitle,
      'series': series,
      'publisher': publisher,
      'collection': collection,
      'mediaType': mediaType,
      'isEnhanced': isEnhanced,
      'isSpecialEdition': isSpecialEdition,
      'isAftermarket': isAftermarket,
      'isPirate': isPirate,
      'isMultiCart': isMultiCart,
      'releaseDate': releaseDate,
      'regions': regions,
      'languages': languages,
      'categories': categories,
    };
  }
}
