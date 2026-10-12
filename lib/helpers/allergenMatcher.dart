/// Result of checking recognized label text against a user's allergens.
class AllergenMatchResult {
  /// Allergens listed as ingredients.
  final List<String> contains;

  /// Allergens that only appear in precautionary statements
  /// ("may contain", "traces of", "made in a facility that...").
  final List<String> mayContain;

  /// False when too little text was recognized to trust the result.
  final bool isReadable;

  /// True when the text looks like it includes an ingredient list.
  final bool hasIngredientList;

  const AllergenMatchResult({
    required this.contains,
    required this.mayContain,
    required this.isReadable,
    required this.hasIngredientList,
  });
}

class AllergenMatcher {
  /// Ingredient names that indicate each allergen.
  static const Map<String, List<String>> synonyms = {
    'Peanuts': ['peanut', 'groundnut', 'ground nut', 'arachis', 'monkey nut'],
    'Gluten': [
      'gluten', 'wheat', 'barley', 'rye', 'oat', 'spelt', 'kamut',
      'triticale', 'semolina', 'durum', 'malt', 'farro', 'einkorn', 'emmer',
      'seitan', 'bulgur', 'couscous',
    ],
    'Dairy': [
      'milk', 'cheese', 'yogurt', 'yoghurt', 'lactose', 'whey', 'casein',
      'caseinate', 'butter', 'buttermilk', 'cream', 'ghee', 'curd',
      'lactalbumin', 'lactoglobulin', 'milk solids', 'skimmed milk powder',
    ],
    'Shellfish': [
      'shrimp', 'crab', 'lobster', 'prawn', 'crayfish', 'krill',
      'langoustine', 'scampi', 'crustacean',
    ],
    'Eggs': [
      'egg', 'albumin', 'albumen', 'ovalbumin', 'ovomucoid', 'lysozyme',
      'mayonnaise', 'meringue',
    ],
    'Soy': ['soy', 'soya', 'soybean', 'edamame', 'tofu', 'tempeh', 'miso'],
    'Tree Nuts': [
      'nut', 'almond', 'walnut', 'cashew', 'hazelnut', 'pecan', 'pistachio',
      'macadamia', 'brazil nut', 'pine nut', 'praline', 'marzipan',
      'gianduja',
    ],
    'Wheat': [
      'wheat', 'flour', 'spelt', 'semolina', 'durum', 'bulgur', 'couscous',
      'farina', 'seitan',
    ],
    'Fish': [
      'fish', 'salmon', 'tuna', 'cod', 'anchovy', 'anchovies', 'sardine',
      'mackerel', 'trout', 'haddock', 'pollock', 'tilapia', 'halibut',
      'herring', 'surimi',
    ],
    'Sesame': ['sesame', 'tahini', 'gingelly', 'benne'],
    'Mustard': ['mustard'],
    'Lupin': ['lupin', 'lupine', 'lupini'],
    'Celery': ['celery', 'celeriac'],
    'Mollusks': [
      'clam', 'mussel', 'oyster', 'squid', 'scallop', 'octopus', 'cuttlefish',
      'snail', 'escargot', 'abalone', 'whelk', 'calamari', 'mollusc',
      'mollusk',
    ],
    'Sulfites': [
      'sulfite', 'sulphite', 'sulfur dioxide', 'sulphur dioxide',
      'metabisulfite', 'metabisulphite', 'bisulfite', 'bisulphite', 'e220',
      'e221', 'e222', 'e223', 'e224', 'e225', 'e226', 'e227', 'e228',
    ],
  };

  /// Phrases that contain a synonym but do not indicate the allergen.
  static const Map<String, List<String>> exclusions = {
    'Dairy': [
      'cocoa butter', 'cacao butter', 'shea butter', 'peanut butter',
      'nut butter', 'almond butter', 'cashew butter', 'apple butter',
      'butter bean', 'coconut milk', 'coconut cream', 'almond milk',
      'oat milk', 'soy milk', 'soya milk', 'rice milk', 'cashew milk',
      'cream of tartar',
    ],
    'Tree Nuts': ['ground nut', 'monkey nut'],
    'Wheat': [
      'rice flour', 'corn flour', 'maize flour', 'potato flour',
      'almond flour', 'coconut flour', 'chickpea flour', 'gram flour',
      'tapioca flour', 'cassava flour', 'buckwheat flour', 'oat flour',
      'rye flour', 'soy flour', 'soya flour', 'sorghum flour',
      'millet flour', 'quinoa flour', 'lupin flour', 'pea flour',
    ],
    'Mollusks': ['oyster mushroom'],
  };

  /// Start of a precautionary statement; it runs to the end of the sentence.
  static final RegExp _precautionary = RegExp(
    r'(may (also )?contain'
    r'|traces? (amounts? )?of'
    r'|(produced|made|manufactured|processed|packed|packaged) (in|on|at|using) '
    r'(a |the )?(same |shared )?(facility|factory|site|premises|equipment|line)'
    r'|(shared|same) (equipment|facility|factory|production line))'
    r'[^.]{0,200}',
  );

  static final RegExp _ingredientList =
      RegExp(r'\b(ingredients?|contains|composition)\b');

  static final RegExp _letter = RegExp(r'\p{L}', unicode: true);

  /// Fewer recognized letters than this means the photo couldn't be read.
  static const int _minReadableLetters = 20;

  static AllergenMatchResult match(
    String rawText, {
    required List<String> allergens,
    List<String> otherAllergens = const [],
  }) {
    final text = normalize(rawText);

    // Split precautionary statements from the ingredient text so
    // "may contain milk" is reported separately from "milk".
    final precautionary =
        _precautionary.allMatches(text).map((m) => m.group(0)!).join(' . ');
    final ingredients = text.replaceAll(_precautionary, ' . ');

    final contains = <String>[];
    final mayContain = <String>[];

    void check(String allergen, List<String> terms, List<String> excluded) {
      if (_mentions(ingredients, terms, excluded)) {
        contains.add(allergen);
      } else if (_mentions(precautionary, terms, excluded)) {
        mayContain.add(allergen);
      }
    }

    for (final allergen in allergens) {
      check(
        allergen,
        synonyms[allergen] ?? [allergen],
        exclusions[allergen] ?? const [],
      );
    }
    for (final other in otherAllergens) {
      if (!contains.contains(other) && !mayContain.contains(other)) {
        check(other, [other], const []);
      }
    }

    return AllergenMatchResult(
      contains: contains,
      mayContain: mayContain,
      isReadable: _letter.allMatches(text).length >= _minReadableLetters,
      hasIngredientList: _ingredientList.hasMatch(text),
    );
  }

  /// Splits the free-text "other allergens" field into individual terms.
  static List<String> parseOtherAllergens(String? raw) {
    if (raw == null) return [];
    return raw
        .split(RegExp(r'[,;\n]'))
        .map((term) => term.trim())
        .where((term) => term.isNotEmpty)
        .toList();
  }

  /// Lowercases OCR output and undoes common line-break artifacts.
  static String normalize(String text) {
    return text
        .toLowerCase()
        // Re-join words hyphenated across lines ("pea-\nnut" -> "peanut").
        .replaceAll(RegExp(r'-[ \t]*\r?\n\s*'), '')
        // "E 220" / "E-220" -> "e220".
        .replaceAllMapped(
            RegExp(r'\be[\s-](\d{3})\b'), (m) => 'e${m.group(1)}')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _mentions(
      String text, List<String> terms, List<String> excluded) {
    var remaining = text;
    for (final phrase in excluded) {
      remaining = remaining.replaceAll(_termPattern(phrase), ' ');
    }
    return terms.any((term) => _termPattern(term).hasMatch(remaining));
  }

  /// Whole-word match with an optional plural, skipping "-free" claims
  /// (so "gluten-free" doesn't count, but "gluten-free oats" still
  /// matches on "oats").
  static RegExp _termPattern(String term) {
    final words = term
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .map(RegExp.escape)
        .join(r'[\s-]+');
    return RegExp('\\b$words(?:s|es)?\\b(?![\\s-]*free\\b)');
  }
}
