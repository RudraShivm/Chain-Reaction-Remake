import 'dart:convert';
import 'dart:io';
import 'package:chain_reaction/algo/chain_reaction_game.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum Mode { HumanvsHuman, HumanvsAI, AIvsAI }

enum Heuristic {
  OrbCount,
  CriticalMass,
  OpponentMobility,
  ExplosionPotential,
  Balanced,
  Random,
}

class GameConfig {
  static const String _configFileName = 'config.json';
  static const String _historyFileName = 'game_history.json';
  static Mode gameMode = Mode.HumanvsHuman;
  static int rows = 9;
  static int cols = 6;
  static int delayMove =
      400; // delay in miliseconds. In case AI move, it doubles.
  static Map<Player, String> playerNameMap = {
    Player.blue: "Player 1",
    Player.red: "Player 2",
  };
  static Map<Player, Heuristic> playerHeuristicMap = {
    Player.blue: Heuristic.Balanced,
    Player.red: Heuristic.Balanced,
  };
  static Map<Player, int> playerDepthMap = {Player.blue: 1, Player.red: 1};
  static Map<Player, int> playerTimeLimitMap = {Player.blue: 2, Player.red: 2};
  static ChainReactionGame? game;
  static DateTime? gameStartTime; // Track game start time
  static int? duration; 

  // Initialize configuration by loading from JSON file
  static Future<void> initialize() async {
    try {
      final file = await _getConfigFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        _loadFromJson(json);
      } else {
        // Create file with default values if it doesn't exist
        await saveConfig();
      }
      // Initialize game with existing board
      game = ChainReactionGame(board: await ChainReactionGame.existingBoard());
    } catch (e) {
      // Fallback to defaults on error
      debugPrint('Error loading config: $e. Using default values.');
      await saveConfig(); // Ensure file exists with defaults
      game = ChainReactionGame(board: await ChainReactionGame.existingBoard());
    }
  }

  // Save current configuration to JSON file
  static Future<void> saveConfig() async {
    try {
      final json = _toJson();
      final file = await _getConfigFile();
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      debugPrint('Error saving config: $e');
    }
  }

  // Get the config file path
  static Future<File> _getConfigFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_configFileName');
  }

  // Get the history file path
  static Future<File> _getHistoryFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_historyFileName');
  }

  // Convert config to JSON
  static Map<String, dynamic> _toJson() {
    return {
      'gameMode': gameMode.toString().split('.').last,
      'rows': rows,
      'cols': cols,
      'delayMove': delayMove,
      'playerNameMap': {
        'blue': playerNameMap[Player.blue],
        'red': playerNameMap[Player.red],
      },
      'playerHeuristicMap': {
        'blue': playerHeuristicMap[Player.blue].toString().split('.').last,
        'red': playerHeuristicMap[Player.red].toString().split('.').last,
      },
      'playerDepthMap': {
        'blue': playerDepthMap[Player.blue],
        'red': playerDepthMap[Player.red],
      },
      'playerTimeLimitMap': {
        'blue': playerTimeLimitMap[Player.blue],
        'red': playerTimeLimitMap[Player.red],
      },
    };
  }

  // Load config from JSON
  static void _loadFromJson(Map<String, dynamic> json) {
    gameMode = Mode.values.firstWhere(
      (e) => e.toString().split('.').last == json['gameMode'],
      orElse: () => Mode.HumanvsHuman,
    );
    rows = json['rows'] as int? ?? 9;
    cols = json['cols'] as int? ?? 6;
    delayMove = json['delayMove'] as int? ?? 400;
    final playerNames = json['playerNameMap'] as Map<String, dynamic>?;
    playerNameMap = {
      Player.blue: playerNames?['blue'] as String? ?? "Player 1",
      Player.red: playerNames?['red'] as String? ?? "Player 2",
    };
    final playerHeuristics =
        json['playerHeuristicMap'] as Map<String, dynamic>?;
    playerHeuristicMap = {
      Player.blue: Heuristic.values.firstWhere(
        (e) =>
            e.toString().split('.').last ==
            (playerHeuristics?['blue'] as String?),
        orElse: () => Heuristic.Balanced,
      ),
      Player.red: Heuristic.values.firstWhere(
        (e) =>
            e.toString().split('.').last ==
            (playerHeuristics?['red'] as String?),
        orElse: () => Heuristic.Balanced,
      ),
    };
    final playerDepths = json['playerDepthMap'] as Map<String, dynamic>?;
    playerDepthMap = {
      Player.blue: (playerDepths?['blue'] as int?) ?? 1,
      Player.red: (playerDepths?['red'] as int?) ?? 1,
    };
    final playerTimeLimits =
        json['playerTimeLimitMap'] as Map<String, dynamic>?;
    playerTimeLimitMap = {
      Player.blue: (playerTimeLimits?['blue'] as int?) ?? 2,
      Player.red: (playerTimeLimits?['red'] as int?) ?? 2,
    };
  }

  // Save game result to history
  static Future<void> saveGameResult(Player winner) async {
    try {
      final file = await _getHistoryFile();
      Map<String, dynamic> historyData = {
        'games': [],
        'globalStats': {
          'totalGamesByMode': {
            for (var mode in Mode.values) mode.toString().split('.').last: 0,
          },
          'gamesByHeuristic': {
            for (var heuristic in Heuristic.values)
              heuristic.toString().split('.').last: 0,
          },
          'winsByHeuristic': {
            for (var heuristic in Heuristic.values)
              heuristic.toString().split('.').last: 0,
          },
        },
      };

      // Load existing history
      if (await file.exists()) {
        final content = await file.readAsString();
        historyData = jsonDecode(content) as Map<String, dynamic>;
      }

      // Update game history
      final gameRecord = {
        'mode': gameMode.toString().split('.').last,
        'winner': winner == Player.blue ? 'Blue' : 'Red',
        'winnerName': playerNameMap[winner],
        'bluePlayerName': playerNameMap[Player.blue],
        'redPlayerName': playerNameMap[Player.red],
        'blueHeuristic':
            game!.playerHumanMap[Player.blue]!
                ? null
                : playerHeuristicMap[Player.blue]!.toString().split('.').last,
        'redHeuristic':
            game!.playerHumanMap[Player.red]!
                ? null
                : playerHeuristicMap[Player.red]!.toString().split('.').last,
        'bluePlayerDepth': game!.playerHumanMap[Player.blue]! ? null : playerDepthMap[Player.blue],
        'redPlayerDepth': game!.playerHumanMap[Player.red]! ? null : playerDepthMap[Player.red],
        'timestamp': DateTime.now().toIso8601String(),
        'duration': duration, // Store duration in seconds
      };

      List games = List.from(historyData['games'] ?? []);
      games.insert(0, gameRecord);
      if (games.length > 10) {
        games = games.sublist(0, 10);
      }
      historyData['games'] = games;

      // Update global statistics
      final modeName = gameMode.toString().split('.').last;
      historyData['globalStats']['totalGamesByMode'][modeName] =
          (historyData['globalStats']['totalGamesByMode'][modeName] as int? ??
              0) +
          1;

      // Update heuristic stats for AI players
      if (!game!.playerHumanMap[Player.blue]!) {
        final blueHeuristic =
            playerHeuristicMap[Player.blue]!.toString().split('.').last;
        historyData['globalStats']['gamesByHeuristic'][blueHeuristic] =
            (historyData['globalStats']['gamesByHeuristic'][blueHeuristic]
                    as int? ??
                0) +
            1;
        if (winner == Player.blue) {
          historyData['globalStats']['winsByHeuristic'][blueHeuristic] =
              (historyData['globalStats']['winsByHeuristic'][blueHeuristic]
                      as int? ??
                  0) +
              1;
        }
      }
      if (!game!.playerHumanMap[Player.red]!) {
        final redHeuristic =
            playerHeuristicMap[Player.red]!.toString().split('.').last;
        historyData['globalStats']['gamesByHeuristic'][redHeuristic] =
            (historyData['globalStats']['gamesByHeuristic'][redHeuristic]
                    as int? ??
                0) +
            1;
        if (winner == Player.red) {
          historyData['globalStats']['winsByHeuristic'][redHeuristic] =
              (historyData['globalStats']['winsByHeuristic'][redHeuristic]
                      as int? ??
                  0) +
              1;
        }
      }

      // Save updated history
      await file.writeAsString(jsonEncode(historyData));
    } catch (e) {
      debugPrint('Error saving game result: $e');
    }
  }

  // Clear game history and statistics
  static Future<void> clearHistory() async {
    try {
      final file = await _getHistoryFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  // Reset to default values and save
  static Future<void> resetConfig() async {
    gameMode = Mode.HumanvsHuman;
    rows = 9;
    cols = 6;
    delayMove = 400;
    playerNameMap = {Player.blue: "Player 1", Player.red: "Player 2"};
    playerHeuristicMap = {
      Player.blue: Heuristic.Balanced,
      Player.red: Heuristic.Balanced,
    };
    playerDepthMap = {Player.blue: 1, Player.red: 1};
    playerTimeLimitMap = {Player.blue: 2, Player.red: 2};
    gameStartTime = null; // Reset game start time
    await saveConfig();
    game = ChainReactionGame(board: await ChainReactionGame.existingBoard());
  }
}
