import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sudoku_state.dart';
import 'user_model.dart';

class HighscoreScreen extends StatelessWidget {
  const HighscoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scores = context.watch<SudokuState>().highscores;
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text("Highscores"),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xFFFF8A00),
            tabs: [
              Tab(text: "Mix"),
              Tab(text: "Easy"),
              Tab(text: "Medium"),
              Tab(text: "Hard"),
              Tab(text: "Expert"),
            ],
          ),
        ),
        body: TabBarView(children: [
          _List(items: scores),
          _List(items: scores.where((e) => e.difficulty == "easy").toList()),
          _List(items: scores.where((e) => e.difficulty == "medium").toList()),
          _List(items: scores.where((e) => e.difficulty == "hard").toList()),
          _List(items: scores.where((e) => e.difficulty == "expert").toList()),
        ]),
      ),
    );
  }
}

class _List extends StatelessWidget {
  final List<HighscoreEntry> items;
  const _List({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text("Noch keine Einträge", style: TextStyle(color: Colors.white24)),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (c, i) => ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFF8A00).withValues(alpha: 0.2),
          child: Text("${i + 1}", style: const TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold)),
        ),
        title: Text(items[i].userName, style: const TextStyle(color: Colors.white)),
        subtitle: Text(items[i].difficulty.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Text("${items[i].score}", style: const TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }
}