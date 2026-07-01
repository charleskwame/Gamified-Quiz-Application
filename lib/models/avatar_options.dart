import 'dart:math';

/// Data-driven model for DiceBear toon-head avatar traits.
/// Each option is stored as {value, label} — no if-else chains needed.
class AvatarTrait {
  final String value;
  final String label;

  const AvatarTrait(this.value, this.label);
}

class AvatarCategory {
  final String label; // UI label, e.g. "Skin Tone"
  final String key; // key in avatarDetails map
  final List<AvatarTrait> options;
  final bool optional; // e.g. clothingColor only shows when clothing != 'none'

  const AvatarCategory({
    required this.label,
    required this.key,
    required this.options,
    this.optional = false,
  });
}

/// Central registry of all DiceBear toon-head options.
class AvatarOptions {
  AvatarOptions._();

  static const List<AvatarTrait> skinColor = [
    AvatarTrait('ffeedd', 'Porcelain (Very Light)'),
    AvatarTrait('f5d0b1', 'Peach (Light)'),
    AvatarTrait('e6b88a', 'Golden (Medium)'),
    AvatarTrait('d4a574', 'Tan (Medium Dark)'),
    AvatarTrait('8d5524', 'Espresso (Dark)'),
  ];

  static const List<AvatarTrait> hair = [
    AvatarTrait('bald', 'Bald'),
    AvatarTrait('bob', 'Bob'),
    AvatarTrait('braids', 'Braids'),
    AvatarTrait('bun', 'Bun'),
    AvatarTrait('buzz', 'Buzz Cut'),
    AvatarTrait('curly', 'Curly'),
    AvatarTrait('dannyPhantom', 'Danny Phantom (Tousled)'),
    AvatarTrait('dougFunny', 'Doug Funny (Short)'),
    AvatarTrait('flatTop', 'Flat Top'),
    AvatarTrait('fonze', 'Fonze (Greaser)'),
    AvatarTrait('full', 'Full (Afro / Volume)'),
    AvatarTrait('long', 'Long'),
    AvatarTrait('mrClean', 'Mr. Clean (Bald)'),
    AvatarTrait('mrT', 'Mr. T (Mohawk)'),
    AvatarTrait('pixie', 'Pixie'),
    AvatarTrait('pompadour', 'Pompadour'),
    AvatarTrait('shortCurly', 'Short Curly'),
    AvatarTrait('shortFlat', 'Short Flat'),
    AvatarTrait('shortRound', 'Short Round'),
    AvatarTrait('turban', 'Turban'),
    AvatarTrait('wave', 'Wave'),
    AvatarTrait('wide', 'Wide'),
  ];

  static const List<AvatarTrait> hairColor = [
    AvatarTrait('1a1a1a', 'Black'),
    AvatarTrait('4a3728', 'Brown'),
    AvatarTrait('a5753f', 'Blonde'),
    AvatarTrait('c25a38', 'Red / Auburn'),
    AvatarTrait('707070', 'Gray'),
    AvatarTrait('305a96', 'Blue'),
    AvatarTrait('b83098', 'Pink'),
    AvatarTrait('e8b270', 'Platinum'),
  ];

  static const List<AvatarTrait> eyes = [
    AvatarTrait('eyes', 'Eyes'),
    AvatarTrait('eyesShadow', 'Eyes Shadow'),
    AvatarTrait('round', 'Round'),
    AvatarTrait('smiling', 'Smiling'),
    AvatarTrait('wide', 'Wide'),
  ];

  static const List<AvatarTrait> eyebrows = [
    AvatarTrait('down', 'Down'),
    AvatarTrait('eyelashesDown', 'Eyelashes Down'),
    AvatarTrait('eyelashesUp', 'Eyelashes Up'),
    AvatarTrait('up', 'Up'),
  ];

  static const List<AvatarTrait> mouth = [
    AvatarTrait('frown', 'Frown'),
    AvatarTrait('laughing', 'Laughing'),
    AvatarTrait('nervous', 'Nervous'),
    AvatarTrait('pucker', 'Pucker'),
    AvatarTrait('sad', 'Sad'),
    AvatarTrait('smile', 'Smile'),
    AvatarTrait('smirk', 'Smirk'),
    AvatarTrait('surprised', 'Surprised'),
  ];

  static const List<AvatarTrait> facialHair = [
    AvatarTrait('none', 'None'),
    AvatarTrait('beard', 'Beard'),
    AvatarTrait('scruff', 'Scruff'),
    AvatarTrait('goatee', 'Goatee'),
    AvatarTrait('moustache', 'Moustache'),
  ];

  static const List<AvatarTrait> glasses = [
    AvatarTrait('none', 'None'),
    AvatarTrait('round', 'Round'),
    AvatarTrait('square', 'Square'),
    AvatarTrait('wayfarers', 'Wayfarers'),
  ];

  static const List<AvatarTrait> clothing = [
    AvatarTrait('none', 'None'),
    AvatarTrait('blazer', 'Blazer'),
    AvatarTrait('blazerAndShirt', 'Blazer & Shirt'),
    AvatarTrait('graphicShirt', 'Graphic Shirt'),
    AvatarTrait('hoodie', 'Hoodie'),
    AvatarTrait('overall', 'Overall'),
    AvatarTrait('shirt', 'Shirt'),
    AvatarTrait('vneck', 'V-Neck'),
  ];

  static const List<AvatarTrait> clothingColor = [
    AvatarTrait('1a1a1a', 'Black'),
    AvatarTrait('4a3728', 'Brown'),
    AvatarTrait('a5753f', 'Blonde / Tan'),
    AvatarTrait('c25a38', 'Red / Auburn'),
    AvatarTrait('707070', 'Gray'),
    AvatarTrait('305a96', 'Blue'),
    AvatarTrait('b83098', 'Pink'),
    AvatarTrait('e8b270', 'Platinum'),
    AvatarTrait('3a7d44', 'Green'),
    AvatarTrait('6c4f8c', 'Purple'),
    AvatarTrait('c4a35a', 'Gold'),
  ];

  /// Ordered list of categories used to build the customizer UI and
  /// serialize/deserialize avatar details.
  static const List<AvatarCategory> categories = [
    AvatarCategory(label: 'Skin Tone', key: 'skinColor', options: skinColor),
    AvatarCategory(label: 'Hair Style', key: 'hair', options: hair),
    AvatarCategory(label: 'Hair Color', key: 'hairColor', options: hairColor),
    AvatarCategory(label: 'Eyes', key: 'eyes', options: eyes),
    AvatarCategory(label: 'Eyebrows', key: 'eyebrows', options: eyebrows),
    AvatarCategory(label: 'Mouth', key: 'mouth', options: mouth),
    AvatarCategory(
      label: 'Facial Hair',
      key: 'facialHair',
      options: facialHair,
    ),
    AvatarCategory(label: 'Glasses', key: 'glasses', options: glasses),
    AvatarCategory(label: 'Clothing', key: 'clothing', options: clothing),
    AvatarCategory(
      label: 'Clothing Color',
      key: 'clothingColor',
      options: clothingColor,
      optional: true,
    ),
  ];

  /// Returns the display label for a given category key and value.
  /// Falls back to the raw value if no match is found.
  static String labelFor(String categoryKey, String value) {
    for (final cat in categories) {
      if (cat.key == categoryKey) {
        for (final opt in cat.options) {
          if (opt.value == value) return opt.label;
        }
        break;
      }
    }
    return value;
  }

  /// Builds validated initial values from stored details, falling back to
  /// the first option in each category when the stored value is invalid.
  static Map<String, String> initialValues(Map<String, dynamic>? details) {
    final String seed = details?['seed']?.toString() ?? _generateRandomSeed();
    final Map<String, String> values = {'seed': seed};
    for (final cat in categories) {
      final stored = details?[cat.key]?.toString();
      final valid = cat.options.any((o) => o.value == stored)
          ? stored!
          : cat.options.first.value;
      values[cat.key] = valid;
    }
    return values;
  }

  /// Builds a DiceBear v10.x toon-head SVG URL from a values map.
  static String buildUrl(Map<String, String> values) {
    String param(String key, [String? value]) {
      final v = value ?? values[key] ?? '';
      if (v.isEmpty) return '';
      // Special probability-based params
      switch (key) {
        case 'facialHair':
          return v == 'none'
              ? 'facialHairProbability=0'
              : 'facialHairProbability=100&facialHair=$v';
        case 'glasses':
          return v == 'none'
              ? 'glassesProbability=0'
              : 'glassesProbability=100&glasses=$v';
        default:
          return '$key=$v';
      }
    }

    final seed = values['seed'] ?? '';
    final parts = <String>[
      'seed=$seed',
      param('skinColor'),
      param('mouth'),
      param('eyebrows'),
      param('eyes'),
      param('hair'),
      param('hairColor'),
      param('facialHair'),
      param('glasses'),
    ];

    final clothingVal = values['clothing'] ?? '';
    if (clothingVal != 'none' && clothingVal.isNotEmpty) {
      parts.add(param('clothing'));
      parts.add(param('clothingColor'));
    }

    return 'https://api.dicebear.com/10.x/toon-head/svg?${parts.where((p) => p.isNotEmpty).join('&')}';
  }

  /// Generates random values for all categories (plus a random seed).
  static Map<String, String> randomize() {
    final random = Random();
    final Map<String, String> values = {'seed': _generateRandomSeed()};
    for (final cat in categories) {
      values[cat.key] = cat.options[random.nextInt(cat.options.length)].value;
    }
    return values;
  }

  static String _generateRandomSeed() {
    final random = Random();
    return List.generate(8, (_) => random.nextInt(10).toString()).join();
  }
}
