import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sudoku_state.dart';
import 'game_screen.dart';
import 'sudoku_engine.dart';
import 'highscore_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => SudokuState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku Flux',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const MainMenu(),
    );
  }
}

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "SUDOKU",
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: Colors.white,
              ),
            ),
            const Text(
              "FLUX",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                letterSpacing: 12,
                color: Color(0xFFFF8A00),
              ),
            ),
            const SizedBox(height: 60),
            _MenuButton(
              label: "EASY",
              color: Colors.green,
              onTap: () => _startGame(context, Difficulty.easy),
            ),
            _MenuButton(
              label: "MEDIUM",
              color: Colors.blue,
              onTap: () => _startGame(context, Difficulty.medium),
            ),
            _MenuButton(
              label: "HARD",
              color: Colors.orange,
              onTap: () => _startGame(context, Difficulty.hard),
            ),
            _MenuButton(
              label: "EXPERT",
              color: Colors.red,
              onTap: () => _startGame(context, Difficulty.expert),
            ),
            const SizedBox(height: 40),
            IconButton(
              icon: const Icon(Icons.leaderboard, color: Colors.white54, size: 30),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HighscoreScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startGame(BuildContext context, Difficulty diff) {
    context.read<SudokuState>().newGame(diff);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(initialDifficulty: diff)),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: 200,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            side: BorderSide(color: color.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
          onPressed: onTap,
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
        ),
      ),
    );
  }
}