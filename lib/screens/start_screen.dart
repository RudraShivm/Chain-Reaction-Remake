import 'package:flutter/material.dart';
import 'dart:io';
import 'package:chain_reaction/game_config.dart';
import 'package:chain_reaction/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _canContinue = false;

  @override
  void initState() {
    super.initState();
    // Check for a saved game when the screen first loads.
    _updateContinueState();
  }

  /// Checks if a game is in progress and updates the state to show/hide the "Continue" button.
  void _updateContinueState() {
    bool gameInProgress = false;
    // The logic from your original hasSavedGame() method
    for (int i = 0; i < GameConfig.rows; i++) {
      for (int j = 0; j < GameConfig.cols; j++) {
        if (int.parse(GameConfig.game!.board[i][j][0]) != 0) {
          gameInProgress = true;
          break;
        }
      }
      if (gameInProgress) break;
    }

    // Use setState to trigger a rebuild with the updated state.
    setState(() {
      _canContinue = gameInProgress;
    });
  }

  /// Navigates to a new screen and updates the state upon returning.
  Future<void> _navigateAndWait(String routeName) async {
    // resume timer
    GameConfig.gameStartTime = DateTime.now();
    await Navigator.pushNamed(context, routeName);
    // After returning from the screen, re-check the game state.
    _updateContinueState();
  }

  /// Resets the game board and navigates to the GameScreen.
  void _startNewGame(BuildContext context, Mode mode) {
    GameConfig.gameMode = mode;
    GameConfig.game!.resetGame();
    GameConfig.duration = 0;
    Navigator.pop(context); // Close the dialog
    _navigateAndWait('/game'); // Navigate and wait for return
  }

  /// Shows the dialog for selecting the game mode.
  void _showGameModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppTheme.backgroundGradientStart,
            title: Text(
              "Select New Game Mode",
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    "Human vs Human",
                    style: TextStyle(color: Colors.white70),
                  ),
                  onTap: () => _startNewGame(context, Mode.HumanvsHuman),
                ),
                ListTile(
                  title: Text(
                    "Human vs AI",
                    style: TextStyle(color: Colors.white70),
                  ),
                  onTap: () => _startNewGame(context, Mode.HumanvsAI),
                ),
                ListTile(
                  title: Text(
                    "AI vs AI",
                    style: TextStyle(color: Colors.white70),
                  ),
                  onTap: () => _startNewGame(context, Mode.AIvsAI),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppTheme.backgroundGradientStart,
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                    "Chain Reaction",
                    style: Theme.of(context).textTheme.headlineLarge,
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: -0.5, curve: Curves.easeOut),
              SizedBox(height: 80),
              if (_canContinue)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.blueBoxColor.withOpacity(0.8),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  onPressed: () => _navigateAndWait('/game'),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -1),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.blueBoxColor.withOpacity(0.8),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: () {
                  _showGameModeDialog(context);
                },
                child: Text(
                  'New Game',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideX(begin: 1),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.blueBoxColor.withOpacity(0.8),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: () => _navigateAndWait('/settings'),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms).slideX(begin: -1),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.blueBoxColor.withOpacity(0.8),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: () => _navigateAndWait('/history'),
                child: Text(
                  'History',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).slideX(begin: 1),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.redBoxColor.withOpacity(0.8),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: () => exit(0),
                child: Text(
                  'Exit',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms).slideX(begin: -1),
            ],
          ),
        ),
      ),
    );
  }
}
