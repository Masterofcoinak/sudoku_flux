import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sudoku_state.dart';
import 'game_screen.dart';
import 'sudoku_engine.dart';
import 'highscore_screen.dart';
import 'user_model.dart';
import 'settings_screen.dart';

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

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});
  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SudokuState>();
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
        child: Stack(
          children: [
            // Profilleiste links
            Positioned(
              top: 60,
              left: 16,
              child: _ProfileColumn(
                profiles: state.profiles,
                activeId: state.activeProfileId,
                onSwitch: (id) => state.switchProfile(id),
                onAdd: () => _showAddProfileDialog(context, state),
              ),
            ),
            // Hauptinhalt
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("SUDOKU", style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 8, color: Colors.white)),
                  const Text("FLUX", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, letterSpacing: 12, color: Color(0xFFFF8A00))),
                  const SizedBox(height: 60),
                  _DifficultyRow(label: "EASY", color: Colors.green, difficulty: Difficulty.easy, state: state, onStart: () => _startGame(context, Difficulty.easy), onResume: (s) => _resumeGame(context, s)),
                  _DifficultyRow(label: "MEDIUM", color: Colors.blue, difficulty: Difficulty.medium, state: state, onStart: () => _startGame(context, Difficulty.medium), onResume: (s) => _resumeGame(context, s)),
                  _DifficultyRow(label: "HARD", color: Colors.orange, difficulty: Difficulty.hard, state: state, onStart: () => _startGame(context, Difficulty.hard), onResume: (s) => _resumeGame(context, s)),
                  _DifficultyRow(label: "EXPERT", color: Colors.red, difficulty: Difficulty.expert, state: state, onStart: () => _startGame(context, Difficulty.expert), onResume: (s) => _resumeGame(context, s)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.spa_outlined, color: Colors.tealAccent, size: 18),
                      const SizedBox(width: 8),
                      const Text("Relax", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(width: 8),
                      Switch(value: state.relaxMode, onChanged: (v) => state.setRelaxMode(v), activeColor: Colors.tealAccent),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    IconButton(
                      icon: const Icon(Icons.leaderboard, color: Colors.white54, size: 28),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HighscoreScreen())),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white54, size: 28),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startGame(BuildContext context, Difficulty diff) {
    context.read<SudokuState>().newGame(diff);
    Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(initialDifficulty: diff)));
  }

  void _resumeGame(BuildContext context, SavedGame saved) {
    context.read<SudokuState>().resumeGame(saved);
    final diff = Difficulty.values.firstWhere((d) => d.name == saved.difficultyName);
    Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(initialDifficulty: diff, resumedElapsed: Duration(seconds: saved.elapsedSeconds))));
  }

  void _showAddProfileDialog(BuildContext context, SudokuState state) {
    showDialog(context: context, builder: (_) => _ProfileDialog(
      onSave: (initials, color) {
        final id = DateTime.now().millisecondsSinceEpoch.toString();
        state.addProfile(UserProfile(id: id, initials: initials, color: color));
      },
    ));
  }
}

class _ProfileColumn extends StatelessWidget {
  final List<UserProfile> profiles;
  final String activeId;
  final void Function(String) onSwitch;
  final VoidCallback onAdd;
  const _ProfileColumn({required this.profiles, required this.activeId, required this.onSwitch, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ...profiles.map((p) {
          final isActive = p.id == activeId;
          final size = isActive ? 60.0 : 42.0;
          return GestureDetector(
            onTap: () => onSwitch(p.id),
            onDoubleTap: () => _showProfileDetail(context, p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: size, height: size,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: p.color,
                shape: BoxShape.circle,
                border: isActive ? Border.all(color: Colors.white, width: 2) : null,
                boxShadow: isActive ? [BoxShadow(color: p.color.withValues(alpha: 0.5), blurRadius: 12)] : [],
              ),
              alignment: Alignment.center,
              child: Text(p.initials, style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: isActive ? 18 : 13,
              )),
            ),
          );
        }),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.add, color: Colors.white38, size: 20),
          ),
        ),
      ],
    );
  }

  void _showProfileDetail(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => _ProfileDetailSheet(profile: profile),
    );
  }
}

class _ProfileDetailSheet extends StatelessWidget {
  final UserProfile profile;
  const _ProfileDetailSheet({required this.profile});

  static const _accent = Color(0xFFFF8A00);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SudokuState>();
    final isActive = state.activeProfileId == profile.id;
    final scores = state.highscores.where((e) => e.userName == profile.initials).toList();
    final best = scores.isEmpty ? 0 : scores.map((e) => e.score).reduce((a, b) => a > b ? a : b);
    final avg = scores.isEmpty ? 0 : (scores.map((e) => e.score).reduce((a, b) => a + b) / scores.length).round();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: profile.color, radius: 28,
                child: Text(profile.initials, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(profile.initials, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  if (isActive) const Text("Aktives Profil", style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                ]),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white54),
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(context: context, builder: (_) => _ProfileDialog(
                    existing: profile,
                    onSave: (initials, color) => state.updateActiveProfile(initials: initials, color: color),
                  ));
                },
              ),
              if (state.profiles.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () { state.deleteProfile(profile.id); Navigator.pop(context); },
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatBox(label: "Spiele", value: "${scores.length}"),
              _StatBox(label: "Bester", value: "$best"),
              _StatBox(label: "Schnitt", value: "$avg"),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          const Align(alignment: Alignment.centerLeft,
            child: Text("Einstellungen", style: TextStyle(color: Colors.white54, fontSize: 12))),
          const SizedBox(height: 8),
          _SettingToggle(label: "Quick Modus", icon: Icons.bolt,
            value: profile.quickMode,
            onChanged: (v) => state.setProfileSetting(profile.id, quickMode: v)),
          _SettingToggle(label: "Auswahl", icon: Icons.select_all,
            value: profile.highlightSelect,
            onChanged: (v) => state.setProfileSetting(profile.id, highlightSelect: v)),
          _SettingToggle(label: "Numbers", icon: Icons.grid_on,
            value: profile.highlightNumbers,
            onChanged: (v) => state.setProfileSetting(profile.id, highlightNumbers: v)),
          _SettingToggle(label: "Lines", icon: Icons.format_line_spacing,
            value: profile.highlightLines,
            onChanged: (v) => state.setProfileSetting(profile.id, highlightLines: v)),
          _SettingToggle(label: "Errors", icon: Icons.remove_red_eye,
            value: profile.showErrors,
            onChanged: (v) => state.setProfileSetting(profile.id, showErrors: v)),
          _SettingToggle(label: "Relax Modus", icon: Icons.spa_outlined,
            value: profile.relaxMode,
            onChanged: (v) => state.setProfileSetting(profile.id, relaxMode: v)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  const _StatBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
    ]);
  }
}

class _SettingToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final void Function(bool) onChanged;
  const _SettingToggle({required this.label, required this.icon, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: value ? const Color(0xFFFF8A00) : Colors.white38, size: 16),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: TextStyle(color: value ? Colors.white : Colors.white54, fontSize: 14))),
      Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFFFF8A00)),
    ]);
  }
}

class _ProfileDialog extends StatefulWidget {
  final void Function(String initials, Color color) onSave;
  final UserProfile? existing;
  const _ProfileDialog({required this.onSave, this.existing});
  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  late final _controller = TextEditingController(text: widget.existing?.initials ?? '');
  late Color _selectedColor = widget.existing?.color ?? Colors.blue;

  static const _colors = [
    Colors.orange, Colors.blue, Colors.green, Colors.red,
    Colors.purple, Colors.teal, Colors.pink, Colors.amber,
    Colors.cyan, Colors.lime, Colors.indigo, Colors.deepOrange,
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(widget.existing == null ? "Profil erstellen" : "Profil bearbeiten", style: const TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            maxLength: 2,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: "Kürzel (2 Buchstaben)",
              hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
              counterText: "",
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF8A00))),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _colors.map((c) => GestureDetector(
              onTap: () => setState(() => _selectedColor = c),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: _selectedColor == c ? Border.all(color: Colors.white, width: 2) : null,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Abbrechen", style: TextStyle(color: Colors.white38))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A00), foregroundColor: Colors.black),
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              widget.onSave(_controller.text.trim().toUpperCase(), _selectedColor);
              Navigator.pop(context);
            }
          },
          child: const Text("Speichern"),
        ),
      ],
    );
  }
}

class _DifficultyRow extends StatelessWidget {
  final String label;
  final Color color;
  final Difficulty difficulty;
  final SudokuState state;
  final VoidCallback onStart;
  final void Function(SavedGame) onResume;

  const _DifficultyRow({required this.label, required this.color, required this.difficulty, required this.state, required this.onStart, required this.onResume});

  @override
  Widget build(BuildContext context) {
    final saved = state.getSavedGame(difficulty);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(children: [
        SizedBox(
          width: 200, height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              side: BorderSide(color: color.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            onPressed: onStart,
            child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ),
        ),
        if (saved != null) ...[
          const SizedBox(height: 2),
          SizedBox(
            width: 200,
            child: Row(children: [
              if (saved.relaxMode) ...[
                const Icon(Icons.spa_outlined, color: Colors.tealAccent, size: 11),
                const SizedBox(width: 4),
              ],
              Text(_fmtDateTime(saved.savedAt), style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 13)),
              const Spacer(),
              GestureDetector(
                onTap: () => onResume(saved),
                child: Icon(Icons.play_circle_fill, color: color, size: 26),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  String _fmtDateTime(DateTime dt) {
    return "${dt.day.toString().padLeft(2,'0')}.${dt.month.toString().padLeft(2,'0')}. ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
  }
}