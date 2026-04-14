import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LevelTransitionScreen extends StatefulWidget {
  final int level;
  final int score;
  final int stars; // 1-3 estrellas según tiempo/monedas
  final VoidCallback onContinue;

  const LevelTransitionScreen({
    super.key,
    required this.level,
    required this.score,
    required this.stars,
    required this.onContinue,
  });

  @override
  State<LevelTransitionScreen> createState() => _LevelTransitionScreenState();
}

class _LevelTransitionScreenState extends State<LevelTransitionScreen> {
  static const _levelNames = {
    1: 'Mundo 1',
    2: 'Mundo 2',
    3: 'Mundo 3',
    4: 'Castillo Final',
  };

  static const _levelSubtitles = {
    1: 'Prados de las Vaquitas 🌿',
    2: 'Desierto Caliente 🌵',
    3: 'Cavernas Oscuras 🦇',
    4: '¡Rescata a Lym! 👸',
  };

  static const _levelColors = {
    1: [Color(0xFF4CAF50), Color(0xFF1B5E20)],
    2: [Color(0xFFFF8F00), Color(0xFFE65100)],
    3: [Color(0xFF1A237E), Color(0xFF000000)],
    4: [Color(0xFFB71C1C), Color(0xFF4A0000)],
  };

  bool _showContinue = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showContinue = true);
    });
    // Auto-continuar después de 4s
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) widget.onContinue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = _levelColors[widget.level] ?? _levelColors[1]!;
    final nextLevel = widget.level + 1;
    final nextName = _levelNames[nextLevel];
    final nextSub = _levelSubtitles[nextLevel];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Stack(
          children: [
            // Partículas de fondo
            ..._buildParticles(),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // "¡Nivel completado!"
                  const Text(
                    '¡NIVEL COMPLETADO!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(color: Colors.black45, offset: Offset(3, 3), blurRadius: 6),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.5, 0.5))
                      .then()
                      .shake(duration: 300.ms, hz: 4),

                  const SizedBox(height: 24),

                  // Estrellas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final filled = i < widget.stars;
                      return Text(
                        filled ? '⭐' : '☆',
                        style: TextStyle(
                          fontSize: 48,
                          color: filled ? Colors.yellow : Colors.white30,
                        ),
                      )
                          .animate(delay: Duration(milliseconds: 400 + i * 200))
                          .fadeIn()
                          .scale(begin: const Offset(0.2, 0.2))
                          .then()
                          .shimmer(duration: 600.ms, color: Colors.yellow);
                    }),
                  ),

                  const SizedBox(height: 20),

                  // Score
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '⭐ ${widget.score} puntos',
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.yellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.3),

                  const SizedBox(height: 40),

                  // Próximo nivel
                  if (nextName != null) ...[
                    const Text(
                      'A CONTINUACIÓN:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white60,
                        letterSpacing: 3,
                      ),
                    ).animate(delay: 1000.ms).fadeIn(),
                    const SizedBox(height: 8),
                    Text(
                      nextName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate(delay: 1100.ms).fadeIn().slideX(begin: 0.2),
                    Text(
                      nextSub ?? '',
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                    ).animate(delay: 1200.ms).fadeIn(),
                  ] else ...[
                    const Text(
                      '¡ÚLTIMA FASE!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.orangeAccent,
                      ),
                    ).animate(delay: 1000.ms).fadeIn().shimmer(color: Colors.orange),
                    const Text(
                      '¡Lym te espera! 👸🐄',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ).animate(delay: 1200.ms).fadeIn(),
                  ],

                  const SizedBox(height: 40),

                  // Botón continuar
                  if (_showContinue)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: colors[0],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        elevation: 8,
                      ),
                      onPressed: widget.onContinue,
                      child: const Text('▶  CONTINUAR'),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(begin: const Offset(0.8, 0.8)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildParticles() {
    final emojis = ['⭐', '🌸', '💫', '✨', '🎉'];
    return List.generate(15, (i) {
      return Positioned(
        top: (i * 71.3) % (MediaQuery.of(context).size.height),
        left: (i * 113.7) % (MediaQuery.of(context).size.width),
        child: Text(
          emojis[i % emojis.length],
          style: TextStyle(fontSize: 14.0 + (i % 4) * 6),
        )
            .animate(delay: Duration(milliseconds: i * 80))
            .fadeIn(duration: 600.ms)
            .moveY(begin: 20, end: -20, duration: 2000.ms)
            .then()
            .moveY(begin: -20, end: 20, duration: 2000.ms),
      );
    });
  }
}
