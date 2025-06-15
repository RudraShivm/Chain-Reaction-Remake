import 'package:chain_reaction/screens/game_screen.dart';
import 'package:chain_reaction/screens/history_screen.dart';
import 'package:flutter/material.dart';
import 'dart:io';
// Conditional import for window_size only on desktop
// ignore: uri_does_not_exist
import 'window_size_stub.dart'
    if (dart.library.io) 'package:window_size/window_size.dart';
import 'screens/start_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/victory_screen.dart';
import 'package:chain_reaction/game_config.dart';
import 'package:chain_reaction/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GameConfig.initialize();
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chain Reaction',
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const StartScreen(),
        '/game': (context) => GameScreen(GameConfig.game!, GameConfig.gameMode),
        '/settings': (context) => const SettingsScreen(),
        '/victory': (context) => const VictoryScreen(),
        '/history': (context) => const HistoryScreen(),
      },
    );
  }
}
