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
  final bool optional;

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

  static const List<AvatarTrait> beardVariant = [
    AvatarTrait('chin', 'Chin'),
    AvatarTrait('chinMoustache', 'Chin Moustache'),
    AvatarTrait('fullBeard', 'Full Beard'),
    AvatarTrait('longBeard', 'Long Beard'),
    AvatarTrait('moustacheTwirl', 'Moustache Twirl'),
  ];

  static const List<AvatarTrait> clothesVariant = [
    AvatarTrait('dress', 'Dress'),
    AvatarTrait('openJacket', 'Open Jacket'),
    AvatarTrait('shirt', 'Shirt'),
    AvatarTrait('tShirt', 'T Shirt'),
    AvatarTrait('turtleNeck', 'Turtle Neck'),
  ];

  static const List<AvatarTrait> eyebrowsVariant = [
    AvatarTrait('angry', 'Angry'),
    AvatarTrait('happy', 'Happy'),
    AvatarTrait('neutral', 'Neutral'),
    AvatarTrait('raised', 'Raised'),
    AvatarTrait('sad', 'Sad'),
  ];

  static const List<AvatarTrait> eyesVariant = [
    AvatarTrait('bow', 'Bow'),
    AvatarTrait('happy', 'Happy'),
    AvatarTrait('humble', 'Humble'),
    AvatarTrait('wide', 'Wide'),
    AvatarTrait('wink', 'Wink'),
  ];

  static const List<AvatarTrait> hairVariant = [
    AvatarTrait('bun', 'Bun'),
    AvatarTrait('sideComed', 'Side Comed'),
    AvatarTrait('spiky', 'Spiky'),
    AvatarTrait('undercut', 'Undercut'),
  ];

  static const List<AvatarTrait> mouthVariant = [
    AvatarTrait('agape', 'Agape'),
    AvatarTrait('angry', 'Angry'),
    AvatarTrait('laugh', 'Laugh'),
    AvatarTrait('sad', 'Sad'),
    AvatarTrait('smile', 'Smile'),
  ];

  static const List<AvatarTrait> clothesColor = [
    AvatarTrait('151613', 'Jet Black'),
    AvatarTrait('0b3286', 'Royal Blue'),
    AvatarTrait('545454', 'Charcoal Gray'),
    AvatarTrait('147f3c', 'Forest Green'),
    AvatarTrait('f97316', 'Orange'),
    AvatarTrait('ec4899', 'Pink'),
    AvatarTrait('731ac3', 'Purple'),
    AvatarTrait('b11f1f', 'Crimson'),
    AvatarTrait('e8e9e6', 'Off White'),
    AvatarTrait('eab308', 'Gold'),
  ];

  static const List<AvatarTrait> hairColor = [
    AvatarTrait('2c1b18', 'Black Brown'),
    AvatarTrait('d6b370', 'Honey Blonde'),
    AvatarTrait('724133', 'Chestnut Brown'),
    AvatarTrait('a55728', 'Auburn'),
    AvatarTrait('b58143', 'Light Brown'),
  ];

  static const List<AvatarTrait> skinColor = [
    AvatarTrait('5c3829', 'Deep Cocoa'),
    AvatarTrait('f1c3a5', 'Fair Peach'),
    AvatarTrait('a36b4f', 'Warm Brown'),
    AvatarTrait('c68e7a', 'Medium Tan'),
    AvatarTrait('b98e6a', 'Sand Brown'),
  ];

  /// Ordered list of categories used to build the customizer UI and
  /// serialize/deserialize avatar details.
  static const List<AvatarCategory> categories = [
    AvatarCategory(label: 'Beard', key: 'beardVariant', options: beardVariant),
    AvatarCategory(
      label: 'Clothes',
      key: 'clothesVariant',
      options: clothesVariant,
    ),
    AvatarCategory(
      label: 'Eyebrows',
      key: 'eyebrowsVariant',
      options: eyebrowsVariant,
    ),
    AvatarCategory(label: 'Eyes', key: 'eyesVariant', options: eyesVariant),
    AvatarCategory(label: 'Hair', key: 'hairVariant', options: hairVariant),
    AvatarCategory(label: 'Mouth', key: 'mouthVariant', options: mouthVariant),
    AvatarCategory(
      label: 'Clothes Color',
      key: 'clothesColor',
      options: clothesColor,
    ),
    AvatarCategory(label: 'Hair Color', key: 'hairColor', options: hairColor),
    AvatarCategory(label: 'Skin Color', key: 'skinColor', options: skinColor),
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
      return '$key=$v';
    }

    String component(String key, String probabilityKey) {
      final value = values[key] ?? '';
      if (value.isEmpty) return '';
      return '$probabilityKey=100&$key=$value';
    }

    final seed = values['seed'] ?? '';
    final parts = <String>[
      'seed=$seed',
      component('beardVariant', 'beardProbability'),
      component('clothesVariant', 'clothesProbability'),
      component('eyebrowsVariant', 'eyebrowsProbability'),
      component('eyesVariant', 'eyesProbability'),
      component('hairVariant', 'hairProbability'),
      component('mouthVariant', 'mouthProbability'),
      param('clothesColor'),
      param('hairColor'),
      param('skinColor'),
    ];

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
