// lib/sudoku_engine.dart
// Handles: puzzle generation, solving, uniqueness check, difficulty

import 'dart:math';

enum Difficulty { easy, medium, hard, expert }

class SudokuEngine {
  static final Random _rng = Random();

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Returns a puzzle + its solution for the given difficulty.
  static ({List<List<int>> puzzle, List<List<int>> solution}) generate(
      Difficulty difficulty) {
    final solution = _generateSolved();
    final puzzle = _digHoles(solution, difficulty);
    return (puzzle: puzzle, solution: solution);
  }

  /// Returns true if [board] is completely and correctly filled.
  static bool isSolved(List<List<int>> board, List<List<int>> solution) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board[r][c] != solution[r][c]) return false;
      }
    }
    return true;
  }

  /// Returns true if placing [value] at [row],[col] violates no rules.
  static bool isValidPlacement(
      List<List<int>> board, int row, int col, int value) {
    if (value == 0) return true;
    // row
    for (int c = 0; c < 9; c++) {
      if (c != col && board[row][c] == value) return false;
    }
    // col
    for (int r = 0; r < 9; r++) {
      if (r != row && board[r][col] == value) return false;
    }
    // 3x3 box
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (int r = br; r < br + 3; r++) {
      for (int c = bc; c < bc + 3; c++) {
        if ((r != row || c != col) && board[r][c] == value) return false;
      }
    }
    return true;
  }

  // ─── Generation ────────────────────────────────────────────────────────────

  static List<List<int>> _generateSolved() {
    final board = List.generate(9, (_) => List.filled(9, 0));
    _solve(board, countOnly: false);
    return board;
  }

  /// Backtracking solver.
  /// [countOnly] = true → counts solutions up to 2 (uniqueness check).
  static int _solve(List<List<int>> board, {required bool countOnly}) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board[r][c] == 0) {
          final candidates = _shuffled([1, 2, 3, 4, 5, 6, 7, 8, 9]);
          int count = 0;
          for (final n in candidates) {
            if (isValidPlacement(board, r, c, n)) {
              board[r][c] = n;
              count += _solve(board, countOnly: countOnly);
              if (!countOnly) {
                // just fill – return immediately on first solution
                if (count > 0) return count;
              } else {
                if (count >= 2) {
                  board[r][c] = 0;
                  return count;
                }
              }
              board[r][c] = 0;
            }
          }
          return count;
        }
      }
    }
    return 1; // fully filled → one solution found
  }

  static List<int> _shuffled(List<int> list) {
    final copy = List<int>.from(list);
    copy.shuffle(_rng);
    return copy;
  }

  // ─── Hole digging ──────────────────────────────────────────────────────────

  static List<List<int>> _digHoles(
      List<List<int>> solution, Difficulty difficulty) {
    final puzzle =
        List.generate(9, (r) => List<int>.from(solution[r]));

    final target = _targetClues(difficulty);
    int filled = 81;

    // Build a shuffled list of all positions
    final positions = [
      for (int r = 0; r < 9; r++)
        for (int c = 0; c < 9; c++) (r, c)
    ]..shuffle(_rng);

    for (final (r, c) in positions) {
      if (filled <= target) break;
      final backup = puzzle[r][c];
      puzzle[r][c] = 0;

      // Check uniqueness: clone and count solutions
      final clone = List.generate(9, (i) => List<int>.from(puzzle[i]));
      final solutions = _solve(clone, countOnly: true);

      if (solutions != 1) {
        // Removing this cell breaks uniqueness – put it back
        puzzle[r][c] = backup;
      } else {
        filled--;
      }
    }

    return puzzle;
  }

  /// How many clues (given cells) the puzzle should keep.
  static int _targetClues(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return 36 + _rng.nextInt(4); // 36–39
      case Difficulty.medium:
        return 30 + _rng.nextInt(4); // 30–33
      case Difficulty.hard:
        return 25 + _rng.nextInt(3); // 25–27
      case Difficulty.expert:
        return 22 + _rng.nextInt(3); // 22–24
    }
  }
}