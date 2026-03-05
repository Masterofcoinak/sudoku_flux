import 'package:flutter/material.dart';
import 'sudoku_engine.dart';

class ScoreManager {
  int currentScore = 0;
  int streakLevel = 0; // 0 bis 5
  DateTime? lastCorrectTime;

  void init(Difficulty d) {
    currentScore = {
      Difficulty.easy: 2000,
      Difficulty.medium: 5000,
      Difficulty.hard: 10000,
      Difficulty.expert: 20000,
    }[d]!;
    streakLevel = 0;
    lastCorrectTime = null;
  }

  void handleCorrectMove(Difficulty d, double multiplier) {
    final now = DateTime.now();
    int flowLimit = {
      Difficulty.easy: 5,
      Difficulty.medium: 8,
      Difficulty.hard: 12,
      Difficulty.expert: 15
    }[d]!;

    if (lastCorrectTime != null) {
      if (now.difference(lastCorrectTime!).inSeconds <= flowLimit) {
        if (streakLevel < 5) streakLevel++;
      } else {
        // Stufenweiser Abstieg bei Zeitüberschreitung
        if (streakLevel > 0) streakLevel--;
      }
    } else {
      streakLevel = 1;
    }

    lastCorrectTime = now;

    double base = {
      Difficulty.easy: 50,
      Difficulty.medium: 100,
      Difficulty.hard: 200,
      Difficulty.expert: 400
    }[d]!.toDouble();
    
    // Faktor im Flow (x2 bei Level 5)
    double flowBonus = (streakLevel == 5) ? 2.0 : 1.0;
    currentScore += (base * multiplier * flowBonus).toInt();
  }

  void handleWrongMove(Difficulty d) {
    int penalty = {
      Difficulty.easy: 50,
      Difficulty.medium: 100,
      Difficulty.hard: 200,
      Difficulty.expert: 400
    }[d]!;
    currentScore = (currentScore - penalty).clamp(0, 999999);
    // Fehler bestraft Streak stärker
    streakLevel = (streakLevel - 2).clamp(0, 5);
  }

  void tick() {
    if (currentScore > 0) currentScore -= 1;
  }
}