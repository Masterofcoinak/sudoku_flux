import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sudoku_state.dart';
import 'user_model.dart';

const _accent = Color(0xFFFF8A00);
const _bg = Color(0xFF1E1E1E);
const _card = Color(0xFF252525);

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SudokuState>();
    final profile = state.activeProfile;
    final entries = state.profileEntries(profile.initials);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Statistik", style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad + 16),
        children: [
          // Profil-Banner
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: profile.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: profile.color.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              CircleAvatar(backgroundColor: profile.color, radius: 22,
                child: Text(profile.initials, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14))),
              const SizedBox(width: 12),
              Text(profile.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ),

          // Streak-Karten
          Row(children: [
            Expanded(child: _StreakCard(
              icon: Icons.local_fire_department,
              color: Colors.orange,
              label: "Tages-Streak",
              value: "${state.dayStreak()}",
              sub: "Tage hintereinander",
            )),
            const SizedBox(width: 12),
            Expanded(child: _StreakCard(
              icon: Icons.emoji_events,
              color: _accent,
              label: "Spiele gesamt",
              value: "${entries.length}",
              sub: "${entries.where((e) => e.isPerfect).length} fehlerfrei",
            )),
          ]),
          const SizedBox(height: 12),

          // Pro Schwierigkeit
          _Section(title: "PRO SCHWIERIGKEIT", children: [
            _DiffStats(label: "Easy", color: Colors.green, entries: entries, diff: "easy"),
            _DiffStats(label: "Medium", color: Colors.blue, entries: entries, diff: "medium"),
            _DiffStats(label: "Hard", color: Colors.orange, entries: entries, diff: "hard"),
            _DiffStats(label: "Expert", color: Colors.red, entries: entries, diff: "expert"),
          ]),

          // Letzte Spiele
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 8),
            _Section(title: "LETZTE SPIELE", children: [
              ...entries.reversed.take(10).map((e) => _RecentEntry(e)),
            ]),
          ],
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value, sub;
  const _StreakCard({required this.icon, required this.color, required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ]),
    );
  }
}

class _DiffStats extends StatelessWidget {
  final String label, diff;
  final Color color;
  final List<HighscoreEntry> entries;
  const _DiffStats({required this.label, required this.color, required this.entries, required this.diff});

  @override
  Widget build(BuildContext context) {
    final filtered = entries.where((e) => e.difficulty == diff).toList();
    final normal = filtered.where((e) => !e.isRelax).toList();
    final relax = filtered.where((e) => e.isRelax).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    final bestNormal = normal.isEmpty ? 0 : normal.map((e) => e.score).reduce((a,b) => a>b?a:b);
    final bestRelax = relax.isEmpty ? 0 : relax.map((e) => e.score).reduce((a,b) => a>b?a:b);
    final avgAll = filtered.isEmpty ? 0 : (filtered.map((e) => e.score).reduce((a,b)=>a+b) / filtered.length).round();
    final perfect = filtered.where((e) => e.isPerfect).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          const Spacer(),
          Text("${filtered.length} Spiele", style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          _StatChip("Ø $avgAll", Colors.white54),
          const SizedBox(width: 8),
          if (bestNormal > 0) _StatChip("Rekord $bestNormal", color),
          if (bestRelax > 0) ...[
            const SizedBox(width: 8),
            _StatChip("🌿 $bestRelax", const Color(0xFF4DD0C4)),
          ],
          if (perfect > 0) ...[
            const SizedBox(width: 8),
            _StatChip("✓ $perfect", Colors.greenAccent),
          ],
        ]),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip(this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }
}

class _RecentEntry extends StatelessWidget {
  final HighscoreEntry e;
  const _RecentEntry(this.e);

  static const _diffColors = {
    'easy': Colors.green, 'medium': Colors.blue,
    'hard': Colors.orange, 'expert': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final color = _diffColors[e.difficulty] ?? Colors.white;
    final dt = e.date;
    final dateStr = "${dt.day.toString().padLeft(2,'0')}.${dt.month.toString().padLeft(2,'0')}. ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Text(e.difficulty[0].toUpperCase() + e.difficulty.substring(1),
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        if (e.isRelax) ...[
          const SizedBox(width: 6),
          const Text("🌿", style: TextStyle(fontSize: 10)),
        ],
        if (e.isPerfect) ...[
          const SizedBox(width: 4),
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 11),
        ],
        const Spacer(),
        Text("${e.score}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        Text(dateStr, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final visible = children.where((w) => w is! SizedBox).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
        child: Text(title, style: const TextStyle(color: Colors.white38, fontSize: 11,
          fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ),
      Container(
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)),
        child: Column(children: List.generate(children.length, (i) => Column(children: [
          children[i],
          if (i < children.length - 1 && children[i] is! SizedBox)
            const Divider(height: 1, color: Colors.white10, indent: 16),
        ]))),
      ),
    ]);
  }
}
