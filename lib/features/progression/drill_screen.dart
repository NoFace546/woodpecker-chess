import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/puzzle_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../solve/puzzle.dart';
import '../solve/solve_board_controller.dart';
import '../solve/solve_board_widget.dart';
import '../solve/solve_state.dart';

class DrillScreen extends ConsumerStatefulWidget {
  const DrillScreen({super.key, required this.setId});

  final String setId;

  @override
  ConsumerState<DrillScreen> createState() => _DrillScreenState();
}

class _DrillScreenState extends ConsumerState<DrillScreen> {
  List<String> _puzzleIds = const [];
  final List<bool> _outcomes = [];
  Puzzle? _puzzle;
  int _index = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final statsRepo = ref.read(statsRepositoryProvider);
      final problems = await statsRepo.problemPuzzlesForSet(widget.setId);
      final ids = problems.map((p) => p.puzzleId).toList()..shuffle(Random());
      if (ids.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
        });
        return;
      }
      final puzzleRepo = ref.read(puzzleRepositoryProvider);
      final first = await puzzleRepo.getById(ids.first);
      if (!mounted) return;
      setState(() {
        _puzzleIds = ids;
        _puzzle = first;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onResult(SolveResult result) {
    setState(() {
      while (_outcomes.length <= _index) {
        _outcomes.add(false);
      }
      _outcomes[_index] = result.isCorrect;
    });
  }

  Future<void> _next() async {
    final newIndex = _index + 1;
    if (newIndex >= _puzzleIds.length) {
      _showDone();
      return;
    }
    final puzzleRepo = ref.read(puzzleRepositoryProvider);
    final next = await puzzleRepo.getById(_puzzleIds[newIndex]);
    if (!mounted) return;
    setState(() {
      _index = newIndex;
      _puzzle = next;
    });
  }

  void _showDone() {
    final correct = _outcomes.where((o) => o).length;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Drill complete'),
        content: Text(
            'You got $correct / ${_puzzleIds.length} on this drill pass.\n'
            'Solve them in a real round to remove them from the problem list.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) context.pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_puzzleIds.isEmpty
            ? 'Drill'
            : 'Drill • ${_index + 1}/${_puzzleIds.length}'),
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_puzzleIds.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No problem puzzles yet — keep playing rounds and come back '
            'when there are some to drill.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_puzzle == null) {
      return const Center(child: Text('No puzzle at this position'));
    }
    return SolveBoardWidget(
      key: ValueKey('drill-${_puzzle!.id}-$_index'),
      puzzle: _puzzle!,
      onResult: _onResult,
      statusBarBuilder: (context, state, controller) => _DrillStatusBar(
        state: state,
        controller: controller,
        index: _index,
        total: _puzzleIds.length,
        onContinue: _next,
      ),
    );
  }
}

class _DrillStatusBar extends StatelessWidget {
  const _DrillStatusBar({
    required this.state,
    required this.controller,
    required this.index,
    required this.total,
    required this.onContinue,
  });

  final SolveState state;
  final SolveBoardController controller;
  final int index;
  final int total;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final feedback = solveStatusFeedback(context, state);
    final canContinue = state.status == SolveStatus.solved ||
        state.status == SolveStatus.wrong ||
        state.status == SolveStatus.inaccuracy ||
        state.status == SolveStatus.almostBest ||
        state.status == SolveStatus.revealed;
    final isLast = index + 1 >= total;
    return Container(
      width: double.infinity,
      color: feedback.color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              feedback.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (state.status == SolveStatus.evaluating)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          if (canShowSolution(state.status))
            TextButton.icon(
              onPressed: controller.revealSolution,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Show solution'),
            ),
          if (canContinue)
            FilledButton.icon(
              onPressed: onContinue,
              icon: Icon(isLast ? Icons.flag : Icons.skip_next),
              label: Text(isLast ? 'Finish drill' : 'Next'),
            ),
        ],
      ),
    );
  }
}
