class TextUtils {
  TextUtils._();

  static String? normalize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  static String countLabel(int count, String singular, String plural) {
    final label = count == 1 ? singular : plural;
    return '$count $label';
  }

  static String greetingWithOptionalName(String greeting, {String? name}) {
    final normalizedName = normalize(name);
    if (normalizedName == null) return '$greeting!';
    return '$greeting, $normalizedName!';
  }
}
