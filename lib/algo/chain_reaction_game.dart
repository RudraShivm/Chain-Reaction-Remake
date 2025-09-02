import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:chain_reaction/game_config.dart';
import 'package:path_provider/path_provider.dart';

enum Player { blue, red }

class CancelToken {
  bool _isCanceled = false;

  bool get isCanceled => _isCanceled;

  void cancel() {
    _isCanceled = true;
  }

  void allow() {
    _isCanceled = false;
  }
}

class MinimaxArgs {
  final List<List<String>> board;
  final Player player;
  final int depth;
  final int aiTimeLimit;
  final CancelToken cancelToken;
  final Heuristic blueHeuristic;
  final Heuristic redHeuristic;
  MinimaxArgs(
    this.board,
    this.player,
    this.depth,
    this.aiTimeLimit,
    this.cancelToken,
    this.blueHeuristic,
    this.redHeuristic,
  );
}

class TimeLimitedException implements Exception {
  final String message;
  TimeLimitedException(this.message);
}

// This function will be run in the background isolate
GameState runMinimax(MinimaxArgs args) {
  final game = ChainReactionGame(board: args.board);
  final startTime = DateTime.now();
  GameState? bestMoveSoFar;
  int maxDepth = args.depth;
  for (int depth = 1; depth <= maxDepth; depth++) {
    if (args.cancelToken.isCanceled) {
      debugPrint('Minimax canceled at depth $depth');
      break;
    }
    try {
      debugPrint('AI searching at depth: $depth');
      final GameState currentBestMove = game.minimax(
        args.board,
        depth,
        -pow(2, 31).toInt(),
        pow(2, 31).toInt(),
        args.player == Player.blue,
        startTime,
        args.aiTimeLimit,
        args.cancelToken,
        args.player == Player.blue ? args.blueHeuristic : args.redHeuristic,
      );

      bestMoveSoFar = currentBestMove;
    } on TimeLimitedException {
      debugPrint(
        'Time limit exceeded during search at depth $depth. Using best move from depth ${depth - 1}.',
      );
      break;
    }
  }
  if (bestMoveSoFar == null) {
    debugPrint(
      "Timeout even at depth 1 or canceled. Returning first available move as a fallback.",
    );
    final children = game.getChildren(
      args.board,
      args.player,
      startTime,
      args.aiTimeLimit,
      args.cancelToken,
    );
    if (children.isNotEmpty) {
      return GameState(
        game.evaluate(
          children.first.$2,
          args.player == Player.blue ? args.blueHeuristic : args.redHeuristic,
        ),
        1,
        children.first.$1,
        children.first.$2,
        children.first.$3,
      );
    } else {
      return GameState(0, 0, args.board, args.board, false);
    }
  }

  return bestMoveSoFar;
}

class GameState {
  int eval = 0;
  int depth = 0;
  List<List<String>> boardConfig = [];
  List<List<String>> explodedBoardConfig = [];
  bool
  neededExplosion; // whether boardConfig and explodedBoardConfig is same or not
  GameState(
    this.eval,
    this.depth,
    this.boardConfig,
    this.explodedBoardConfig,
    this.neededExplosion,
  );
}

class ChainReactionGame {
  List<List<String>> board = List.generate(
    GameConfig.rows,
    (_) => List.filled(GameConfig.cols, '0'),
  );
  Player currentPlayer = Player.blue;
  Player winner = Player.blue;
  int lastAIMoveDepth = -1;
  int lastAIMoveEval = -1;
  static const String _fileName = 'gamestate.txt';
  ValueChanged<List<List<String>>>? onStateChanged;
  ValueChanged<MapEntry<int, int>>? onCellSelected;
  CancelToken cancelToken = CancelToken();

  ChainReactionGame({
    required this.board,
    this.onStateChanged,
    this.onCellSelected,
  });

  // Get the game state file path
  static Future<String> get filePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_fileName';
  }

  Map<Player, bool> get playerHumanMap {
    return GameConfig.gameMode == Mode.AIvsAI
        ? {Player.blue: false, Player.red: false}
        : GameConfig.gameMode == Mode.HumanvsAI
        ? {Player.blue: true, Player.red: false}
        : {Player.blue: true, Player.red: true};
  }

  bool isTimeUp(DateTime startTime, int timeLimit) {
    return DateTime.now().difference(startTime).inSeconds >= timeLimit;
  }

  int getCriticalMass(int row, int col) {
    int neighbors = 0;
    if (row > 0) neighbors++;
    if (row < GameConfig.rows - 1) neighbors++;
    if (col > 0) neighbors++;
    if (col < GameConfig.cols - 1) neighbors++;
    return neighbors;
  }

  (List<List<String>>, bool) processExplosions(
    List<List<String>> board,
    Player player,
  ) {
    var tempBoard = board.map((row) => List<String>.from(row)).toList();
    String playerChar = player == Player.blue ? 'B' : 'R';
    Queue<MapEntry<int, int>> explosionQueue = Queue();
    Set<String> explodedThisPass = {};

    for (int r = 0; r < GameConfig.rows; r++) {
      for (int c = 0; c < GameConfig.cols; c++) {
        if (int.parse(tempBoard[r][c][0]) >= getCriticalMass(r, c)) {
          explosionQueue.add(MapEntry(r, c));
          explodedThisPass.add('$r,$c');
        }
      }
    }

    while (explosionQueue.isNotEmpty) {
      var cell = explosionQueue.removeFirst();
      int r = cell.key;
      int c = cell.value;

      tempBoard[r][c] = '0';

      final neighbors = [
        if (r > 0) MapEntry(r - 1, c),
        if (r < GameConfig.rows - 1) MapEntry(r + 1, c),
        if (c > 0) MapEntry(r, c - 1),
        if (c < GameConfig.cols - 1) MapEntry(r, c + 1),
      ];

      for (var neighbor in neighbors) {
        int nr = neighbor.key;
        int nc = neighbor.value;
        int newCount = int.parse(tempBoard[nr][nc][0]) + 1;
        tempBoard[nr][nc] = '$newCount$playerChar';

        if (newCount >= getCriticalMass(nr, nc) &&
            !explodedThisPass.contains('$nr,$nc')) {
          explosionQueue.add(MapEntry(nr, nc));
          explodedThisPass.add('$nr,$nc');
        }
      }
    }
    bool needsAnotherPass = false;
    bool boardSame = true;
    for (int r = 0; r < GameConfig.rows; r++) {
      for (int c = 0; c < GameConfig.cols; c++) {
        if (board[r][c] != tempBoard[r][c]) {
          boardSame = false;
        }
        if (int.parse(tempBoard[r][c][0]) >= getCriticalMass(r, c)) {
          needsAnotherPass = true;
        }
      }
    }

    if (needsAnotherPass && !boardSame) {
      final result = processExplosions(tempBoard, player);
      tempBoard = result.$1;
    }

    return (tempBoard, !boardSame);
  }

  bool isTerminalState(List<List<String>> position) {
    String dominantColor = '';
    bool allOneColor = true;
    int nonEmptyCount = 0;
    for (int i = 0; i < GameConfig.rows; i++) {
      for (int j = 0; j < GameConfig.cols; j++) {
        if (position[i][j] != '0') {
          nonEmptyCount++;
          String color = position[i][j].endsWith('R') ? 'R' : 'B';
          if (dominantColor.isEmpty) {
            dominantColor = color;
          } else if (dominantColor != color) {
            allOneColor = false;
            break;
          }
        }
      }
      if (!allOneColor) break;
    }
    return allOneColor && dominantColor.isNotEmpty && (nonEmptyCount > 1);
  }

  bool isEmpty(List<List<String>> position) {
    for (int i = 0; i < GameConfig.rows; i++) {
      for (int j = 0; j < GameConfig.cols; j++) {
        if (position[i][j] != '0') {
          return false;
        }
      }
    }
    return true;
  }

  GameState minimax(
    List<List<String>> position,
    int depth,
    int alpha,
    int beta,
    bool maximizingPlayer,
    DateTime startTime,
    int aiTimeLimit,
    CancelToken cancelToken,
    Heuristic currentPlayerHeuristic,
  ) {
    if (cancelToken.isCanceled) {
      throw TimeLimitedException('Minimax canceled');
    }
    if (isTimeUp(startTime, aiTimeLimit)) {
      throw TimeLimitedException('Time limit exceeded');
    }
    Player playerForThisTurn = maximizingPlayer ? Player.blue : Player.red;

    if (depth == 0 || isTerminalState(position)) {
      final (explodedPos, neededExplosion) = processExplosions(
        position,
        playerForThisTurn,
      );
      return GameState(
        evaluate(explodedPos, currentPlayerHeuristic),
        depth,
        position,
        explodedPos,
        neededExplosion,
      );
    }

    List<(List<List<String>>, List<List<String>>, bool)> children = getChildren(
      position,
      playerForThisTurn,
      startTime,
      aiTimeLimit,
      cancelToken,
    );

    if (maximizingPlayer) {
      int maxEval = -pow(2, 31).toInt();
      List<List<String>> bestState =
          children.isNotEmpty ? children.first.$1 : position;
      List<List<String>> bestExplodedState =
          children.isNotEmpty ? children.first.$2 : position;
      bool bestStateNeededExplosion =
          children.isNotEmpty ? children.first.$3 : true;
      for (var (state, explodedState, neededExplosion) in children) {
        if (cancelToken.isCanceled) {
          throw TimeLimitedException('Minimax canceled in loop');
        }
        if (isTimeUp(startTime, aiTimeLimit)) {
          throw TimeLimitedException('Time limit exceeded in minimax loop');
        }
        GameState childState = minimax(
          explodedState,
          depth - 1,
          alpha,
          beta,
          false,
          startTime,
          aiTimeLimit,
          cancelToken,
          currentPlayerHeuristic,
        );
        if (childState.eval > maxEval) {
          maxEval = childState.eval;
          bestState = state;
          bestExplodedState = explodedState;
          bestStateNeededExplosion = neededExplosion;
        }
        alpha = max(alpha, childState.eval);
        if (beta <= alpha) break;
      }
      return GameState(
        maxEval,
        depth,
        bestState,
        bestExplodedState,
        bestStateNeededExplosion,
      );
    } else {
      int minEval = pow(2, 31).toInt();
      List<List<String>> bestState =
          children.isNotEmpty ? children.first.$1 : position;
      List<List<String>> bestExplodedState =
          children.isNotEmpty ? children.first.$2 : position;
      bool bestStateNeededExplosion =
          children.isNotEmpty ? children.first.$3 : true;
      for (var (state, explodedState, neededExplosion) in children) {
        if (cancelToken.isCanceled) {
          throw TimeLimitedException('Minimax canceled in loop');
        }
        if (isTimeUp(startTime, aiTimeLimit)) {
          throw TimeLimitedException('Time limit exceeded in minimax loop');
        }
        GameState childState = minimax(
          explodedState,
          depth - 1,
          alpha,
          beta,
          true,
          startTime,
          aiTimeLimit,
          cancelToken,
          currentPlayerHeuristic,
        );
        if (childState.eval < minEval) {
          minEval = childState.eval;
          bestState = state;
          bestExplodedState = explodedState;
          bestStateNeededExplosion = neededExplosion;
        }
        beta = min(beta, childState.eval);
        if (beta <= alpha) break;
      }
      return GameState(
        minEval,
        depth,
        bestState,
        bestExplodedState,
        bestStateNeededExplosion,
      );
    }
  }

  List<(List<List<String>>, List<List<String>>, bool)> getChildren(
    List<List<String>> position,
    Player player,
    DateTime startTime,
    int aiTimeLimit,
    CancelToken cancelToken,
  ) {
    List<
      (
        List<List<String>> newBoard,
        List<List<String>> explodedBoard,
        int criticalMass,
        bool neededExplosion,
      )
    >
    tempChildren = [];
    String playerChar = player == Player.blue ? 'B' : 'R';

    for (int i = 0; i < GameConfig.rows; i++) {
      for (int j = 0; j < GameConfig.cols; j++) {
        if (cancelToken.isCanceled) {
          throw TimeLimitedException('GetChildren canceled');
        }
        if (isTimeUp(startTime, aiTimeLimit)) {
          throw TimeLimitedException('Time limit exceeded in getChildren');
        }
        if (position[i][j] == '0' || position[i][j].endsWith(playerChar)) {
          var newBoard = List<List<String>>.from(
            position.map((row) => List<String>.from(row)),
          );
          newBoard[i][j] = '${int.parse(newBoard[i][j][0]) + 1}$playerChar';

          int criticalMass = getCriticalMass(i, j);
          final (explodedBoard, neededExplosion) = processExplosions(
            newBoard,
            player,
          );
          tempChildren.add((
            newBoard,
            explodedBoard,
            criticalMass,
            neededExplosion,
          ));
        }
      }
    }

    tempChildren.sort((a, b) => a.$3.compareTo(b.$3));

    return tempChildren.map((child) => (child.$1, child.$2, child.$4)).toList();
  }

  int evaluate(List<List<String>> position, Heuristic heuristic) {
    switch (heuristic) {
      case Heuristic.OrbCount:
        return evaluateOrbCount(position);
      case Heuristic.CriticalMass:
        return evaluateCriticalMass(position);
      case Heuristic.OpponentMobility:
        return evaluateOpponentMobility(position);
      case Heuristic.ExplosionPotential:
        return evaluateExplosionPotential(position);
      // Balances multiple strategic aspects for robust evaluation.
      case Heuristic.Balanced:
        const weights = [0.3, 0.2, 0.2, 0.15];
        return (weights[0] * evaluateOrbCount(position) +
                weights[1] * evaluateCriticalMass(position) +
                weights[2] * evaluateOpponentMobility(position) +
                weights[3] * evaluateExplosionPotential(position))
            .toInt();
      case Heuristic.Random:
        return evaluateRandom();
    }
  }

  // OrbCount: Measures the normalized difference in orbs between AI (Blue) and opponent (Red).
  // Strategy: Prioritizes maximizing AI's orb count, assuming more orbs indicate a stronger position.
  // Normalized to [-100, 100] using max score (rows * cols * 4).
  int evaluateOrbCount(List<List<String>> position) {
    int score = 0;
    int totalOrb = 0;
    for (int i = 0; i < GameConfig.rows; i++) {
      for (int j = 0; j < GameConfig.cols; j++) {
        if (position[i][j].endsWith('B')) {
          score += int.parse(position[i][j][0]);
          totalOrb++;
        } else if (position[i][j].endsWith('R')) {
          score -= int.parse(position[i][j][0]);
          totalOrb++;
        }
      }
    }
    int maxScore = GameConfig.rows * GameConfig.cols * 4;
    return totalOrb == 0
        ? 0
        : ((100 * score / maxScore).clamp(-100, 100)).toInt();
  }

  // CriticalMass: Rewards cells nearing explosion based on orb-to-critical-mass ratio.
  // Strategy: Encourages moves that bring cells closer to triggering explosions, which can convert opponent orbs.
  // Normalized to [-100, 100] using max score (rows * cols).
  int evaluateCriticalMass(List<List<String>> position) {
    double score = 0;
    for (int i = 0; i < GameConfig.rows; i++) {
      for (int j = 0; j < GameConfig.cols; j++) {
        if (position[i][j] != '0') {
          int count = int.parse(position[i][j][0]);
          int criticalMass = getCriticalMass(i, j);
          double ratio = count / criticalMass;
          if (position[i][j].endsWith('B')) {
            score += ratio;
          } else if (position[i][j].endsWith('R')) {
            score -= ratio;
          }
        }
      }
    }
    int maxScore = GameConfig.rows * GameConfig.cols;
    return (100 * score / maxScore).clamp(-100, 100).toInt();
  }

  // OpponentMobility: Evaluates the difference in valid moves between AI and opponent.
  // Strategy: Aims to restrict opponent's options, limiting their strategic flexibility.
  // Normalized to [-100, 100] using max difference (rows * cols).
  int evaluateOpponentMobility(List<List<String>> position) {
    int playerMoves = 0;
    int oppMoves = 0;
    for (int i = 0; i < GameConfig.rows; i++) {
      for (int j = 0; j < GameConfig.cols; j++) {
        if (position[i][j] == '0' || position[i][j].endsWith('B')) {
          playerMoves++;
        }
        if (position[i][j] == '0' || position[i][j].endsWith('R')) {
          oppMoves++;
        }
      }
    }
    int maxDiff = GameConfig.rows * GameConfig.cols;
    return (100 * (playerMoves - oppMoves) / maxDiff).clamp(-100, 100).toInt();
  }

  // ExplosionPotential: Rewards cells one orb from exploding if adjacent to opponent or empty cells.
  // Strategy: Promotes chain reactions to capture opponent orbs or expand control.
  // Normalized to [-100, 100] using max score (rows * cols * 4).
  int evaluateExplosionPotential(List<List<String>> position) {
    double score = 0;
    for (int i = 0; i < GameConfig.rows; i++) {
      for (int j = 0; j < GameConfig.cols; j++) {
        if (position[i][j] != '0') {
          int count = int.parse(position[i][j][0]);
          int criticalMass = getCriticalMass(i, j);
          if (count == criticalMass - 1) {
            final neighbors = [
              if (i > 0) MapEntry(i - 1, j),
              if (i < GameConfig.rows - 1) MapEntry(i + 1, j),
              if (j > 0) MapEntry(i, j - 1),
              if (j < GameConfig.cols - 1) MapEntry(i, j + 1),
            ];
            for (var n in neighbors) {
              int ni = n.key, nj = n.value;
              if (position[ni][nj] != '0') {
                if (position[ni][nj].endsWith('R')) {
                  score += position[i][j].endsWith('B') ? 1 : -1;
                } else {
                  score += position[i][j].endsWith('R') ? -1 : 1;
                }
              } else {
                score += position[i][j].endsWith('B') ? 0.5 : -0.5;
              }
            }
          }
        }
      }
    }
    double maxScore = GameConfig.rows * GameConfig.cols * 4;
    return (100 * score / maxScore).clamp(-100, 100).toInt();
  }

  int evaluateRandom() {
    return Random().nextInt(201) - 100;
  }

  Future<void> makeAIMove([CancelToken? cancelToken]) async {
    cancelToken ??= CancelToken();
    final args = MinimaxArgs(
      board.map((row) => List<String>.from(row)).toList(),
      currentPlayer,
      GameConfig.playerDepthMap[currentPlayer]!,
      GameConfig.playerTimeLimitMap[currentPlayer]!,
      cancelToken,
      GameConfig.playerHeuristicMap[Player.blue]!,
      GameConfig.playerHeuristicMap[Player.red]!,
    );
    await Future.delayed(Duration(milliseconds: GameConfig.delayMove));
    try {
      final GameState bestMove = await compute(runMinimax, args);
      if (cancelToken.isCanceled) {
        debugPrint('AI move canceled before applying');
        return;
      }
      lastAIMoveDepth = bestMove.depth;
      lastAIMoveEval = bestMove.eval;
      String player = currentPlayer == Player.blue ? 'B' : 'R';
      bool moveFound = false;
      for (int i = 0; i < GameConfig.rows; i++) {
        for (int j = 0; j < GameConfig.cols; j++) {
          if (bestMove.boardConfig[i][j] != board[i][j] &&
              (board[i][j] == '0' || board[i][j].endsWith(player)) &&
              bestMove.boardConfig[i][j].endsWith(player)) {
            if (onCellSelected != null) {
              moveFound = true;
              onCellSelected!(MapEntry(i, j));
            }
            break;
          }
        }
        if (moveFound) break;
      }
      board = bestMove.boardConfig;
      await writeGameState('${GameConfig.playerNameMap[currentPlayer]} Move:');
      if (bestMove.neededExplosion) {
        await Future.delayed(
          Duration(milliseconds: (GameConfig.delayMove * 0.4).toInt()),
        );
        board = bestMove.explodedBoardConfig;
        await writeGameState(
          '${GameConfig.playerNameMap[currentPlayer]} Move:',
        );
      }
      await readGameState();
    } catch (e) {
      if (cancelToken.isCanceled) {
        debugPrint('AI move computation canceled');
      } else {
        debugPrint('Error in AI move: $e');
      }
    }
  }

  Future<void> writeGameState(String header) async {
    try {
      String content = "";
      if (header.isNotEmpty) {
        content = '$header\n';
      } else {
        final filePath = await ChainReactionGame.filePath;
        final file = File(filePath);
        if (await file.exists()) {
          content = await file.readAsString();
          content = '${LineSplitter.split(content).toList()[0]}\n';
        }
      }
      for (int i = 0; i < GameConfig.rows; i++) {
        content += '${board[i].join(' ')}\n';
      }
      final filePath = await ChainReactionGame.filePath;
      await File(filePath).writeAsString(content.trim());

      if (onStateChanged != null && !cancelToken._isCanceled) {
        winner = currentPlayer;
        onStateChanged!(board);
      }
    } catch (e) {
      debugPrint('Error writing game state: $e');
    }
  }

  Future<void> readGameState() async {
    try {
      final filePath = await ChainReactionGame.filePath;
      final file = File(filePath);
      if (await file.exists()) {
        String content = await file.readAsString();
        List<String> lines = LineSplitter.split(content).toList();
        if (!lines[0].contains(GameConfig.playerNameMap[Player.red]!) &&
            !lines[0].contains(GameConfig.playerNameMap[Player.blue]!)) {
          await writeGameState(
            '${GameConfig.playerNameMap[currentPlayer]} Move:',
          );
        }
        if (!cancelToken._isCanceled) {
          if (lines[0] == '${GameConfig.playerNameMap[Player.red]} Move:') {
            currentPlayer = Player.blue;
            if (!playerHumanMap[currentPlayer]! && !isTerminalState(board)) {
              await makeAIMove(cancelToken);
            }
          } else if (lines[0] ==
              '${GameConfig.playerNameMap[Player.blue]} Move:') {
            currentPlayer = Player.red;
            if (!playerHumanMap[currentPlayer]! && !isTerminalState(board)) {
              await makeAIMove(cancelToken);
            }
          }
        }
      } else {
        await resetGame();
      }
    } catch (e) {
      debugPrint('Error reading game state: $e');
      await resetGame();
    }
  }

  Future<void> resetGame() async {
    List<List<String>> defaultBoard = List.generate(
      GameConfig.rows,
      (_) => List.filled(GameConfig.cols, '0'),
    );
    String content =
        '${GameConfig.playerNameMap[Player.red]} Move:\n${defaultBoard.map((row) => row.join(' ')).join('\n')}';
    try {
      final filePath = await ChainReactionGame.filePath;
      await File(filePath).writeAsString(content);
    } catch (e) {
      debugPrint('Error resetting game state: $e');
    }
    GameConfig.game = this;
    cancelToken.allow();
    board = defaultBoard;
  }

  static Future<List<List<String>>> existingBoard() async {
    List<List<String>> defaultBoard = List.generate(
      GameConfig.rows,
      (_) => List.filled(GameConfig.cols, '0'),
    );
    try {
      final filePath = await ChainReactionGame.filePath;
      final file = File(filePath);
      if (await file.exists()) {
        String content = await file.readAsString();
        List<String> lines = LineSplitter.split(content).toList();
        List<List<String>> board = [];
        for (int i = 0; i < GameConfig.rows; i++) {
          board.add(lines[i + 1].split(' ').toList());
        }
        return board;
      } else {
        String content =
            '${GameConfig.playerNameMap[Player.red]} Move:\n${defaultBoard.map((row) => row.join(' ')).join('\n')}';
        await File(filePath).writeAsString(content);
        return defaultBoard;
      }
    } catch (e) {
      debugPrint('Error accessing game state file: $e. Using default board.');
      return defaultBoard;
    }
  }
}
