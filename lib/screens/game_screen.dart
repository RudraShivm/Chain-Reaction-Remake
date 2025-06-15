import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chain_reaction/algo/chain_reaction_game.dart';
import 'package:chain_reaction/theme/app_theme.dart';
import 'package:chain_reaction/game_config.dart';

class GameScreen extends StatefulWidget {
  final ChainReactionGame game;
  final Mode mode;
  const GameScreen(this.game, this.mode, {super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  MapEntry<int, int>? _selectedCell;
  late AnimationController _animationController;
  Timer? _terminalStateTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    widget.game.onStateChanged = (board) {
      _terminalStateTimer = Timer(
        Duration(milliseconds: GameConfig.delayMove * 3),
        () {
          if (mounted) {
            if (widget.game.isTerminalState(board)) {
              if (mounted) {
                debugPrint('Terminal state detected, navigating to victory');
                widget.game.cancelToken.cancel();
                // update timer
                final gameEndTime = DateTime.now();
                GameConfig.duration =
                    (GameConfig.duration ?? 0) +
                    gameEndTime.difference(GameConfig.gameStartTime!).inSeconds;
                GameConfig.saveGameResult(widget.game.winner).then((_) {
                  if (mounted) {
                    widget.game.resetGame().then((_) {
                      if (mounted) {
                        Navigator.pop(context); // Close dialog if present
                        Navigator.pushNamed(context, '/victory');
                      }
                    });
                  }
                });
              }
            } else {
              setState(() {}); // Trigger rebuild for non-terminal state changes
            }
          }
        },
      );
    };
    widget.game.onCellSelected = (cell) {
      if (mounted) {
        setState(() {
          _selectedCell = cell;
        });
        _animationController.forward(from: 0).then((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    };
    if (widget.game.cancelToken.isCanceled) {
      widget.game.cancelToken.allow();
    }
    widget.game.writeGameState('');
    widget.game.readGameState();
  }

  @override
  void dispose() {
    debugPrint('Disposing GameScreen, canceling timer and game operations');
    _terminalStateTimer?.cancel();
    widget.game.cancelToken.cancel();
    _animationController.dispose();
    widget.game.onStateChanged = null;
    widget.game.onCellSelected = null;
    super.dispose();
  }

  void _handleTap(int row, int col) async {
    String player = widget.game.currentPlayer == Player.blue ? 'B' : 'R';
    if (widget.game.board[row][col] == '0' ||
        widget.game.board[row][col].endsWith(player)) {
      widget.game.onCellSelected?.call(MapEntry(row, col));
      widget.game.board[row][col] =
          '${int.parse(widget.game.board[row][col][0]) + 1}$player';
      await widget.game.writeGameState('');
      widget.game.board = widget.game.processExplosions(
        widget.game.board,
        widget.game.currentPlayer,
      );
      await widget.game.writeGameState(
        '${GameConfig.playerNameMap[widget.game.currentPlayer]} Move:',
      );
      await widget.game.readGameState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chain Reaction'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color.fromARGB(255, 168, 168, 168),
          ),
          onPressed: () {
            debugPrint('Back button pressed, canceling game operations');
            // update timer
            final gamePauseTime = DateTime.now();
            GameConfig.duration =
                (GameConfig.duration ?? 0) +
                gamePauseTime.difference(GameConfig.gameStartTime!).inSeconds;
            widget.game.cancelToken.cancel();
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        color: AppTheme.backgroundGradientStart,
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.backgroundGradientStart,
                widget.game.currentPlayer == Player.blue
                    ? AppTheme.backgroundGradientBlueEnd
                    : AppTheme.backgroundGradientRedEnd,
              ],
              stops: const [0.0, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.game.playerHumanMap[widget.game.currentPlayer]!
                        ? '${GameConfig.playerNameMap[widget.game.currentPlayer]!}\'s turn'
                        : GameConfig.playerHeuristicMap[widget
                                .game
                                .currentPlayer]! ==
                            Heuristic.Random
                        ? 'Random agent\'s turn'
                        : widget.game.currentPlayer == Player.blue
                        ? 'Blue AI is thinking'
                        : 'Red AI is thinking',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      color: const Color.fromARGB(221, 255, 255, 255),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 360,
                    height: 540,
                    padding: const EdgeInsets.all(8),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            childAspectRatio: 1,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                      itemCount: GameConfig.rows * GameConfig.cols,
                      itemBuilder: (context, index) {
                        int row = index ~/ 6;
                        int col = index % 6;
                        String cell = widget.game.board[row][col];
                        bool isCritical =
                            int.parse(cell[0]) >=
                            widget.game.getCriticalMass(row, col);
                        bool isSelected =
                            _selectedCell != null &&
                            _selectedCell!.key == row &&
                            _selectedCell!.value == col;
                        int orbCount = int.parse(cell[0]);

                        return GestureDetector(
                              onTap:
                                  () =>
                                      widget.game.playerHumanMap[widget
                                              .game
                                              .currentPlayer]!
                                          ? _handleTap(row, col)
                                          : null,
                              child: AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  double glowOpacity =
                                      isSelected
                                          ? _animationController.value
                                          : 0.0;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      color:
                                          cell.endsWith('R')
                                              ? AppTheme.redBoxColor
                                                  .withOpacity(0.8)
                                              : cell.endsWith('B')
                                              ? AppTheme.blueBoxColor
                                                  .withOpacity(0.8)
                                              : const Color.fromARGB(
                                                255,
                                                54,
                                                58,
                                                60,
                                              ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: isSelected ? 8 : 4,
                                          offset: const Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          if (cell != '0')
                                            Wrap(
                                              alignment: WrapAlignment.center,
                                              spacing: 4,
                                              runSpacing: 4,
                                              children: List.generate(
                                                orbCount,
                                                (index) {
                                                  return Container(
                                                    width: 12,
                                                    height: 12,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color:
                                                          cell.endsWith('R')
                                                              ? AppTheme
                                                                  .redOrbColor
                                                              : AppTheme
                                                                  .blueOrbColor,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          if (isCritical || isSelected)
                                            Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white
                                                        .withOpacity(0.2),
                                                  ),
                                                )
                                                .animate(
                                                  onPlay:
                                                      (controller) =>
                                                          controller.repeat(
                                                            reverse: true,
                                                          ),
                                                )
                                                .scale(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  begin: const Offset(1, 1),
                                                  end: const Offset(1.5, 1.5),
                                                )
                                                .fade(begin: 0.5, end: 1),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                            .animate()
                            .scale(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutBack,
                            )
                            .fadeIn();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.game.lastAIMoveDepth != -1
                        ? '${widget.game.currentPlayer == Player.blue ? 'Blue' : ' Red'} AI move: Depth ${widget.game.lastAIMoveDepth} | Eval ${widget.game.lastAIMoveEval}'
                        : '',
                    style: GoogleFonts.lato(
                      fontSize: 10,
                      color: const Color.fromARGB(221, 255, 255, 255),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
