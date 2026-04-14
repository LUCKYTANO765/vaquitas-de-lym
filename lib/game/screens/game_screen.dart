import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:provider/provider.dart';
import '../vaquitas_game.dart';
import '../game_state.dart';
import 'ending_screen.dart';
import 'level_transition_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late VaquitasGame _game;

  @override
  void initState() {
    super.initState();
    final gameState = context.read<GameState>();
    _game = VaquitasGame(
      gameState: gameState,
      onLevelComplete: _onLevelComplete,
      onGameOver: _onGameOver,
    );
  }

  void _onLevelComplete() {
    final state = context.read<GameState>();

    if (state.currentLevel >= state.totalLevels) {
      // Último nivel → ending con Lym
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EndingScreen()),
      );
      return;
    }

    // Calcular estrellas según score del nivel
    final stars = state.score >= 2000 ? 3 : state.score >= 1000 ? 2 : 1;

    // Mostrar pantalla de transición
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LevelTransitionScreen(
          level: state.currentLevel,
          score: state.score,
          stars: stars,
          onContinue: () {
            Navigator.pop(context);
            state.nextLevel();
            setState(() {
              _game = VaquitasGame(
                gameState: state,
                onLevelComplete: _onLevelComplete,
                onGameOver: _onGameOver,
              );
            });
          },
        ),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _onGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('💀 GAME OVER',
            style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 24)),
        content: const Text('¡Lym te está esperando!\n¿Intentas de nuevo?',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Menú', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              context.read<GameState>().lives = 3;
              setState(() {
                _game = VaquitasGame(
                  gameState: context.read<GameState>(),
                  onLevelComplete: _onLevelComplete,
                  onGameOver: _onGameOver,
                );
              });
            },
            child:
                const Text('REINTENTAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // El juego Flame ocupa toda la pantalla
          GameWidget(game: _game),

          // HUD: vidas y puntuación arriba
          Positioned(
            top: 8,
            left: 8,
            child: Consumer<GameState>(
              builder: (_, state, __) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    ...List.generate(
                      3,
                      (i) => Text(
                        i < state.lives ? '❤️' : '🖤',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '⭐ ${state.score}',
                      style: const TextStyle(
                          color: Colors.yellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Nivel ${state.currentLevel}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botón pausa arriba derecha
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.pause, color: Colors.white, size: 28),
              onPressed: () {
                _game.pauseEngine();
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF1a1a2e),
                    title: const Text('⏸ Pausa',
                        style: TextStyle(color: Colors.white)),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('Salir',
                            style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _game.resumeEngine();
                        },
                        child: const Text('Continuar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
