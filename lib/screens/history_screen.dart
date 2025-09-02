import 'package:flutter/material.dart';
import 'package:chain_reaction/game_config.dart';
import 'package:chain_reaction/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _gameHistory = [];
  Map<String, dynamic> _globalStats = {
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
  };

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final file = await _getHistoryFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        setState(() {
          _gameHistory = List<Map<String, dynamic>>.from(json['games'] ?? []);
          _globalStats = json['globalStats'] ?? _globalStats;
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<File> _getHistoryFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/game_history.json');
  }

  Map<String, double> _calculateWinPercentages() {
    final winPercentages = <String, double>{};
    for (var heuristic in Heuristic.values) {
      final heuristicName = heuristic.toString().split('.').last;
      final games =
          (_globalStats['gamesByHeuristic'][heuristicName] as int?) ?? 0;
      final wins =
          (_globalStats['winsByHeuristic'][heuristicName] as int?) ?? 0;
      winPercentages[heuristicName] =
          games > 0 ? (wins / games * 100).toDouble() : 0.0;
    }
    return winPercentages;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return minutes > 0
        ? '$minutes min ${remainingSeconds}s'
        : '${remainingSeconds}s';
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.backgroundGradientStart,
            title: Text(
              'Clear History',
              style: GoogleFonts.lato(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to clear all game history and statistics? This action cannot be undone.',
              style: GoogleFonts.lato(fontSize: 16, color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.lato(fontSize: 16, color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await GameConfig.clearHistory();
                  setState(() {
                    _gameHistory = [];
                    _globalStats = {
                      'totalGamesByMode': {
                        for (var mode in Mode.values)
                          mode.toString().split('.').last: 0,
                      },
                      'gamesByHeuristic': {
                        for (var heuristic in Heuristic.values)
                          heuristic.toString().split('.').last: 0,
                      },
                      'winsByHeuristic': {
                        for (var heuristic in Heuristic.values)
                          heuristic.toString().split('.').last: 0,
                      },
                    };
                  });
                  Navigator.pop(context);
                },
                child: Text(
                  'Clear',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: AppTheme.redBoxColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final winPercentages = _calculateWinPercentages();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Game History"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Color.fromARGB(255, 168, 168, 168),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            color: Color.fromARGB(255, 168, 168, 168),
            onPressed: _gameHistory.isEmpty ? null : _clearHistory,
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: Container(
        color: AppTheme.backgroundGradientStart,
        height: MediaQuery.of(context).size.height,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.backgroundGradientStart,
                AppTheme.backgroundGradientBlueEnd,
              ],
              stops: const [0.8, 1.0],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Win Percentages by Heuristic
                  Text(
                    'Win Percentages by Heuristic',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(duration: 200.ms),
                  const SizedBox(height: 10),
                  ...Heuristic.values.map((heuristic) {
                    final heuristicName = heuristic.toString().split('.').last;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            heuristicName,
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),

                          Row(
                            children: [
                              Text(
                                '(${_globalStats['winsByHeuristic'][heuristicName]}/${_globalStats['gamesByHeuristic'][heuristicName]}) ',
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  color: Colors.white38,
                                ),
                              ),
                              Text(
                                '${winPercentages[heuristicName]!.toStringAsFixed(1)}%',
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 250.ms);
                  }),
                  const SizedBox(height: 20),
                  // Global Statistics
                  Text(
                    'Global Statistics',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 10),
                  Text(
                    'Total Games by Mode:',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ).animate().fadeIn(duration: 350.ms),
                  ...Mode.values.map((mode) {
                    final modeName = mode.toString().split('.').last;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            modeName,
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '${(_globalStats['totalGamesByMode'][modeName] as int?) ?? 0}',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms);
                  }),
                  const SizedBox(height: 20),
                  // Last 10 Games
                  Text(
                    'Last 10 Games',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(duration: 450.ms),
                  const SizedBox(height: 10),
                  if (_gameHistory.isEmpty)
                    Text(
                      'No game history available.',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ).animate().fadeIn(duration: 500.ms)
                  else
                    ..._gameHistory.asMap().entries.map((entry) {
                      final index = entry.key;
                      final game = entry.value;
                      final mode = game['mode'];
                      final winner = game['winner'];
                      final winnerName = game['winnerName'];
                      final bluePlayerName = game['bluePlayerName'];
                      final redPlayerName = game['redPlayerName'];
                      final blueHeuristic = game['blueHeuristic'];
                      final redHeuristic = game['redHeuristic'];
                      final timestamp = DateTime.parse(game['timestamp']);
                      final duration = game['duration'] as int? ?? 0;
                      var winnerHeuristic;
                      if (winner == 'Blue' && blueHeuristic != null) {
                        winnerHeuristic = blueHeuristic;
                      } else if (winner == 'Red' && redHeuristic != null) {
                        winnerHeuristic = redHeuristic;
                      }
                      return Card(
                        color:
                            winner == 'Blue'
                                ? AppTheme.blueBoxColor.withOpacity(0.8)
                                : AppTheme.redBoxColor.withOpacity(0.8),
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(
                            'Game ${index + 1}: ${(winnerHeuristic != null)
                                ? winnerHeuristic == 'Random'
                                    ? 'Random Agent'
                                    : '$winner AI'
                                : winnerName} won in $mode',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Blue: ${blueHeuristic != null
                                    ? blueHeuristic == 'Random'
                                        ? 'Random Agent'
                                        : 'AI with $blueHeuristic D:${game['bluePlayerDepth']}'
                                    : '$bluePlayerName'}',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                'Red: ${redHeuristic != null
                                    ? redHeuristic == 'Random'
                                        ? 'Random Agent'
                                        : 'AI with $redHeuristic D:${game['redPlayerDepth']}'
                                    : '$redPlayerName'}',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                'Played on: ${timestamp.toLocal().toString().split('.')[0]}',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                'Duration: ${_formatDuration(duration)}',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(
                        duration: Duration(milliseconds: 500 + index * 50),
                      );
                    }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
