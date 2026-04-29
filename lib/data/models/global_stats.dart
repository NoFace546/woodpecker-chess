class GlobalStats {
  const GlobalStats({
    required this.totalRoundsCompleted,
    required this.totalAttempts,
    required this.correctAttempts,
    required this.totalTime,
    required this.totalHints,
  });

  final int totalRoundsCompleted;
  final int totalAttempts;
  final int correctAttempts;
  final Duration totalTime;
  final int totalHints;

  double get accuracy => totalAttempts == 0 ? 0 : correctAttempts / totalAttempts;
}

class SetActivity {
  const SetActivity({
    required this.setId,
    required this.setName,
    required this.roundsCompleted,
    required this.totalAttempts,
    required this.correctAttempts,
  });

  final String setId;
  final String setName;
  final int roundsCompleted;
  final int totalAttempts;
  final int correctAttempts;

  double get accuracy => totalAttempts == 0 ? 0 : correctAttempts / totalAttempts;
}

class DailyActivity {
  const DailyActivity({
    required this.day,
    required this.totalAttempts,
    required this.correctAttempts,
    required this.totalTime,
  });

  final DateTime day;
  final int totalAttempts;
  final int correctAttempts;
  final Duration totalTime;

  double get accuracy => totalAttempts == 0 ? 0 : correctAttempts / totalAttempts;
}
