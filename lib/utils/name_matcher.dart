class NameMatcher {
  static String normalizeName(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static Map<String, List<String>> buildTokenIndex(Iterable<String> names) {
    final Map<String, List<String>> index = {};
    for (final name in names) {
      for (final token in name.split(' ')) {
        if (!(RegExp(r'^\d+$').hasMatch(token) || token.length > 2 || RegExp(r'^[a-z]+\d+$').hasMatch(token))) {
          continue;
        }
        index.putIfAbsent(token, () => []).add(name);
      }
    }
    return index;
  }

  static String? match({
    required String nameToMatch,
    required Map<String, String> candidates,
    required Map<String, List<String>> tokenIndex,
  }) {
    final normalizedGameName = normalizeName(nameToMatch);

    if (candidates.containsKey(normalizedGameName)) {
      return candidates[normalizedGameName];
    }

    final numericRegExp = RegExp(r'^\d{2,}$');
    final mixedTokenRegExp = RegExp(r'^[a-z]+\d+$');
    final gameTokens = normalizedGameName.split(' ').where((token) {
      if (token.isEmpty) return false;
      return numericRegExp.hasMatch(token) || token.length > 2 || mixedTokenRegExp.hasMatch(token);
    }).toList();

    final numericTokens = gameTokens.where((t) => numericRegExp.hasMatch(t)).toList();

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
      for (final token in gameTokens.where((t) => !numericRegExp.hasMatch(t))) {
        final names = tokenIndex[token];
        if (names != null) candidateNames.addAll(names);
      }
    }

    if (candidateNames.isEmpty) {
      return null;
    }

    final mixedTokens = gameTokens.where((t) => mixedTokenRegExp.hasMatch(t)).toList();
    if (mixedTokens.isNotEmpty) {
      candidateNames = candidateNames.where((name) {
        final tokens = name.split(' ');
        for (final mt in mixedTokens) {
          if (!tokens.contains(mt)) return false;
        }
        return true;
      }).toSet();

      if (candidateNames.isEmpty) {
        return null;
      }
    }

    final hasMixedTokensInGame = mixedTokens.isNotEmpty;
    candidateNames = candidateNames.where((name) {
      if (!hasMixedTokensInGame && RegExp(r'\b[a-z]+\d+\b').hasMatch(name)) {
        return false;
      }
      return true;
    }).toSet();

    if (candidateNames.isEmpty) return null;

    final Iterable<String> searchSpace = candidateNames;
    final Set<String> nonNumericTokens = {
      for (final t in gameTokens)
        if (!numericRegExp.hasMatch(t)) t
    };
    final mainTitle = gameTokens.firstWhere(
      (t) => !numericRegExp.hasMatch(t),
      orElse: () => gameTokens.isNotEmpty ? gameTokens.first : '',
    );

    String? bestMatchName;
    int highestScore = 0;
    for (final candidate in searchSpace) {
      if (nonNumericTokens.isNotEmpty && !nonNumericTokens.any((t) => candidate.contains(t))) {
        continue;
      }

      final score = _calculateMatchScore(normalizedGameName, candidate, mainTitle);
      if (score > highestScore && score > 2) {
        highestScore = score;
        bestMatchName = candidate;
      }
    }
    if (bestMatchName != null) {
      return candidates[bestMatchName];
    }
    return null;
  }

  static int _calculateMatchScore(String gameName, String boxartName, String mainTitle) {
    final gameTokens = gameName.split(' ');
    final boxartTokens = boxartName.split(' ');

    int score = 0;

    if (boxartName.contains(mainTitle)) {
      score += 3;
    }

    final numericExp = RegExp(r'^\d{2,}$');

    for (final gameToken in gameTokens) {
      final isNumeric = numericExp.hasMatch(gameToken);

      if (isNumeric) {
        if (boxartTokens.contains(gameToken)) {
          score += 4;
        } else {
          score -= 3;
        }
        continue;
      }

      if (gameToken.length > 2) {
        if (boxartTokens.any((token) => token.contains(gameToken))) {
          score += 2;
        } else if (boxartName.contains(gameToken)) {
          score += 1;
        }
      }
    }

    final tokenDifference = (boxartTokens.length - gameTokens.length).abs();
    if (tokenDifference > 2) {
      score -= 1;
    }

    if (gameTokens.length == boxartTokens.length) {
      score += 1;
    }

    return score;
  }
}
