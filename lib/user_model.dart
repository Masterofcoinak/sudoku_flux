import 'package:flutter/material.dart';

class UserProfile {
  final String id;
  String initials;
  Color color;

  // Profil-eigene Einstellungen
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
}