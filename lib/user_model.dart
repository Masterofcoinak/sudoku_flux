import 'package:flutter/material.dart';

class UserProfile {
  final String id;
  final String name;
  final Color color;
  final String initial;

  UserProfile({
    required this.id, 
    required this.name, 
    required this.color, 
    required this.initial
  });
}

class HighscoreEntry {
  final String userName;
  final int score;
  final String difficulty;
  final DateTime date;

  HighscoreEntry({
    required this.userName, 
    required this.score, 
    required this.difficulty, 
    required this.date
  });
}