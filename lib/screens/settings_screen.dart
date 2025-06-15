import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:chain_reaction/game_config.dart';
import 'package:chain_reaction/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:chain_reaction/algo/chain_reaction_game.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Mode _selectedMode;
  late double _player1Depth;
  late double _player2Depth;
  late double _player1TimeLimit;
  late double _player2TimeLimit;
  late final TextEditingController _player1Controller;
  late final TextEditingController _player2Controller;
  late Heuristic _player1Heuristic;
  late Heuristic _player2Heuristic;
  late double _delayMove;

  @override
  void initState() {
    super.initState();
    // Initialize state from GameConfig
    _selectedMode = GameConfig.gameMode;
    _player1Depth = GameConfig.playerDepthMap[Player.blue]!.toDouble();
    _player2Depth = GameConfig.playerDepthMap[Player.red]!.toDouble();
    _player1TimeLimit = GameConfig.playerTimeLimitMap[Player.blue]!.toDouble();
    _player2TimeLimit = GameConfig.playerTimeLimitMap[Player.red]!.toDouble();
    _player1Controller = TextEditingController(
      text: GameConfig.playerNameMap[Player.blue],
    );
    _player2Controller = TextEditingController(
      text: GameConfig.playerNameMap[Player.red],
    );
    _player1Heuristic = GameConfig.playerHeuristicMap[Player.blue]!;
    _player2Heuristic = GameConfig.playerHeuristicMap[Player.red]!;
    _delayMove = GameConfig.delayMove.toDouble();
  }

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
  }

  void _saveSettings() {
    // Save state back to GameConfig
    GameConfig.gameMode = _selectedMode;
    GameConfig.playerDepthMap[Player.blue] = _player1Depth.toInt();
    GameConfig.playerDepthMap[Player.red] = _player2Depth.toInt();
    GameConfig.playerTimeLimitMap[Player.blue] = _player1TimeLimit.toInt();
    GameConfig.playerTimeLimitMap[Player.red] = _player2TimeLimit.toInt();
    GameConfig.playerNameMap[Player.blue] = _player1Controller.text;
    GameConfig.playerNameMap[Player.red] = _player2Controller.text;
    GameConfig.playerHeuristicMap[Player.blue] = _player1Heuristic;
    GameConfig.playerHeuristicMap[Player.red] = _player2Heuristic;
    GameConfig.delayMove = _delayMove.toInt();
    GameConfig.saveConfig();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Color.fromARGB(255, 168, 168, 168),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          // Scrollable content
          Container(
            height: MediaQuery.of(context).size.height,
            color: AppTheme.backgroundGradientStart,
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
                  ).copyWith(bottom: 80.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Player 1 Name TextField
                      Text(
                        'Blue Player Settings',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          color: const Color.fromARGB(221, 255, 255, 255),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _player1Controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.blueBoxColor,
                            ),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                      ).animate().fadeIn(duration: 200.ms),
                      const SizedBox(height: 10),
                      // Player 1 Heuristic Dropdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Blue AI Heuristic:",
                            style: TextStyle(fontSize: 15, color: Colors.white),
                          ),
                          DropdownButton<Heuristic>(
                            value: _player1Heuristic,
                            dropdownColor: AppTheme.backgroundGradientStart,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            items:
                                Heuristic.values
                                    .map(
                                      (heuristic) => DropdownMenuItem(
                                        value: heuristic,
                                        child: Text(
                                          heuristic.toString().split('.').last,
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              if (value != null && mounted) {
                                setState(() {
                                  _player1Heuristic = value;
                                });
                              }
                            },
                          ),
                        ],
                      ).animate().fadeIn(duration: 250.ms),
                      const SizedBox(height: 10),
                      // Player 1 AI Depth Slider
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Blue AI Depth: ${_player1Depth.toInt()}",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          Slider(
                            value: _player1Depth,
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: _player1Depth.toInt().toString(),
                            activeColor: AppTheme.blueBoxColor,
                            inactiveColor: AppTheme.secondaryColorBlue,
                            onChanged: (value) {
                              setState(() {
                                _player1Depth = value;
                              });
                            },
                          ),
                        ],
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 10),
                      // Player 1 AI Time Limit Slider
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Blue AI Time Limit: ${_player1TimeLimit.toInt()}s",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          Slider(
                            value: _player1TimeLimit,
                            min: 1,
                            max: 20,
                            divisions: 19,
                            label: "${_player1TimeLimit.toInt()}s",
                            activeColor: AppTheme.blueBoxColor,
                            inactiveColor: AppTheme.secondaryColorBlue,
                            onChanged: (value) {
                              setState(() {
                                _player1TimeLimit = value;
                              });
                            },
                          ),
                        ],
                      ).animate().fadeIn(duration: 350.ms),
                      const SizedBox(height: 20),
                      Text(
                        'Red Player Settings',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          color: const Color.fromARGB(221, 255, 255, 255),
                        ),
                      ),

                      const SizedBox(height: 10),
                      // Player 2 Name TextField
                      TextField(
                        controller: _player2Controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.redBoxColor),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: 10),
                      // Player 2 Heuristic Dropdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Red AI Heuristic:",
                            style: TextStyle(fontSize: 15, color: Colors.white),
                          ),
                          DropdownButton<Heuristic>(
                            value: _player2Heuristic,
                            dropdownColor: AppTheme.backgroundGradientStart,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            items:
                                Heuristic.values
                                    .map(
                                      (heuristic) => DropdownMenuItem(
                                        value: heuristic,
                                        child: Text(
                                          heuristic.toString().split('.').last,
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              if (value != null && mounted) {
                                setState(() {
                                  _player2Heuristic = value;
                                });
                              }
                            },
                          ),
                        ],
                      ).animate().fadeIn(duration: 450.ms),
                      const SizedBox(height: 10),
                      // Player 2 AI Depth Slider
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Red AI Depth: ${_player2Depth.toInt()}",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          Slider(
                            value: _player2Depth,
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: _player2Depth.toInt().toString(),
                            activeColor: AppTheme.redBoxColor,
                            inactiveColor: AppTheme.secondaryColorRed,
                            onChanged: (value) {
                              setState(() {
                                _player2Depth = value;
                              });
                            },
                          ),
                        ],
                      ).animate().fadeIn(duration: 500.ms),
                      const SizedBox(height: 10),
                      // Player 2 AI Time Limit Slider
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Red AI Time Limit: ${_player2TimeLimit.toInt()}s",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          Slider(
                            value: _player2TimeLimit,
                            min: 1,
                            max: 20,
                            divisions: 19,
                            label: "${_player2TimeLimit.toInt()}s",
                            activeColor: AppTheme.redBoxColor,
                            inactiveColor: AppTheme.secondaryColorRed,
                            onChanged: (value) {
                              setState(() {
                                _player2TimeLimit = value;
                              });
                            },
                          ),
                        ],
                      ).animate().fadeIn(duration: 550.ms),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Delay Between Moves: ${_delayMove.toInt()}ms",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Slider(
                            value: _delayMove,
                            min: 0,
                            max: 2000,
                            divisions: 10,
                            label: "${_delayMove.toInt()}ms",
                            activeColor: AppTheme.blueBoxColor,
                            inactiveColor: AppTheme.secondaryColorBlue,
                            onChanged: (value) {
                              setState(() {
                                _delayMove = value;
                              });
                            },
                          ),
                        ],
                      ).animate().fadeIn(duration: 550.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Fixed Save Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.blueBoxColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 20,
                  ),
                  elevation: 8, // Shadow for floating effect
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveSettings,
                child: const Text(
                  "Save",
                  style: TextStyle(
                    color: Color.fromARGB(218, 255, 255, 255),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().fadeIn(duration: 700.ms).slideY(begin: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
