import 'package:flutter/material.dart';
import 'sudoku_engine.dart';

class ScoreManager {
  int currentScore = 0;
  double streakValue = 0.0;
  DateTime? lastCorrectTime;
  Difficulty _difficulty = Difficulty.easy;
  set difficulty(Difficulty d) => _difficulty = d;

  // Score-Tracking für Aufschlüsselung
  int startingScore = 0;
  int earnedFromMoves = 0;
  int lostFromTime = 0;
  int lostFromHints = 0;
  int lostFromErrors = 0;

  int get streakLevel => streakValue.floor().clamp(0, 5);
  double get scoreMultiplier => 1.0 + (streakValue / 5.0);

  void init(Difficulty d) {
    currentScore = {
      Difficulty.easy: 2000,
      Difficulty.medium: 5000,
      Difficulty.hard: 10000,
      Difficulty.expert: 20000,
    }[d]!;
    startingScore = currentScore;
    earnedFromMoves = 0;
    lostFromTime = 0;
    lostFromHints = 0;
    lostFromErrors = 0;
    streakValue = 0.0;
    lastCorrectTime = null;
    _difficulty = d;
  }

  void handleCorrectMove(Difficulty d, double multiplier) {
    lastCorrectTime = DateTime.now();
    final fillAmount = {
      Difficulty.easy: 1.2,
      Difficulty.medium: 0.9,
      Difficulty.hard: 0.65,
      Difficulty.expert: 0.5,
    }[d]!;
    streakValue = (streakValue + fillAmount).clamp(0.0, 5.0);

    double base = {
      Difficulty.easy: 50,
      Difficulty.medium: 100,
      Difficulty.hard: 200,
      Difficulty.expert: 400
    }[d]!.toDouble();

    final gained = (base * multiplier * scoreMultiplier).toInt();
    currentScore += gained;
    earnedFromMoves += gained;
  }

  void handleErrorThreshold(Difficulty d) {
    streakValue = 0.0;
    int penalty = {
      Difficulty.easy: 300,
      Difficulty.medium: 600,
      Difficulty.hard: 1200,
      Difficulty.expert: 2400,
    }[d]!;
    final actual = penalty.clamp(0, currentScore);
    currentScore = (currentScore - penalty).clamp(0, 999999);
    lostFromErrors += actual;
  }

  void handleWrongMove(Difficulty d) {
    int penalty = {
      Difficulty.easy: 50,
      Difficulty.medium: 100,
      Difficulty.hard: 200,
      Difficulty.expert: 400
    }[d]!;
    currentScore = (currentScore - penalty).clamp(0, 999999);
    streakValue = (streakValue - 1.5).clamp(0.0, 5.0);
  }

  void deductHint(int amount) {
    final actual = amount.clamp(0, currentScore);
    currentScore = (currentScore - amount).clamp(0, 999999);
    lostFromHints += actual;
  }

  void tick() {
    if (currentScore > 0) {
      currentScore -= 1;
      lostFromTime += 1;
    }
    if (streakValue > 0) {
      final decay = {
        Difficulty.easy: 0.20,
        Difficulty.medium: 0.12,
        Difficulty.hard: 0.08,
        Difficulty.expert: 0.05,
      }[_difficulty]!;
      streakValue = (streakValue - decay).clamp(0.0, 5.0);
    }
  }
}