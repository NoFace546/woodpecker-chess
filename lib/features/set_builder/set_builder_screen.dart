import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/set_filter.dart';
import '../../data/repositories/set_repository.dart';
import '../../services/training_recommender.dart';

const _commonThemes = [
  'mate', 'mateIn1', 'mateIn2', 'mateIn3',
  'fork', 'pin', 'skewer', 'discoveredAttack',
  'sacrifice', 'attraction', 'deflection',
  'opening', 'middlegame', 'endgame',
  'short', 'long',
];

const _sizeOptions = [50, 100, 250, 500, 1000];

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

  SetFilter get _currentFilter => SetFilter(
        ratingMin: _ratingRange.start.round(),
        ratingMax: _ratingRange.end.round(),
        themes: _selectedThemes.toList(),
        size: _size,
      );

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
        title: const Text('How recommended training works'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Builds one ~150-puzzle set tailored to you, designed to '
                'be drilled Woodpecker-style across 5–7 rounds.',
              ),
              SizedBox(height: 12),
              Text('Rating range',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                'Your Elo - 200 to your Elo + 100 (comfort zone). Hard '
                'enough to learn from, easy enough to keep momentum.',
              ),
              SizedBox(height: 12),
              Text('Theme mix',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '70% targets your weakest themes (high-confidence weaknesses '
                "from your stats). 30% explores themes we don't have enough "
                'data on yet, so future recommendations stay accurate.',
              ),
              SizedBox(height: 12),
              Text('When to switch',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                'When you hit 90%+ accuracy AND 35%+ faster than round 1, '
                'archive the set and build the next one. Updated stats will '
                'reshape the next set around your current weaknesses.',
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

  Future<void> _buildRecommended() async {
    if (_creating) return;
    setState(() => _creating = true);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Building recommended set…')),
    );
    try {
      final result =
          await ref.read(trainingRecommenderProvider).buildRecommended();
      ref.invalidate(allSetsProvider);
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      context.go('/sets/${result.set.id}');
    } catch (e) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
      setState(() => _creating = false);
    }
  }

  Future<void> _createSet() async {
    if (_creating) return;
    setState(() => _creating = true);
    try {
      final repo = ref.read(setRepositoryProvider);
      final set = await repo.create(_currentFilter);
      ref.invalidate(allSetsProvider);
      if (!mounted) return;
      context.go('/sets/${set.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create set: $e')),
      );
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
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: ListTile(
              leading: const Icon(Icons.fitness_center),
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
              subtitle: const Text(
                  'Targets your current weaknesses, sized for Woodpecker'),
              trailing: _creating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _creating ? null : _buildRecommended,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Or build a custom set',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Text('Rating', style: Theme.of(context).textTheme.titleMedium),
          Text(
            '${_ratingRange.start.round()} – ${_ratingRange.end.round()}',
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
          const SizedBox(height: 16),
          Text('Themes (optional, any match)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final theme in _commonThemes)
                FilterChip(
                  label: Text(theme),
                  selected: _selectedThemes.contains(theme),
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        _selectedThemes.add(theme);
                      } else {
                        _selectedThemes.remove(theme);
                      }
                    });
                    _refreshPreview();
                  },
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
                  : 'Only $_previewCount puzzles match — set will contain all of them.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            OutlinedButton.icon(
              onPressed: _refreshPreview,
              icon: const Icon(Icons.refresh),
              label: const Text('Preview match count'),
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
