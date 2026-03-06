import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sudoku_state.dart';
import 'sudoku_engine.dart';
import 'highscore_screen.dart';
import 'dart:async';

const _accent = Color(0xFFFF8A00);
const _bg = Color(0xFF1E1E1E);

// Relax Modus - Nachtozean
const _relaxBg = Color(0xFF0D1B2A);
const _relaxBgTop = Color(0xFF0D2B35);
const _relaxAccent = Color(0xFF4DD0C4);

class GameScreen extends StatelessWidget {
  final Difficulty initialDifficulty;
  final Duration resumedElapsed;
  const GameScreen({super.key, this.initialDifficulty = Difficulty.easy, this.resumedElapsed = Duration.zero});

  @override
  Widget build(BuildContext context) {
    return _GameView(resumedElapsed: resumedElapsed);
  }
}

class _GameView extends StatefulWidget {
  final Duration resumedElapsed;
  const _GameView({this.resumedElapsed = Duration.zero});
  @override
  State<_GameView> createState() => _GameViewState();
}

class _GameViewState extends State<_GameView> with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  late AnimationController _streakController;
  bool _wasComplete = false;
  late SudokuState _state;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state = context.read<SudokuState>();
  }

  @override
  void initState() {
    super.initState();
    _elapsed = widget.resumedElapsed;
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
    if (!_state.isComplete && _state.hasUserProgress) {
      _state.saveCurrentGame(_elapsed);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SudokuState>();
    if (_wasComplete && !state.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _elapsed = Duration.zero);
        _startTimer();
      });
    }
    _wasComplete = state.isComplete;
    final isRelax = state.relaxMode;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isRelax
            ? const [_relaxBgTop, _relaxBg]
            : const [_bg, _bg],
        ),
      ),
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: state.relaxMode
          ? const Icon(Icons.spa_outlined, color: Colors.tealAccent, size: 20)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_fmt(_elapsed), style: const TextStyle(fontSize: 16, color: Colors.white70)),
                const SizedBox(width: 20),
                const Icon(Icons.stars, color: _accent, size: 18),
                const SizedBox(width: 4),
                Text("${state.scoreManager.currentScore}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _accent)),
                const SizedBox(width: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: state.recentPoints > 0
                    ? Text("+${state.recentPoints}",
                        key: ValueKey(state.recentPoints),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.greenAccent))
                    : const SizedBox(width: 32, key: ValueKey(0)),
                ),
              ],
            ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HighscoreScreen())),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: state.activeProfile.color,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(state.activeProfile.initials,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: _StatusRow()),
          const _SudokuBoard(),
          if (!state.relaxMode) _StreakBar(controller: _streakController),
          const SizedBox(height: 8),
          const _ActionBar(),
          const SizedBox(height: 12),
          const _NumberPad(),
          const SizedBox(height: 16),
        ],
      ),
    ));
  }

  String _fmt(Duration d) => 
    "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";
}

class _StreakBar extends StatelessWidget {
  final AnimationController controller;
  const _StreakBar({required this.controller});

  static const _sectionColors = [
    Color(0xFF4CAF50), // grün
    Color(0xFF00BCD4), // cyan
    Color(0xFF2196F3), // blau
    Color(0xFF9C27B0), // lila
    Color(0xFFFF8A00), // orange (FLOW)
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SudokuState>();
    final streakValue = state.scoreManager.streakValue;
    final multiplier = state.scoreManager.scoreMultiplier;
    final isFlow = streakValue >= 4.5;

return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final fillWidth = (streakValue / 5.0) * totalWidth;
                  return Stack(
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 12,
                          width: fillWidth,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: () {
                                final count = ((streakValue / 1.0).ceil()).clamp(1, 5);
                                final cols = _sectionColors.sublist(0, count);
                                return cols.length >= 2 ? cols : [cols[0], cols[0]];
                              }(),
                            ),
                            boxShadow: isFlow ? [BoxShadow(color: _accent.withValues(alpha: 0.4 * controller.value), blurRadius: 8)] : [],
                          ),
                        ),
                      ),
                      ...List.generate(4, (i) {
                        final x = (i + 1) / 5.0 * totalWidth;
                        return Positioned(
                          left: x - 0.5,
                          child: Container(width: 1, height: 12, color: Colors.black.withValues(alpha: 0.4)),
                        );
                      }),
                    ],
                  );
                }),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (state.errorCount >= 3)
                    GestureDetector(
                      onTap: state.showErrorsTemporarily ? null : state.revealAndClearErrors,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: state.showErrorsTemporarily ? 0.35 : 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.6)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 12),
                          const SizedBox(width: 3),
                          Text("${state.errorCount}", style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    )
                  else
                    Text(
                      "x${multiplier.toStringAsFixed(1)}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isFlow ? _accent.withValues(alpha: 0.7 + 0.3 * controller.value) : Colors.white70,
                      ),
                    ),
                  Text(
                    "+${state.nextMovePoints}",
                    style: const TextStyle(fontSize: 10, color: Colors.white38),
                  ),
                ],
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
        _AssistBtn(icon: Icons.lightbulb_outline, label: 'Hint', isOn: false, onTap: state.useHint),
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
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
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
          if (state.lastCompletedBlock != null)
            IgnorePointer(child: CustomPaint(size: Size.infinite, painter: _BlockCompletePainter(state.lastCompletedBlock!))),
          if (state.isComplete) _SolvedOverlay(score: state.scoreManager.currentScore, difficulty: state.difficulty, isNewRecord: state.isNewRecord),
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
      _ActionIcon(icon: Icons.bolt, label: 'Quick', onTap: state.toggleQuickMode, color: state.quickMode ? _accent : Colors.white70),
      _ActionIcon(icon: Icons.redo, label: 'Redo', onTap: state.redo),
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
      final remaining = state.remainingCount(n);
      final used = remaining == 0;
      return GestureDetector(
        onTap: used ? null : () => state.setActiveNumber(n),
        child: Column(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: used ? Colors.transparent : (isActive ? _accent : Colors.white10),
              shape: BoxShape.circle,
              border: Border.all(color: used ? Colors.white12 : (isActive ? Colors.white : Colors.transparent), width: 2),
            ),
            alignment: Alignment.center,
            child: Text("$n", style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold,
              color: used ? Colors.white12 : (isActive ? Colors.black : Colors.white),
              decoration: used ? TextDecoration.lineThrough : null,
              decorationColor: Colors.white24,
            )),
          ),
          const SizedBox(height: 4),
          Text(used ? "✓" : "$remaining",
            style: TextStyle(fontSize: 10, color: used ? Colors.green.withValues(alpha: 0.6) : Colors.white38)),
        ]),
      );
    }));
  }
}

class _BlockCompletePainter extends CustomPainter {
  final int blockIndex;
  _BlockCompletePainter(this.blockIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final br = (blockIndex ~/ 3) * 3;
    final bc = (blockIndex % 3) * 3;
    final step = size.width / 9;
    final rect = Rect.fromLTWH(bc * step, br * step, 3 * step, 3 * step);
    final paint = Paint()
      ..color = const Color(0xFFFF8A00).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
    final border = Paint()
      ..color = const Color(0xFFFF8A00).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), border);
  }

  @override bool shouldRepaint(_BlockCompletePainter old) => old.blockIndex != blockIndex;
}

class _SolvedOverlay extends StatelessWidget {
  final int score;
  final Difficulty difficulty;
  final bool isNewRecord;
  const _SolvedOverlay({required this.score, required this.difficulty, required this.isNewRecord});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SudokuState>();
    final sm = state.scoreManager;
    final isRelax = state.relaxMode;
    final isPerfect = state.errorCount == 0;

    // Ø Vergleich (gleiche Schwierigkeit + relax/normal)
    final myEntries = state.profileEntries(state.activeProfile.initials)
        .where((e) => e.difficulty == difficulty.name && e.isRelax == isRelax).toList();
    final myAvg = myEntries.isEmpty ? 0 : (myEntries.map((e) => e.score).reduce((a,b)=>a+b) / myEntries.length).round();
    final globalEntries = state.highscores.where((e) => e.difficulty == difficulty.name && e.isRelax == isRelax).toList();
    final globalAvg = globalEntries.isEmpty ? 0 : (globalEntries.map((e) => e.score).reduce((a,b)=>a+b) / globalEntries.length).round();

    final vsMyAvg = myAvg > 0 ? ((score - myAvg) / myAvg * 100).round() : null;
    final vsGlobal = globalAvg > 0 ? ((score - globalAvg) / globalAvg * 100).round() : null;

    return Container(
      color: Colors.black.withValues(alpha: 0.92),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(children: [
            Icon(isRelax ? Icons.spa_outlined : Icons.emoji_events,
              color: isRelax ? _relaxAccent : _accent, size: 60),
            const SizedBox(height: 8),
            Text("SOLVED!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
              color: isRelax ? _relaxAccent : _accent)),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (isRelax) ...[
                const Icon(Icons.spa_outlined, color: _relaxAccent, size: 13),
                const SizedBox(width: 4),
                const Text("Relax", style: TextStyle(color: _relaxAccent, fontSize: 12)),
                const SizedBox(width: 12),
              ],
              if (isPerfect) ...[
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 13),
                const SizedBox(width: 4),
                const Text("Fehlerfrei", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
              ],
            ]),
            if (isNewRecord) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.star, color: Colors.amber, size: 14),
                  SizedBox(width: 5),
                  Text("NEUER REKORD!", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(width: 5),
                  Icon(Icons.star, color: Colors.amber, size: 14),
                ]),
              ),
            ],
            const SizedBox(height: 20),
            // Score Aufschlüsselung
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                _ScoreLine("Startpunkte", sm.startingScore, color: Colors.white54),
                _ScoreLine("Richtige Züge", sm.earnedFromMoves, prefix: "+", color: Colors.greenAccent),
                _ScoreLine("Zeitabzug", -sm.lostFromTime, prefix: "−", color: Colors.white38),
                if (sm.lostFromHints > 0) _ScoreLine("Hints", -sm.lostFromHints, prefix: "−", color: Colors.orange),
                if (sm.lostFromErrors > 0) _ScoreLine("Fehler", -sm.lostFromErrors, prefix: "−", color: Colors.red),
                const Divider(color: Colors.white12, height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("GESAMT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text("$score", style: TextStyle(color: isRelax ? _relaxAccent : _accent,
                    fontWeight: FontWeight.bold, fontSize: 18)),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            // Vergleich
            if (vsMyAvg != null || vsGlobal != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  if (vsMyAvg != null) _CompareRow("vs. mein Ø", vsMyAvg),
                  if (vsGlobal != null) _CompareRow("vs. Gesamt-Ø", vsGlobal),
                ]),
              ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white54, side: const BorderSide(color: Colors.white24)),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Menü"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black),
                onPressed: () => context.read<SudokuState>().newGame(difficulty),
                child: const Text("Nochmal"),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _ScoreLine extends StatelessWidget {
  final String label;
  final int value;
  final String prefix;
  final Color color;
  const _ScoreLine(this.label, this.value, {this.prefix = "", this.color = Colors.white70});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: color, fontSize: 13)),
        Text("$prefix${value.abs()}", style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final int percent;
  const _CompareRow(this.label, this.percent);
  @override
  Widget build(BuildContext context) {
    final better = percent >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Row(children: [
          Icon(better ? Icons.arrow_upward : Icons.arrow_downward,
            color: better ? Colors.greenAccent : Colors.redAccent, size: 13),
          Text("${percent.abs()}%",
            style: TextStyle(color: better ? Colors.greenAccent : Colors.redAccent,
              fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }
}