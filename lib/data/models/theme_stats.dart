class ThemeStats {
  const ThemeStats({
    required this.theme,
    required this.total,
    required this.correct,
    required this.averageTime,
  });

  final String theme;
  final int total;
  final int correct;
  final Duration averageTime;

  double get accuracy => total == 0 ? 0 : correct / total;
}
