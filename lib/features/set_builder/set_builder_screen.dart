import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/set_filter.dart';
import '../../data/models/theme_definitions.dart';
import '../../data/repositories/set_repository.dart';
import '../../data/repositories/user_state_repository.dart';
import '../../services/pro_status.dart';
import '../../services/training_recommender.dart';
import '../paywall/paywall_screen.dart';
import '../strengths/widgets/theme_explainer_sheet.dart';

// Recommended training is now the broad calibration tool itself, so it is
// available from a fresh account. Kept as a constant in case the threshold
// returns later.
const _recommendedUnlockAttempts = 0;

// Free tier - the most common motifs a club player would pick.
const _freeThemes = [
  'mate', 'mateIn1', 'mateIn2',
  'fork', 'pin', 'skewer',
  'opening', 'middlegame', 'endgame',
  'short', 'long',
];

// Shown above the "View all" expander. Free + a few popular Pro motifs.
const _commonThemes = [
  ..._freeThemes,
  'mateIn3',
  'discoveredAttack', 'sacrifice', 'attraction', 'deflection',
];

const _sizeOptions = [50, 100, 250, 500, 1000];

const _recommendedSizeOptions = [
  _RecommendedSizeOption(
    size: 50,
    label: 'Focused',
    subtitle: 'Shorter drill. Faster to repeat, but easier to memorize.',
  ),
  _RecommendedSizeOption(
    size: 150,
    label: 'Recommended',
    subtitle: 'Best balance for learning patterns instead of single answers.',
    recommended: true,
  ),
  _RecommendedSizeOption(
    size: 300,
    label: 'Deep',
    subtitle: 'More coverage for a longer training cycle.',
  ),
];

// Themes from kThemeDefinitions that aren't already in the common list.
final List<String> _allOtherThemes = () {
  final common = _commonThemes.toSet();
  final extras = kThemeDefinitions.keys
      .where((t) => !common.contains(t))
      .toList()
    ..sort();
  return extras;
}();

class SetBuilderScreen extends ConsumerStatefulWidget {
  const SetBuilderScreen({super.key});

  @override
  ConsumerState<SetBuilderScreen> createState() => _SetBuilderScreenState();
}

class _SetBuilderScreenState extends ConsumerState<SetBuilderScreen> {
  RangeValues _ratingRange = const RangeValues(1400, 1800);
  final Set<String> _selectedThemes = {};
  int _size = 100;
  int? _previewCount;
  bool _previewLoading = false;
  bool _creating = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  SetFilter get _currentFilter => SetFilter(
        ratingMin: _ratingRange.start.round(),
        ratingMax: _ratingRange.end.round(),
        themes: _selectedThemes.toList(),
        size: _size,
      );

  Widget _themeChip(String theme) {
    final isProTheme = !_freeThemes.contains(theme);
    final isPro = ref.watch(isProProvider);
    final locked = isProTheme && !isPro;
    final selected = _selectedThemes.contains(theme);
    final scheme = Theme.of(context).colorScheme;
    final bg = selected
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;

    void toggle() {
      if (locked) {
        PaywallScreen.show(
          context,
          headline: 'Unlock all tactical themes',
          subhead:
              'Free includes the core motifs. Pro unlocks 40+ named '
              'mating patterns, advanced motifs and phase-specific '
              'endgame themes.',
        );
        return;
      }
      setState(() {
        if (selected) {
          _selectedThemes.remove(theme);
        } else {
          _selectedThemes.add(theme);
        }
      });
      _refreshPreview();
    }

    return Material(
      color: bg,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? scheme.primary.withValues(alpha: 0.6)
              : scheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: toggle,
        onLongPress: () => ThemeExplainerSheet.show(context, theme),
        customBorder: const StadiumBorder(),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (locked) ...[
                Icon(Icons.lock_outline, size: 14, color: fg),
                const SizedBox(width: 4),
              ],
              if (selected && !locked) ...[
                Icon(Icons.check, size: 14, color: fg),
                const SizedBox(width: 4),
              ],
              Text(
                theme,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w600 : null,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshPreview() async {
    setState(() {
      _previewLoading = true;
      _previewCount = null;
    });
    final repo = ref.read(setRepositoryProvider);
    try {
      final count = await repo.previewSize(_currentFilter);
      if (!mounted) return;
      setState(() {
        _previewCount = count;
        _previewLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _previewLoading = false);
    }
  }

  void _showRecommendedExplainer() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How Recommended training is built'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Data-driven, not generic',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text(
                'Recommended training is built from your own attempt '
                'history. The recommender reads every puzzle you have '
                'solved and uses statistics to find where you actually '
                'struggle.',
              ),
              SizedBox(height: 12),
              Text('Weakness detection',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text(
                'Each tactical theme gets a weakness score from:\n'
                '• Wilson lower-bound on your correct-ratio (the same '
                'statistic Lichess uses - suppresses noise from small '
                'samples)\n'
                '• A 50/50 blend of lifetime and recent attempts, so '
                'recent play is weighted up\n'
                '• 70 % accuracy gap + 30 % speed penalty vs your baseline\n\n'
                'Themes with too few attempts are flagged low-confidence '
                'and held out of the drill pool.',
              ),
              SizedBox(height: 12),
              Text('Adaptive drill / explore split',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text(
                'The mix between drilling confirmed weaknesses and probing '
                'untested themes shifts with how much data the recommender '
                'has on you:\n\n'
                '• Calibration - fresh account, mostly exploration so the '
                'recommender learns your shape\n'
                '• Discovery - balanced drill and explore once a few '
                'weaknesses surface\n'
                '• Refinement - heavy drill on confirmed weaknesses, '
                'light exploration on the side\n'
                '• Mastery - almost pure drill on the few weaknesses left '
                'after deep history\n\n'
                'You move into the next mode automatically as your '
                'attempt history grows.',
              ),
              SizedBox(height: 12),
              Text('Difficulty band',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text(
                'Puzzles are picked from a band around your current Elo, '
                'biased toward the harder side. Marginal learning comes '
                'from slightly above your level, not below.',
              ),
              SizedBox(height: 12),
              Text('Size',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text(
                '150 puzzles - calibrated to be drilled 5-7 times over a '
                "few weeks (Smith and Tikkanen's Woodpecker cadence).",
              ),
              SizedBox(height: 12),
              Text('Custom set vs Recommended',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text(
                'Custom: you pick rating and theme manually.\n'
                'Recommended: the app reads your data, computes per-theme '
                'scores, and builds a set you could not replicate by hand '
                'without doing the math yourself.',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<int?> _pickRecommendedSize() {
    var selected = 150;
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) => SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Build recommended set',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Smaller sets are faster. Larger sets reduce '
                      'memorization and teach the theme more reliably.',
                      style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    for (final option in _recommendedSizeOptions)
                      _RecommendedSizeTile(
                        option: option,
                        selected: selected == option.size,
                        onTap: () {
                          setModalState(() => selected = option.size);
                        },
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(ctx, selected),
                        icon: const Icon(Icons.fitness_center),
                        label: const Text('Build set'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _buildRecommended() async {
    if (_creating) return;
    // Gate: free tier gets 1 recommended set ever. Detect by checking for any
    // existing set named "Recommended · …" across active + archived.
    if (!ref.read(isProProvider)) {
      final active = await ref.read(setRepositoryProvider).listAll();
      final archived = await ref.read(setRepositoryProvider).listArchived();
      final hasRecommended = [...active, ...archived]
          .any((s) => s.name.startsWith('Recommended ·'));
      if (hasRecommended) {
        if (!mounted) return;
        await PaywallScreen.show(
          context,
          headline: 'Unlock unlimited Recommended training',
          subhead:
              'Your first recommended set is free. Pro lets you regenerate '
              'a fresh, weakness-targeted set whenever your stats evolve.',
        );
        return;
      }
    }
    final targetSize = await _pickRecommendedSize();
    if (targetSize == null || !mounted) return;
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _creating = true);
    messenger.showSnackBar(
      const SnackBar(content: Text('Building recommended set…')),
    );
    try {
      final result =
          await ref
              .read(trainingRecommenderProvider)
              .buildRecommended(targetSize: targetSize);
      ref.invalidate(allSetsProvider);
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      router.go('/sets/${result.set.id}');
    } catch (e) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      debugPrint('Recommended set build failed: $e');
      messenger.showSnackBar(const SnackBar(
        content: Text('Could not build recommended set. Try again.'),
        behavior: SnackBarBehavior.floating,
      ));
      setState(() => _creating = false);
    }
  }

  Future<void> _createSet() async {
    if (_creating) return;
    // Gate: free tier allows 1 active custom set. Recommended sets don't
    // count against the cap so the user can experience both flows once.
    if (!ref.read(isProProvider)) {
      final active = await ref.read(setRepositoryProvider).listAll();
      final customCount =
          active.where((s) => !s.name.startsWith('Recommended ·')).length;
      if (customCount >= 1) {
        if (!mounted) return;
        await PaywallScreen.show(
          context,
          headline: 'Unlock unlimited custom sets',
          subhead:
              'Free includes 1 active custom set. Pro removes the limit and '
              'unlocks every tactical theme.',
        );
        return;
      }
    }
    setState(() => _creating = true);
    try {
      final repo = ref.read(setRepositoryProvider);
      final customName = _nameController.text.trim();
      final set = await repo.create(
        _currentFilter,
        name: customName.isEmpty ? null : customName,
      );
      ref.invalidate(allSetsProvider);
      if (!mounted) return;
      context.go('/sets/${set.id}');
    } catch (e) {
      if (!mounted) return;
      debugPrint('Set create failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not create set. Try again.'),
        behavior: SnackBarBehavior.floating,
      ));
      setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New puzzle set')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Builder(builder: (_) {
            final user = ref.watch(userStateProvider).value;
            final attempts = user?.attemptsTotal ?? 0;
            final unlocked = attempts >= _recommendedUnlockAttempts;
            return Card(
              color: unlocked
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHigh,
              child: ListTile(
                leading: Icon(
                  unlocked ? Icons.fitness_center : Icons.lock_outline,
                ),
                title: Row(
                  children: [
                    const Expanded(child: Text('Recommended training')),
                    InkWell(
                      onTap: _showRecommendedExplainer,
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.info_outline, size: 18),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  unlocked
                      ? 'Targets your current weaknesses, sized for Woodpecker'
                      : 'Unlocks after $_recommendedUnlockAttempts attempts '
                          '($attempts/$_recommendedUnlockAttempts). Solve '
                          'random puzzles to calibrate first.',
                ),
                trailing: _creating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(unlocked
                        ? Icons.chevron_right
                        : Icons.lock_outline),
                onTap: !unlocked || _creating ? null : _buildRecommended,
              ),
            );
          }),
          const SizedBox(height: 16),
          Text(
            'Or build a custom set',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Text('Rating', style: Theme.of(context).textTheme.titleMedium),
          Text(
            '${_ratingRange.start.round()} - ${_ratingRange.end.round()}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          RangeSlider(
            values: _ratingRange,
            min: 600,
            max: 3000,
            divisions: 48,
            labels: RangeLabels(
              _ratingRange.start.round().toString(),
              _ratingRange.end.round().toString(),
            ),
            onChanged: (v) => setState(() => _ratingRange = v),
            onChangeEnd: (_) => _refreshPreview(),
          ),
          _RatingRangeWarning(range: _ratingRange),
          const SizedBox(height: 16),
          Text('Themes (optional, any match)',
              style: Theme.of(context).textTheme.titleMedium),
          Text(
            'Long-press a theme to see its explanation.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final theme in _commonThemes) _themeChip(theme),
            ],
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 4),
            title: const Text('View all themes'),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final theme in _allOtherThemes) _themeChip(theme),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Size', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              for (final s in _sizeOptions)
                ButtonSegment(value: s, label: Text('$s')),
            ],
            selected: {_size},
            onSelectionChanged: (sel) {
              setState(() => _size = sel.first);
            },
          ),
          const SizedBox(height: 24),
          if (_previewLoading)
            const LinearProgressIndicator()
          else if (_previewCount != null)
            Text(
              _previewCount! >= _size
                  ? 'About $_previewCount puzzles match. Set will contain $_size of them.'
                  : 'Only $_previewCount puzzles match, set will contain all of them.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            OutlinedButton.icon(
              onPressed: _refreshPreview,
              icon: const Icon(Icons.refresh),
              label: const Text('Preview match count'),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Set name (optional)',
              hintText: 'Leave blank for auto-generated name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _creating || _previewCount == 0 ? null : _createSet,
            icon: _creating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('Create set'),
          ),
        ],
      ),
    );
  }
}

class _RecommendedSizeOption {
  const _RecommendedSizeOption({
    required this.size,
    required this.label,
    required this.subtitle,
    this.recommended = false,
  });

  final int size;
  final String label;
  final String subtitle;
  final bool recommended;
}

class _RecommendedSizeTile extends StatelessWidget {
  const _RecommendedSizeTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _RecommendedSizeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${option.label} - ${option.size} puzzles',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          if (option.recommended) ...[
                            const SizedBox(width: 8),
                            const _RecommendedBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendedBadge extends StatelessWidget {
  const _RecommendedBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Best',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _RatingRangeWarning extends ConsumerWidget {
  const _RatingRangeWarning({required this.range});
  final RangeValues range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userStateProvider).value;
    if (user == null) return const SizedBox.shrink();
    final elo = user.elo;
    final lo = range.start.round();
    final hi = range.end.round();
    String? msg;
    bool isHard = false;
    if (lo > elo + 300) {
      msg = 'This range is well above your Elo ($elo). '
          'You may struggle to solve enough puzzles to improve.';
      isHard = true;
    } else if (hi < elo - 300) {
      msg = 'This range is well below your Elo ($elo). '
          'Puzzles may feel too easy to push your training.';
    }
    if (msg == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final bg = isHard
        ? scheme.errorContainer.withValues(alpha: 0.6)
        : scheme.surfaceContainerHigh;
    final fg = isHard ? scheme.onErrorContainer : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isHard ? Icons.warning_amber_rounded : Icons.info_outline,
              size: 18,
              color: fg,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
