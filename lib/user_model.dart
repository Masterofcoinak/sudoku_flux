import 'package:flutter/material.dart';

class UserProfile {
  final String id;
  String initials;
  Color color;

  bool quickMode;
  bool relaxMode;
  bool highlightSelect;
  bool highlightNumbers;
  bool highlightLines;
  bool showErrors;

  UserProfile({
    required this.id,
    required this.initials,
    required this.color,
    this.quickMode = false,
    this.relaxMode = false,
    this.highlightSelect = false,
    this.highlightNumbers = false,
    this.highlightLines = false,
    this.showErrors = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'initials': initials,
    'color': color.toARGB32(),
    'quickMode': quickMode,
    'relaxMode': relaxMode,
    'highlightSelect': highlightSelect,
    'highlightNumbers': highlightNumbers,
    'highlightLines': highlightLines,
    'showErrors': showErrors,
  };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    id: j['id'],
    initials: j['initials'],
    color: Color(j['color']),
    quickMode: j['quickMode'] ?? false,
    relaxMode: j['relaxMode'] ?? false,
    highlightSelect: j['highlightSelect'] ?? false,
    highlightNumbers: j['highlightNumbers'] ?? false,
    highlightLines: j['highlightLines'] ?? false,
    showErrors: j['showErrors'] ?? false,
  );
}

class SavedGame {
  final String profileId;
  final String difficultyName;
  final List<List<int>> given;
  final List<List<int>> current;
  final List<List<List<int>>> notes;
  final List<List<int>> solution;
  final int elapsedSeconds;
  final int score;
  final double streakValue;
  final bool relaxMode;
  final bool quickMode;
  final bool showErrors;
  final bool highlightSelect;
  final bool highlightNumbers;
  final bool highlightLines;
  final DateTime savedAt;

  SavedGame({
    required this.profileId,
    required this.difficultyName,
    required this.given,
    required this.current,
    required this.notes,
    required this.solution,
    required this.elapsedSeconds,
    required this.score,
    required this.streakValue,
    required this.relaxMode,
    required this.quickMode,
    required this.showErrors,
    required this.highlightSelect,
    required this.highlightNumbers,
    required this.highlightLines,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'difficultyName': difficultyName,
    'given': given,
    'current': current,
    'notes': notes,
    'solution': solution,
    'elapsedSeconds': elapsedSeconds,
    'score': score,
    'streakValue': streakValue,
    'relaxMode': relaxMode,
    'quickMode': quickMode,
    'showErrors': showErrors,
    'highlightSelect': highlightSelect,
    'highlightNumbers': highlightNumbers,
    'highlightLines': highlightLines,
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedGame.fromJson(Map<String, dynamic> j) => SavedGame(
    profileId: j['profileId'],
    difficultyName: j['difficultyName'],
    given: (j['given'] as List).map((r) => (r as List).map((v) => v as int).toList()).toList(),
    current: (j['current'] as List).map((r) => (r as List).map((v) => v as int).toList()).toList(),
    notes: (j['notes'] as List).map((r) => (r as List).map((c) => (c as List).map((v) => v as int).toList()).toList()).toList(),
    solution: (j['solution'] as List).map((r) => (r as List).map((v) => v as int).toList()).toList(),
    elapsedSeconds: j['elapsedSeconds'],
    score: j['score'],
    streakValue: (j['streakValue'] as num).toDouble(),
    relaxMode: j['relaxMode'] ?? false,
    quickMode: j['quickMode'] ?? false,
    showErrors: j['showErrors'] ?? false,
    highlightSelect: j['highlightSelect'] ?? false,
    highlightNumbers: j['highlightNumbers'] ?? false,
    highlightLines: j['highlightLines'] ?? false,
    savedAt: DateTime.parse(j['savedAt']),
  );
}

class HighscoreEntry {
  final String userName;
  final Color profileColor;
  final int score;
  final String difficulty;
  final DateTime date;

  HighscoreEntry({
    required this.userName,
    required this.profileColor,
    required this.score,
    required this.difficulty,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'userName': userName,
    'profileColor': profileColor.toARGB32(),
    'score': score,
    'difficulty': difficulty,
    'date': date.toIso8601String(),
  };

  factory HighscoreEntry.fromJson(Map<String, dynamic> j) => HighscoreEntry(
    userName: j['userName'],
    profileColor: Color(j['profileColor']),
    score: j['score'],
    difficulty: j['difficulty'],
    date: DateTime.parse(j['date']),
  );
}