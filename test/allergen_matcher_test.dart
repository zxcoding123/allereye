import 'package:flutter_test/flutter_test.dart';

import 'package:allereye/helpers/allergenMatcher.dart';

AllergenMatchResult check(String text, List<String> allergens,
        {List<String> other = const []}) =>
    AllergenMatcher.match(text, allergens: allergens, otherAllergens: other);

void main() {
  group('synonyms', () {
    test('catches derived dairy ingredients', () {
      final r = check('Ingredients: sugar, whey powder, salt', ['Dairy']);
      expect(r.contains, ['Dairy']);
    });

    test('catches gluten grains', () {
      expect(check('Ingredients: spelt, water', ['Gluten']).contains,
          ['Gluten']);
      expect(check('Ingredients: barley malt extract', ['Gluten']).contains,
          ['Gluten']);
    });

    test('matches plurals', () {
      expect(check('Ingredients: roasted peanuts, salt', ['Peanuts']).contains,
          ['Peanuts']);
    });

    test('normalizes E-numbers', () {
      expect(check('Ingredients: grapes, preservative (E 220)', ['Sulfites'])
          .contains, ['Sulfites']);
    });
  });

  group('word boundaries', () {
    test('eggplant is not egg', () {
      expect(check('Ingredients: eggplant, olive oil', ['Eggs']).contains,
          isEmpty);
    });

    test('coconut and nutmeg are not tree nuts', () {
      expect(
          check('Ingredients: coconut, nutmeg', ['Tree Nuts']).contains, isEmpty);
    });

    test('peanut is not a tree nut', () {
      expect(check('Ingredients: peanut', ['Tree Nuts']).contains, isEmpty);
    });

    test('re-joins words hyphenated across lines', () {
      expect(check('Ingredients: roasted pea-\nnuts, salt', ['Peanuts']).contains,
          ['Peanuts']);
    });
  });

  group('exclusions', () {
    test('cocoa butter is not dairy', () {
      expect(check('Ingredients: sugar, cocoa butter, cocoa mass', ['Dairy'])
          .contains, isEmpty);
    });

    test('milk chocolate is still dairy', () {
      expect(check('Ingredients: milk chocolate, cocoa butter', ['Dairy'])
          .contains, ['Dairy']);
    });

    test('rice flour is not wheat', () {
      expect(check('Ingredients: rice flour, water', ['Wheat']).contains,
          isEmpty);
    });

    test('"gluten-free" claim alone does not flag gluten', () {
      expect(check('Gluten-free. Ingredients: rice, water', ['Gluten']).contains,
          isEmpty);
    });

    test('"gluten-free oats" still flags oats', () {
      expect(check('Ingredients: gluten-free oats', ['Gluten']).contains,
          ['Gluten']);
    });
  });

  group('precautionary statements', () {
    test('may contain is reported separately', () {
      final r = check(
          'Ingredients: oats, sugar. May contain traces of milk and peanuts.',
          ['Dairy', 'Peanuts']);
      expect(r.contains, isEmpty);
      expect(r.mayContain, unorderedEquals(['Dairy', 'Peanuts']));
    });

    test('facility statements count as may contain', () {
      final r = check(
          'Ingredients: corn, salt. Made in a facility that also processes '
          'sesame.',
          ['Sesame']);
      expect(r.mayContain, ['Sesame']);
    });

    test('an ingredient wins over a may-contain mention', () {
      final r = check('Ingredients: milk, sugar. May contain milk.', ['Dairy']);
      expect(r.contains, ['Dairy']);
      expect(r.mayContain, isEmpty);
    });
  });

  group('other allergens', () {
    test('parses the free-text field', () {
      expect(AllergenMatcher.parseOtherAllergens('kiwi, Strawberry;\n banana '),
          ['kiwi', 'Strawberry', 'banana']);
      expect(AllergenMatcher.parseOtherAllergens(null), isEmpty);
    });

    test('matches other allergens', () {
      final r = check('Ingredients: kiwi, apple', [], other: ['Kiwi']);
      expect(r.contains, ['Kiwi']);
    });
  });

  group('readability', () {
    test('almost no text is unreadable', () {
      expect(check('a1 b', ['Dairy']).isReadable, isFalse);
    });

    test('detects an ingredient list', () {
      expect(check('Ingredients: water, salt, sugar', ['Dairy'])
          .hasIngredientList, isTrue);
      expect(check('Delicious crunchy snack bar for the whole family',
              ['Dairy'])
          .hasIngredientList, isFalse);
    });
  });
}
