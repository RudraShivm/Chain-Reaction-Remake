import 'package:chain_reaction/game_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:chain_reaction/theme/app_theme.dart';
import 'package:chain_reaction/algo/chain_reaction_game.dart';

class VictoryScreen extends StatelessWidget {
  const VictoryScreen({super.key});

  Player get winner {
    return GameConfig.game!.winner;
  }

  String? get winnerName {
    return GameConfig.playerNameMap[winner];
  }

  bool get isWinnerHuman {
    return GameConfig.game!.playerHumanMap[winner] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    bool hasRandomHeuristic =
        GameConfig.playerHeuristicMap[winner] == Heuristic.Random;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          !isWinnerHuman && GameConfig.gameMode == Mode.HumanvsAI
              ? "Defeat"
              : "Victory!",
        ),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        color: AppTheme.backgroundGradientStart,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.backgroundGradientStart,
                winner == Player.blue
                    ? AppTheme.backgroundGradientBlueEnd
                    : AppTheme.backgroundGradientRedEnd,
              ],
              stops: [0.3, 0.6],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                      GameConfig.gameMode == Mode.HumanvsAI
                          ? isWinnerHuman
                              ? "You Won!"
                              : "You Lost"
                          : GameConfig.gameMode == Mode.AIvsAI
                          ? hasRandomHeuristic
                              ? 'Random Agent Won!'
                              : '${winner == Player.blue ? "Blue" : "Red"} AI Wins!'
                          : "$winnerName Wins!",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    .animate()
                    .scale(
                      delay: 300.ms,
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    )
                    .then()
                    .shimmer(duration: 1200.ms, color: Colors.white),
                SizedBox(height: 40),
                ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            GameConfig.game!.winner == Player.blue
                                ? AppTheme.blueBoxColor.withOpacity(0.9)
                                : AppTheme.redBoxColor.withOpacity(0.9),
                        padding: EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (route) => false,
                        );
                      },
                      child: Text(
                        "Back to Start",
                        style: TextStyle(
                          color: const Color.fromARGB(218, 255, 255, 255),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 1000.ms)
                    .slideY(begin: 2, curve: Curves.easeOut),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
