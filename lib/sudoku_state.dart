import 'package:flutter/material.dart';
import 'sudoku_engine.dart';
import 'score_manager.dart';
import 'user_model.dart';
import 'dart:async';

class SudokuCell {
  final bool given;
  int value;
  Set<int> notes;
  SudokuCell({required this.given, required this.value, Set<int>? notes}) : notes = notes ?? <int>{};
  SudokuCell copy() => SudokuCell(given: given, value: value, notes: {...notes});
}

class SudokuState extends ChangeNotifier {
  late List<List<SudokuCell>> grid;
  late List<List<int>> _solution;
  final ScoreManager scoreManager = ScoreManager();

  int? selectedRow, selectedCol;
  int? lastPlacedRow, lastPlacedCol;
  int? previousPlacedRow, previousPlacedCol;
  int? activeNumber;

  bool pencilMode = false;
  bool showErrors = false;
  bool highlightSelect = false;
  bool highlightNumbers = false;
  bool highlightLines = false;
  bool scanSudoku = false;

  Difficulty difficulty = Difficulty.easy;
  bool isComplete = false;
  Timer? _tickTimer;

  // Diese Liste fehlte laut Fehlermeldung
  List<HighscoreEntry> highscores = [];
  
  // Standard-Nutzer für die Zuordnung
  UserProfile currentUser = UserProfile(id: '1', name: 'Spieler 1', color: Colors.orange, initial: 'S');

  final List<List<List<SudokuCell>>> _undoHistory = [];

  SudokuState() {
    newGame(Difficulty.easy);
    _tickTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!isComplete) {
        scoreManager.tick();
        notifyListeners();
      }
    });
  }

  void newGame(Difficulty d) {
    difficulty = d;
    isComplete = false;
    final result = SudokuEngine.generate(d);
    _solution = result.solution;
    grid = List.generate(9, (r) => List.generate(9, (c) => 
      SudokuCell(given: result.puzzle[r][c] != 0, value: result.puzzle[r][c])));

    scoreManager.init(d);
    _undoHistory.clear();
    selectedRow = null; selectedCol = null;
    lastPlacedRow = null; lastPlacedCol = null;
    previousPlacedRow = null; previousPlacedCol = null;
    activeNumber = null;
    notifyListeners();
  }

  void selectCell(int r, int c) {
    selectedRow = r; selectedCol = c;
    if (activeNumber != null) {
      if (lastPlacedRow != null && (lastPlacedRow != r || lastPlacedCol != c)) {
        previousPlacedRow = lastPlacedRow;
        previousPlacedCol = lastPlacedCol;
      }
      applyNumber(activeNumber!);
      lastPlacedRow = r; lastPlacedCol = c;
    }
    notifyListeners();
  }

  void setActiveNumber(int? n) {
    if (activeNumber == n) { 
      activeNumber = null; 
    } else {
      activeNumber = n;
      previousPlacedRow = null; previousPlacedCol = null;
      selectedRow = null; selectedCol = null;
      lastPlacedRow = null; lastPlacedCol = null;
    }
    notifyListeners();
  }

  void applyNumber(int n) {
    if (selectedRow == null || selectedCol == null) return;
    final cell = grid[selectedRow!][selectedCol!];
    if (cell.given) return;

    _saveUndo();

    if (pencilMode) {
      if (cell.notes.contains(n)) {
        cell.notes.remove(n);
      } else {
        cell.notes.add(n);
      }
      if (cell.notes.isNotEmpty) cell.value = 0;
    } else {
      bool isCorrect = n == _solution[selectedRow!][selectedCol!];
      if (isCorrect && cell.value != n) {
        double mult = 1.0;
        if (scanSudoku) mult *= 0.0;
        if (showErrors) mult *= 0.10;
        if (highlightLines) mult *= 0.25;
        if (highlightNumbers) mult *= 0.50;
        if (highlightSelect) mult *= 0.75;
        scoreManager.handleCorrectMove(difficulty, mult);
      } else if (!isCorrect && n != 0) {
        scoreManager.handleWrongMove(difficulty);
      }
      cell.value = (cell.value == n) ? 0 : n;
      cell.notes.clear();
    }
    _checkCompletion();
    notifyListeners();
  }

  void _saveUndo() {
    _undoHistory.add(grid.map((r) => r.map((c) => c.copy()).toList()).toList());
    if (_undoHistory.length > 50) _undoHistory.removeAt(0);
  }

  void undo() {
    if (_undoHistory.isEmpty) return;
    grid = _undoHistory.removeLast();
    lastPlacedRow = null; lastPlacedCol = null;
    notifyListeners();
  }

  void togglePencil() { pencilMode = !pencilMode; notifyListeners(); }
  void toggleErrors() { showErrors = !showErrors; notifyListeners(); }
  void toggleHighlightSelect() { highlightSelect = !highlightSelect; notifyListeners(); }
  void toggleHighlightNumbers() { highlightNumbers = !highlightNumbers; notifyListeners(); }
  void toggleHighlightLines() { highlightLines = !highlightLines; notifyListeners(); }
  void toggleScan() { 
    scanSudoku = !scanSudoku; 
    if(scanSudoku) scoreManager.currentScore -= 500; 
    notifyListeners(); 
  }

  void _checkCompletion() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c].value != _solution[r][c]) return;
      }
    }
    isComplete = true;
    
    // Highscore speichern
    highscores.add(HighscoreEntry(
      userName: currentUser.name,
      score: scoreManager.currentScore,
      difficulty: difficulty.name,
      date: DateTime.now(),
    ));
    
    notifyListeners();
  }

  bool isCellInSelectionArea(int r, int c) => highlightSelect && selectedRow != null && (r == selectedRow || c == selectedCol || (r ~/ 3 == selectedRow! ~/ 3 && c ~/ 3 == selectedCol! ~/ 3));
  bool isCellSameNumber(int r, int c) => highlightNumbers && activeNumber != null && (grid[r][c].value == activeNumber || grid[r][c].notes.contains(activeNumber));
  
  bool isCellLineBlockedByActiveNumber(int r, int c) {
    if (!highlightLines || activeNumber == null) return false;
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col].value == activeNumber) {
          if (r == row || c == col || (r ~/ 3 == row ~/ 3 && c ~/ 3 == col ~/ 3)) return true;
        }
      }
    }
    return false;
  }

  bool isCellError(int r, int c) {
    if (scanSudoku) return grid[r][c].value != 0 && grid[r][c].value != _solution[r][c];
    if (!showErrors) return false;
    int val = grid[r][c].value;
    if (val == 0) return false;
    for (int i = 0; i < 9; i++) {
      if (i != c && grid[r][i].value == val) return true;
      if (i != r && grid[i][c].value == val) return true;
    }
    return false;
  }

  int remainingCount(int n) {
    int count = 0;
    for (var r in grid) { for (var cell in r) { if (cell.value == n) count++; } }
    return 9 - count;
  }

  @override
  void dispose() { _tickTimer?.cancel(); super.dispose(); }
}