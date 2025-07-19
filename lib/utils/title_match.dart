import 'package:rapidfuzz/rapidfuzz.dart';

String normalizeTitle(String name) {
  return RegExp(r'[_\W]+')
      .allMatches(name.toLowerCase())
      .fold<StringBuffer>(StringBuffer(), (b, m) {
        b
          ..write(name.substring(b.length, m.start).replaceAll('_', ' '))
          ..write(' ');
        return b;
      })
      .toString()
      .trim();
}

Map<String, List<String>> buildTokenIndex(Iterable<String> names) {
  final Map<String, List<String>> index = {};
  for (final name in names) {
    for (final token in name.split(' ')) {
      if (token.length > 1) {
        index.putIfAbsent(token, () => []).add(name);
      }
    }
  }
  return index;
}

String? matchTitle({
  required String titleToMatch,
  required Map<String, String> candidates,
  required Map<String, List<String>> tokenIndex,
}) {
  final normalizedTitle = normalizeTitle(titleToMatch);

  if (candidates.containsKey(normalizedTitle)) {
    return candidates[normalizedTitle];
  }

  final numericRegExp = RegExp(r'^\d+$');
  final mixedTokenRegExp = RegExp(r'^[a-z]+\d+$');
  final titleTokens = normalizedTitle.split(' ').where((token) {
    return token.length > 1;
  }).toList();

  final numericTokens = titleTokens.where((t) => numericRegExp.hasMatch(t)).toList();

  Set<String> candidateNames = {};

  if (numericTokens.isNotEmpty) {
    Set<String>? intersection;
    for (final nt in numericTokens) {
      final names = tokenIndex[nt];
      if (names == null) {
        intersection = <String>{};
        break;
      }
      final nameSet = names.toSet();
      intersection = intersection == null ? nameSet : intersection.intersection(nameSet);
      if (intersection.isEmpty) break;
    }
    candidateNames = intersection ?? <String>{};
  }

  if (candidateNames.isEmpty && numericTokens.isEmpty) {
    for (final token in titleTokens.where((t) => !numericRegExp.hasMatch(t))) {
      final names = tokenIndex[token];
      if (names != null) candidateNames.addAll(names);
    }
  }

  if (candidateNames.isEmpty) {
    return null;
  }

  final mixedTokens = titleTokens.where((t) => mixedTokenRegExp.hasMatch(t)).toList();

  final hasMixedTokensInGame = mixedTokens.isNotEmpty;
  candidateNames = candidateNames.where((name) {
    if (!hasMixedTokensInGame && RegExp(r'\b[a-z]+\d+\b').hasMatch(name)) {
      return false;
    }
    return true;
  }).toSet();

  // Generic meaningful-token Jaccard style filter.
  if (candidateNames.isNotEmpty) {
    final Set<String> meaningfulGameTokens = {
      for (final t in titleTokens)
        if (!numericRegExp.hasMatch(t) && t.length > 1) t
    };

    if (meaningfulGameTokens.isNotEmpty) {
      candidateNames = candidateNames.where((name) {
        final tokens = name.split(' ').where((tok) => tok.length > 1 && !numericRegExp.hasMatch(tok)).toSet();
        final int common = tokens.intersection(meaningfulGameTokens).length;
        return common >= meaningfulGameTokens.length * 0.7;
      }).toSet();
    }
  }

  if (candidateNames.isEmpty) return null;

  final Iterable<String> searchSpace = candidateNames;

  String? bestMatchName;
  int highestScore = 0;
  for (final candidate in searchSpace) {
    final score = tokenSetRatio(normalizedTitle, candidate).toInt();
    if (score > highestScore && score >= 90) {
      highestScore = score;
      bestMatchName = candidate;
    }
  }
  if (bestMatchName != null) {
    return candidates[bestMatchName];
  }
  return null;
}
