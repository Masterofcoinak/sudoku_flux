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
  int recentPoints = 0;
  Timer? _recentPointsTimer;

  int errorCount = 0;
  bool _showErrorsTemporarily = false;
  bool get showErrorsTemporarily => _showErrorsTemporarily;
  Timer? _errorRevealTimer;

  bool get hasUserProgress {
    for (var r in grid) {
      for (var cell in r) {
        if (!cell.given && cell.value != 0) return true;
      }
    }
    return false;
  }

  int get hintCost => {
    Difficulty.easy: 200,
    Difficulty.medium: 400,
    Difficulty.hard: 800,
    Difficulty.expert: 1600,
  }[difficulty]!;

  bool pencilMode = false;
  bool showErrors = false;
  bool highlightSelect = false;
  bool highlightNumbers = false;
  bool highlightLines = false;
  bool quickMode = false;
  bool relaxMode = false;

  Difficulty difficulty = Difficulty.easy;
  bool isComplete = false;
  Timer? _tickTimer;

  List<HighscoreEntry> highscores = [];

  // profileId -> difficultyName -> SavedGame
  final Map<String, Map<String, SavedGame>> _savedGames = {};

  SavedGame? getSavedGame(Difficulty d) {
    return _savedGames[activeProfileId]?[d.name];
  }

  List<SavedGame> get activeSavedGames {
    return (_savedGames[activeProfileId]?.values.toList()) ?? [];
  }

  void saveCurrentGame(Duration elapsed) {
    final profileGames = _savedGames.putIfAbsent(activeProfileId, () => {});
    profileGames[difficulty.name] = SavedGame(
      profileId: activeProfileId,
      difficultyName: difficulty.name,
      given: List.generate(9, (r) => List.generate(9, (c) => grid[r][c].given ? grid[r][c].value : 0)),
      current: List.generate(9, (r) => List.generate(9, (c) => grid[r][c].value)),
      notes: List.generate(9, (r) => List.generate(9, (c) => grid[r][c].notes.toList())),
      solution: _solution,
      elapsedSeconds: elapsed.inSeconds,
      score: scoreManager.currentScore,
      streakValue: scoreManager.streakValue,
      relaxMode: relaxMode,
      quickMode: quickMode,
      showErrors: showErrors,
      highlightSelect: highlightSelect,
      highlightNumbers: highlightNumbers,
      highlightLines: highlightLines,
      savedAt: DateTime.now(),
    );
  }

  void resumeGame(SavedGame saved) {
    difficulty = Difficulty.values.firstWhere((d) => d.name == saved.difficultyName);
    isComplete = false;
    _solution = saved.solution;
    grid = List.generate(9, (r) => List.generate(9, (c) => SudokuCell(
      given: saved.given[r][c] != 0,
      value: saved.current[r][c],
      notes: saved.notes[r][c].toSet(),
    )));
    errorCount = 0;
    _errorRevealTimer?.cancel();
    _showErrorsTemporarily = false;
    scoreManager.currentScore = saved.score;
    scoreManager.streakValue = saved.streakValue;
    scoreManager.difficulty = difficulty;
    relaxMode = saved.relaxMode;
    quickMode = saved.quickMode;
    showErrors = saved.showErrors;
    highlightSelect = saved.highlightSelect;
    highlightNumbers = saved.highlightNumbers;
    highlightLines = saved.highlightLines;
    _undoHistory.clear();
    selectedRow = null; selectedCol = null;
    activeNumber = null;
    recentPoints = 0;
    notifyListeners();
  }

  void deleteSavedGame(Difficulty d) {
    _savedGames[activeProfileId]?.remove(d.name);
  }

  List<UserProfile> profiles = [
    UserProfile(id: '1', initials: 'P1', color: Colors.orange),
  ];
  String activeProfileId = '1';

  UserProfile get activeProfile => profiles.firstWhere((p) => p.id == activeProfileId);

  void switchProfile(String id) {
    _saveSettingsToProfile();
    activeProfileId = id;
    _loadSettingsFromProfile();
    notifyListeners();
  }

  void addProfile(UserProfile p) {
    profiles.add(p);
    notifyListeners();
  }

  void updateActiveProfile({required String initials, required Color color}) {
    activeProfile.initials = initials;
    activeProfile.color = color;
    notifyListeners();
  }

  void _saveSettingsToProfile() {
    final p = activeProfile;
    p.quickMode = quickMode;
    p.relaxMode = relaxMode;
    p.highlightSelect = highlightSelect;
    p.highlightNumbers = highlightNumbers;
    p.highlightLines = highlightLines;
    p.showErrors = showErrors;
  }

  void _loadSettingsFromProfile() {
    final p = activeProfile;
    quickMode = p.quickMode;
    relaxMode = p.relaxMode;
    highlightSelect = p.highlightSelect;
    highlightNumbers = p.highlightNumbers;
    highlightLines = p.highlightLines;
    showErrors = p.showErrors;
  }

  void setProfileSetting(String profileId, {
    bool? quickMode, bool? relaxMode,
    bool? highlightSelect, bool? highlightNumbers,
    bool? highlightLines, bool? showErrors,
  }) {
    final p = profiles.firstWhere((x) => x.id == profileId);
    if (quickMode != null) p.quickMode = quickMode;
    if (relaxMode != null) p.relaxMode = relaxMode;
    if (highlightSelect != null) p.highlightSelect = highlightSelect;
    if (highlightNumbers != null) p.highlightNumbers = highlightNumbers;
    if (highlightLines != null) p.highlightLines = highlightLines;
    if (showErrors != null) p.showErrors = showErrors;
    if (profileId == activeProfileId) _loadSettingsFromProfile();
    notifyListeners();
  }

  void deleteProfile(String id) {
    if (profiles.length <= 1) return;
    profiles.removeWhere((p) => p.id == id);
    if (activeProfileId == id) {
      activeProfileId = profiles.first.id;
      _loadSettingsFromProfile();
    }
    notifyListeners();
  }

  final List<List<List<SudokuCell>>> _undoHistory = [];

  SudokuState() {
    newGame(Difficulty.easy);
    _tickTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!isComplete) {
        if (!relaxMode) scoreManager.tick();
        notifyListeners();
      }
    });
  }

  void revealAndClearErrors() {
    _errorRevealTimer?.cancel();
    _showErrorsTemporarily = true;
    notifyListeners();
    _errorRevealTimer = Timer(const Duration(seconds: 3), () {
      _saveUndo();
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (!grid[r][c].given && grid[r][c].value != 0 && grid[r][c].value != _solution[r][c]) {
            grid[r][c].value = 0;
            grid[r][c].notes.clear();
          }
        }
      }
      errorCount = 0;
      _showErrorsTemporarily = false;
      notifyListeners();
    });
  }

  void useHint() {
    final candidates = <List<int>>[];
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (!grid[r][c].given && grid[r][c].value != _solution[r][c]) {
          candidates.add([r, c]);
        }
      }
    }
    if (candidates.isEmpty) return;
    candidates.shuffle();
    final pos = candidates.first;
    _saveUndo();
    grid[pos[0]][pos[1]].value = _solution[pos[0]][pos[1]];
    grid[pos[0]][pos[1]].notes.clear();
    scoreManager.currentScore = (scoreManager.currentScore - hintCost).clamp(0, 999999);
    _checkCompletion();
    notifyListeners();
  }

  void newGame(Difficulty d) {
    difficulty = d;
    isComplete = false;
    deleteSavedGame(d);
    errorCount = 0;
    _errorRevealTimer?.cancel();
    _showErrorsTemporarily = false;
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
    if (quickMode && activeNumber != null) {
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
      if (!quickMode && selectedRow != null && selectedCol != null) {
        applyNumber(n!);
      } else {
        previousPlacedRow = null; previousPlacedCol = null;
        selectedRow = null; selectedCol = null;
        lastPlacedRow = null; lastPlacedCol = null;
      }
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
        if (showErrors) mult *= 0.10;
        if (highlightLines) mult *= 0.25;
        if (highlightNumbers) mult *= 0.50;
        if (highlightSelect) mult *= 0.75;
        final before = scoreManager.currentScore;
        scoreManager.handleCorrectMove(difficulty, mult);
        final gained = scoreManager.currentScore - before;
        if (gained > 0) {
          recentPoints = gained;
          _recentPointsTimer?.cancel();
          _recentPointsTimer = Timer(const Duration(milliseconds: 1200), () {
            recentPoints = 0;
            notifyListeners();
          });
        }
      } else if (!isCorrect && n != 0 && cell.value != n) {
        errorCount++;
        if (errorCount >= 3) {
          scoreManager.handleErrorThreshold(difficulty);
        }
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

  void toggleQuickMode() { quickMode = !quickMode; notifyListeners(); }
  void setRelaxMode(bool value) { relaxMode = value; notifyListeners(); }
  void togglePencil() { pencilMode = !pencilMode; notifyListeners(); }
  void toggleErrors() { showErrors = !showErrors; notifyListeners(); }
  void toggleHighlightSelect() { highlightSelect = !highlightSelect; notifyListeners(); }
  void toggleHighlightNumbers() { highlightNumbers = !highlightNumbers; notifyListeners(); }
  void toggleHighlightLines() { highlightLines = !highlightLines; notifyListeners(); }

  void _checkCompletion() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c].value != _solution[r][c]) return;
      }
    }
    isComplete = true;
    deleteSavedGame(difficulty);

    // Highscore speichern
    highscores.add(HighscoreEntry(
      userName: activeProfile.initials,
      profileColor: activeProfile.color,
      score: scoreManager.currentScore,
      difficulty: difficulty.name,
      date: DateTime.now(),
    ));
    
    notifyListeners();
  }

  int get nextMovePoints {
    double mult = 1.0;
    if (showErrors) mult *= 0.10;
    if (highlightLines) mult *= 0.25;
    if (highlightNumbers) mult *= 0.50;
    if (highlightSelect) mult *= 0.75;
    double base = {
      Difficulty.easy: 50,
      Difficulty.medium: 100,
      Difficulty.hard: 200,
      Difficulty.expert: 400,
    }[difficulty]!.toDouble();
    return (base * mult * scoreManager.scoreMultiplier).toInt();
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
    if (_showErrorsTemporarily) return !grid[r][c].given && grid[r][c].value != 0 && grid[r][c].value != _solution[r][c];
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
  void dispose() { _tickTimer?.cancel(); _recentPointsTimer?.cancel(); _errorRevealTimer?.cancel(); super.dispose(); }
}