import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sudoku_state.dart';

const _accent = Color(0xFFFF8A00);
const _bg = Color(0xFF1E1E1E);
const _card = Color(0xFF252525);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SudokuState>();
    final profile = state.activeProfile;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Einstellungen", style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: profile.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: profile.color.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              CircleAvatar(backgroundColor: profile.color, radius: 20,
                child: Text(profile.initials, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13))),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Einstellungen für: ${profile.initials}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const Text("Alle Änderungen gelten nur für dieses Profil",
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
              ]),
            ]),
          ),

          _Section(title: "SPIEL", children: [
            _Toggle(icon: Icons.bolt, label: "Quick-Modus",
              description: "Zahl wählen, Feld tippen, automatisch platziert",
              value: state.quickMode, onChanged: (_) => state.toggleQuickMode()),
            _Toggle(icon: Icons.spa_outlined, label: "Relax-Modus",
              description: "Kein Timer, kein Streak, einfach entspannt spielen",
              value: state.relaxMode, onChanged: (v) => state.setRelaxMode(v)),
            _Toggle(icon: Icons.timer_outlined, label: "Timer anzeigen",
              description: "Zeigt die Spielzeit an",
              value: false, onChanged: null, comingSoon: true),
            _Toggle(icon: Icons.error_outline, label: "Fehlerlimit",
              description: "Spiel endet nach 3 Fehlern",
              value: false, onChanged: null, comingSoon: true),
            _Toggle(icon: Icons.check_circle_outline, label: "Benutzte Zahlen ausblenden",
              description: "Zahlen die 9x platziert wurden ausblenden",
              value: false, onChanged: null, comingSoon: true),
          ]),

          _Section(title: "HILFEN", children: [
            _Toggle(icon: Icons.select_all, label: "Auswahl markieren",
              description: "Zeile, Spalte und Block des gewählten Felds hervorheben",
              value: state.highlightSelect, onChanged: (_) => state.toggleHighlightSelect()),
            _Toggle(icon: Icons.grid_on, label: "Gleiche Zahlen markieren",
              description: "Alle identischen Zahlen im Spielfeld hervorheben",
              value: state.highlightNumbers, onChanged: (_) => state.toggleHighlightNumbers()),
            _Toggle(icon: Icons.format_line_spacing, label: "Linien hervorheben",
              description: "Gesperrte Zeilen und Spalten anzeigen",
              value: state.highlightLines, onChanged: (_) => state.toggleHighlightLines()),
            _Toggle(icon: Icons.remove_red_eye_outlined, label: "Fehler anzeigen",
              description: "Falsch platzierte Zahlen rot markieren",
              value: state.showErrors, onChanged: (_) => state.toggleErrors()),
            _Toggle(icon: Icons.auto_fix_high, label: "Notizen automatisch entfernen",
              description: "Entfernt Notizen wenn eine Zahl platziert wird",
              value: false, onChanged: null, comingSoon: true),
          ]),

          _Section(title: "DARSTELLUNG", children: [
            _Arrow(icon: Icons.palette_outlined, label: "Theme",
              description: "Spielfeld-Design auswählen", comingSoon: true),
            _Arrow(icon: Icons.format_size, label: "Schriftgröße",
              description: "Größe der Zahlen anpassen", comingSoon: true),
            _Arrow(icon: Icons.dialpad, label: "Tastatur-Layout",
              description: "1-9 in einer Reihe oder 2 Reihen", comingSoon: true),
          ]),

          _Section(title: "AUDIO & FEEDBACK", children: [
            _Toggle(icon: Icons.volume_up_outlined, label: "Sound-Effekte",
              description: "Töne beim Platzieren von Zahlen",
              value: false, onChanged: null, comingSoon: true),
            _Toggle(icon: Icons.vibration, label: "Vibration",
              description: "Haptisches Feedback",
              value: false, onChanged: null, comingSoon: true),
          ]),

          _Section(title: "PUNKTE-SYSTEM", children: [
            _Info(icon: Icons.stars, label: "Startpunkte", description: "Easy: 2.000 · Medium: 5.000 · Hard: 10.000 · Expert: 20.000"),
            _Info(icon: Icons.add_circle_outline, label: "Richtige Zahl", description: "Easy +50 · Medium +100 · Hard +200 · Expert +400\nMultipliziert mit Streak-Bonus (bis ×2.0)"),
            _Info(icon: Icons.local_fire_department_outlined, label: "Streak-Leiste", description: "Füllt sich bei richtigen Zügen. Volle Leiste = doppelte Punkte.\nFällt langsam ab, schnell bei Fehlern"),
            _Info(icon: Icons.timer_outlined, label: "Zeit-Abzug", description: "Alle 2 Sekunden −1 Punkt (nicht im Relax-Modus)"),
            _Info(icon: Icons.warning_amber_rounded, label: "Fehler-System", description: "1–2 Fehler: keine Strafe, kein Streak-Verlust\nAb 3. Fehler: Streak auf 0, Punkteabzug (Easy −300 bis Expert −2400)\nFehler-Knopf: zeigt Fehler 3 Sek an, löscht sie dann"),
            _Info(icon: Icons.lightbulb_outline, label: "Hint", description: "Legt eine richtige Zahl frei\nKosten: Easy −200 · Medium −400 · Hard −800 · Expert −1600"),
            _Info(icon: Icons.remove_red_eye_outlined, label: "Hilfen-Abzüge", description: "Fehler anzeigen: ×0.10 · Linien: ×0.25\nZahlen: ×0.50 · Auswahl: ×0.75"),
          ]),

          _Section(title: "ÜBER", children: [
            _Arrow(icon: Icons.info_outline, label: "Version", description: "Sudoku Flux v1.0"),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
        child: Text(title, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ),
      Container(
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)),
        child: Column(children: List.generate(children.length, (i) => Column(children: [
          children[i],
          if (i < children.length - 1) const Divider(height: 1, color: Colors.white10, indent: 16),
        ]))),
      ),
    ]);
  }
}

class _Toggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final void Function(bool)? onChanged;
  final bool comingSoon;

  const _Toggle({
    required this.icon, required this.label, required this.description,
    required this.value, required this.onChanged, this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = comingSoon || onChanged == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, color: disabled ? Colors.white24 : (value ? _accent : Colors.white54), size: 20),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(label, style: TextStyle(color: disabled ? Colors.white24 : Colors.white, fontSize: 14)),
            if (comingSoon) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                child: const Text("bald", style: TextStyle(color: Colors.white38, fontSize: 9)),
              ),
            ],
          ]),
          const SizedBox(height: 2),
          Text(description, style: TextStyle(color: disabled ? Colors.white12 : Colors.white38, fontSize: 11)),
        ])),
        Switch(
          value: disabled ? false : value,
          onChanged: disabled ? null : onChanged,
          activeColor: _accent,
        ),
      ]),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  const _Info({required this.icon, required this.label, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: _accent, size: 18),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(description, style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.5)),
        ])),
      ]),
    );
  }
}

class _Arrow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool comingSoon;
  const _Arrow({required this.icon, required this.label, required this.description, this.comingSoon = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, color: comingSoon ? Colors.white24 : Colors.white54, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(label, style: TextStyle(color: comingSoon ? Colors.white24 : Colors.white, fontSize: 14)),
            if (comingSoon) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                child: const Text("bald", style: TextStyle(color: Colors.white38, fontSize: 9)),
              ),
            ],
          ]),
          const SizedBox(height: 2),
          Text(description, style: TextStyle(color: comingSoon ? Colors.white12 : Colors.white38, fontSize: 11)),
        ])),
        Icon(Icons.chevron_right, color: comingSoon ? Colors.white12 : Colors.white38, size: 20),
      ]),
    );
  }
}
