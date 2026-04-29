import 'dart:convert';

class SetFilter {
  const SetFilter({
    required this.ratingMin,
    required this.ratingMax,
    required this.themes,
    required this.size,
  });

  final int ratingMin;
  final int ratingMax;
  final List<String> themes;
  final int size;

  String get themesJson => jsonEncode(themes);

  static List<String> parseThemes(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! List) return const [];
    return decoded.cast<String>();
  }
}
