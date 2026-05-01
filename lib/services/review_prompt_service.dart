import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models/global_stats.dart';
import '../data/models/round_comparison.dart';
import 'app_preferences.dart';

class ReviewPromptService {
  ReviewPromptService(this._prefs);

  final Future<SharedPreferences> Function() _prefs;

  static const _packageId = 'com.woodpecker.chess';
  static const _kFirstSeenAt = 'app.reviewPrompt.firstSeenAt';
  static const _kLastPromptAt = 'app.reviewPrompt.lastPromptAt';
  static const _kCompleted = 'app.reviewPrompt.completed';
  static const _kNeverAsk = 'app.reviewPrompt.neverAsk';

  Future<bool> shouldPromptAfterRound({
    required RoundComparison comparison,
    required GlobalStats globalStats,
  }) async {
    final previous = comparison.previous;
    if (previous == null) return false;

    final current = comparison.current;
    if (current.roundNumber < 2) return false;
    if (current.total < 10) return false;
    if (current.accuracy < 0.75) return false;
    if (globalStats.totalRoundsCompleted < 2) return false;
    if (globalStats.totalAttempts < 30) return false;

    final improvedAccuracy = comparison.accuracyDelta >= 0.05;
    final improvedSpeed = comparison.speedupPercent >= 10;
    final savedMeaningfulTime =
        comparison.timeSavings >= const Duration(seconds: 30);
    if (!improvedAccuracy && !improvedSpeed && !savedMeaningfulTime) {
      return false;
    }

    final prefs = await _prefs();
    if (prefs.getBool(_kCompleted) ?? false) return false;
    if (prefs.getBool(_kNeverAsk) ?? false) return false;

    final now = DateTime.now();
    final firstSeenMs = prefs.getInt(_kFirstSeenAt);
    if (firstSeenMs == null) {
      await prefs.setInt(_kFirstSeenAt, now.millisecondsSinceEpoch);
      return false;
    }

    final firstSeen = DateTime.fromMillisecondsSinceEpoch(firstSeenMs);
    if (now.difference(firstSeen) < const Duration(days: 2)) {
      return false;
    }

    final lastPromptMs = prefs.getInt(_kLastPromptAt);
    if (lastPromptMs != null) {
      final lastPrompt = DateTime.fromMillisecondsSinceEpoch(lastPromptMs);
      if (now.difference(lastPrompt) < const Duration(days: 30)) {
        return false;
      }
    }

    return true;
  }

  Future<void> markNotNow() async {
    final prefs = await _prefs();
    await prefs.setInt(_kLastPromptAt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> markNeverAsk() async {
    final prefs = await _prefs();
    await prefs.setBool(_kNeverAsk, true);
    await prefs.setInt(_kLastPromptAt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> markCompleted() async {
    final prefs = await _prefs();
    await prefs.setBool(_kCompleted, true);
    await prefs.setInt(_kLastPromptAt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> openStoreListing() async {
    final marketUri = Uri.parse('market://details?id=$_packageId');
    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$_packageId',
    );
    if (await launchUrl(marketUri, mode: LaunchMode.externalApplication)) {
      return true;
    }
    return launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}

final reviewPromptServiceProvider = Provider<ReviewPromptService>((ref) {
  return ReviewPromptService(() => ref.read(sharedPreferencesProvider.future));
});
