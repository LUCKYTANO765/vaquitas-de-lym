import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../game_state.dart';
import 'game_screen.dart';
import '../../parental/parental_gate.dart';
import '../../parental/parental_settings_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GameState>().loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF87CEEB), Color(0xFF4CAF50)], // cielo y pasto
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Título
                  const Text(
                    '🐄 Las Vaquitas de Lym 🐄',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(3, 3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.3, end: 0),

                  const SizedBox(height: 16),

                  // Subtítulo
                  const Text(
                    '¡Rescata a la princesa Lym!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ).animate(delay: 300.ms).fadeIn(),

                  const SizedBox(height: 40),

                  // Botón JUGAR
                  _MenuButton(
                    label: '▶  JUGAR',
                    color: const Color(0xFF2196F3),
                    onPressed: () {
                      context.read<GameState>().resetGame();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GameScreen()),
                      );
                    },
                  ).animate(delay: 500.ms).fadeIn().slideX(begin: -0.2),

                  const SizedBox(height: 12),

                  // Botón CONTINUAR
                  Consumer<GameState>(
                    builder: (_, state, __) => _MenuButton(
                      label: '⏸  CONTINUAR',
                      color: const Color(0xFF9C27B0),
                      onPressed: state.currentLevel > 1
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const GameScreen()),
                              )
                          : null,
                    ),
                  ).animate(delay: 600.ms).fadeIn().slideX(begin: 0.2),

                  const SizedBox(height: 24),

                  // Vidas e info
                  Consumer<GameState>(
                    builder: (_, state, __) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(
                            3,
                            (i) => Text(
                                  i < state.lives ? '❤️' : '🖤',
                                  style: const TextStyle(fontSize: 24),
                                )),
                        const SizedBox(width: 16),
                        Text(
                          'Nivel ${state.currentLevel} / ${state.totalLevels}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ).animate(delay: 700.ms).fadeIn(),
                ],
              ),
            ),
          ),
          
          // Botón de Ajustes Parentales (Esquina)
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.family_restroom, color: Colors.white, size: 32),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ParentalGate(
                      destination: ParentalSettingsScreen(),
                    ),
                  ),
                );
              },
            ).animate(delay: 1000.ms).fadeIn(),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _MenuButton({
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? color : Colors.grey,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 6,
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
