import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sudoku_state.dart';
import 'sudoku_engine.dart';
import 'highscore_screen.dart';
import 'dart:async';

const _accent = Color(0xFFFF8A00);
const _bg = Color(0xFF1E1E1E);

class GameScreen extends StatelessWidget {
  final Difficulty initialDifficulty;
  const GameScreen({super.key, this.initialDifficulty = Difficulty.easy});

  @override
  Widget build(BuildContext context) {
    return const _GameView();
  }
}

class _GameView extends StatefulWidget {
  const _GameView();
  @override
  State<_GameView> createState() => _GameViewState();
}

class _GameViewState extends State<_GameView> with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  late AnimationController _streakController;

  @override
  void initState() { 
    super.initState(); 
    _startTimer(); 
    _streakController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final state = context.read<SudokuState>();
      if (state.isComplete) { 
        _timer?.cancel(); 
      } else {
        setState(() => _elapsed += const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() { 
    _timer?.cancel(); 
    _streakController.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SudokuState>();
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_fmt(_elapsed), style: const TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(width: 20),
            const Icon(Icons.stars, color: _accent, size: 18),
            const SizedBox(width: 4),
            Text("${state.scoreManager.currentScore}", 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _accent)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded, color: Colors.white70),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HighscoreScreen())),
          ),
        ],
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: _StatusRow()),
          const _SudokuBoard(),
          _StreakBar(controller: _streakController),
          const Spacer(),
          const _ActionBar(),
          const SizedBox(height: 16),
          const _NumberPad(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _fmt(Duration d) => 
    "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";
}

class _StreakBar extends StatelessWidget {
  final AnimationController controller;
  const _StreakBar({required this.controller});
  
  @override
  Widget build(BuildContext context) {
    final state = context.watch<SudokuState>();
    final level = state.scoreManager.streakLevel;
    final progress = level / 5.0;
    final isMax = level == 5;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          height: 16,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05), 
            borderRadius: BorderRadius.circular(8),
            border: isMax ? Border.all(color: _accent.withValues(alpha: controller.value), width: 1) : null,
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: (MediaQuery.of(context).size.width - 48) * progress,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: isMax ? [Colors.orange, Colors.yellow] : [Colors.blue, Colors.cyan]),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isMax ? [BoxShadow(color: _accent.withValues(alpha: 0.4 * controller.value), blurRadius: 8)] : [],
                ),
              ),
              Center(
                child: Text(
                  isMax ? "FLOW x2.0" : "STREAK x1.$level",
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, 
                    shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow();
  @override
  Widget build(BuildContext context) {
    final state = context.watch<SudokuState>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _AssistBtn(icon: Icons.select_all, label: 'Select', isOn: state.highlightSelect, onTap: state.toggleHighlightSelect),
        const SizedBox(width: 8),
        _AssistBtn(icon: Icons.grid_on, label: 'Numbers', isOn: state.highlightNumbers, onTap: state.toggleHighlightNumbers),
        const SizedBox(width: 8),
        _AssistBtn(icon: Icons.format_line_spacing, label: 'Lines', isOn: state.highlightLines, onTap: state.toggleHighlightLines),
        const SizedBox(width: 8),
        _AssistBtn(icon: Icons.remove_red_eye, label: 'Errors', isOn: state.showErrors, onTap: state.toggleErrors),
        const SizedBox(width: 8),
        _AssistBtn(icon: Icons.qr_code_scanner, label: 'Scan', isOn: state.scanSudoku, onTap: state.toggleScan),
      ]),
    );
  }
}

class _AssistBtn extends StatelessWidget {
  final IconData icon; final String label; final bool isOn; final VoidCallback onTap;
  const _AssistBtn({required this.icon, required this.label, required this.isOn, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isOn ? _accent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isOn ? _accent : Colors.white10),
        ),
        child: Row(children: [
          Icon(icon, size: 14, color: isOn ? _accent : Colors.white38),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: isOn ? _accent : Colors.white38))
        ]),
      ),
    );
  }
}

class _SudokuBoard extends StatelessWidget {
  const _SudokuBoard();
  @override
  Widget build(BuildContext context) {
    final state = context.watch<SudokuState>();
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8)),
        child: Stack(children: [
          Column(children: List.generate(9, (r) => Expanded(child: Row(children: List.generate(9, (c) => Expanded(child: _Cell(r: r, c: c))))))),
          IgnorePointer(child: CustomPaint(size: Size.infinite, painter: _GridPainter())),
          if (state.isComplete) _SolvedOverlay(score: state.scoreManager.currentScore, difficulty: state.difficulty),
        ]),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final int r, c;
  const _Cell({required this.r, required this.c});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<SudokuState>();
    final cell = state.grid[r][c];
    Color? bg;
    
    if (state.selectedRow == r && state.selectedCol == c) { bg = _accent.withValues(alpha: 0.6); }
    else if (state.isCellSameNumber(r, c)) { bg = _accent.withValues(alpha: 0.3); }
    else if (state.isCellLineBlockedByActiveNumber(r, c)) { bg = Colors.blue.withValues(alpha: 0.15); }
    else if (state.isCellInSelectionArea(r, c)) { bg = Colors.white.withValues(alpha: 0.08); }

    Color textColor;
    if (state.isCellError(r, c)) { textColor = Colors.red; }
    else if (cell.given) { textColor = Colors.white; }
    else if (state.previousPlacedRow == r && state.previousPlacedCol == c) { textColor = Colors.blue; }
    else { textColor = _accent; }

    return GestureDetector(
      onTap: () => state.selectCell(r, c),
      child: Container(
        color: bg,
        alignment: Alignment.center,
        child: cell.value != 0 
          ? Text("${cell.value}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor))
          : _NotesGrid(notes: cell.notes),
      ),
    );
  }
}

class _NotesGrid extends StatelessWidget {
  final Set<int> notes;
  const _NotesGrid({required this.notes});
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3, padding: const EdgeInsets.all(2),
      children: List.generate(9, (i) => Center(child: Text(notes.contains(i+1) ? "${i+1}" : "", 
        style: const TextStyle(fontSize: 8, color: Colors.white54)))),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final thinPaint = Paint()..color = Colors.white10..strokeWidth = 1;
    final thickPaint = Paint()..color = _accent.withValues(alpha: 0.4)..strokeWidth = 3;
    final double step = size.width / 9;
    for (int i = 0; i <= 9; i++) {
      final p = i * step;
      final paint = (i % 3 == 0) ? thickPaint : thinPaint;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), paint);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), paint);
    }
  }
  @override bool shouldRepaint(CustomPainter old) => false;
}

class _ActionBar extends StatelessWidget {
  const _ActionBar();
  @override
  Widget build(BuildContext context) {
    final state = context.watch<SudokuState>();
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _ActionIcon(icon: Icons.undo, label: 'Undo', onTap: state.undo),
      _ActionIcon(icon: Icons.backspace_outlined, label: 'Clear', onTap: () => state.applyNumber(0)),
      _ActionIcon(icon: state.pencilMode ? Icons.edit : Icons.edit_outlined, label: 'Notes', onTap: state.togglePencil, color: state.pencilMode ? _accent : Colors.white70),
      _ActionIcon(icon: Icons.redo, label: 'Redo', onTap: (){}),
    ]);
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap; final Color color;
  const _ActionIcon({required this.icon, required this.label, required this.onTap, this.color = Colors.white70});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Column(children: [Icon(icon, color: color), Text(label, style: TextStyle(color: color, fontSize: 10))]));
  }
}

class _NumberPad extends StatelessWidget {
  const _NumberPad();
  @override
  Widget build(BuildContext context) {
    final state = context.watch<SudokuState>();
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(9, (i) {
      final n = i + 1;
      final isActive = state.activeNumber == n;
      return GestureDetector(
        onTap: () => state.setActiveNumber(n),
        child: Column(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: isActive ? _accent : Colors.white10, shape: BoxShape.circle, border: Border.all(color: isActive ? Colors.white : Colors.transparent, width: 2)),
            alignment: Alignment.center,
            child: Text("$n", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.white)),
          ),
          const SizedBox(height: 4),
          Text("${state.remainingCount(n)}", style: const TextStyle(fontSize: 10, color: Colors.white38)),
        ]),
      );
    }));
  }
}

class _SolvedOverlay extends StatelessWidget {
  final int score;
  final Difficulty difficulty;
  const _SolvedOverlay({required this.score, required this.difficulty});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.emoji_events, color: _accent, size: 80),
        const SizedBox(height: 16),
        const Text("SOLVED!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _accent)),
        Text("Score: $score", style: const TextStyle(fontSize: 24, color: Colors.white)),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black),
          onPressed: () => context.read<SudokuState>().newGame(difficulty), 
          child: const Text("Play Again"),
        ),
      ])),
    );
  }
}