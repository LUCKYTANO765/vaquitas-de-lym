import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../game_state.dart';
import 'game_screen.dart';
import '../../tracker/parent_panel_screen.dart';
import '../../tracker/mini_map_widget.dart';

// Codigo del padre para entrar al panel parental.
// Cambiar aca por uno propio. Solo el padre lo sabe.
const _parentCode = '1234';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _secretTaps = 0;
  DateTime? _firstTapAt;

  @override
  void initState() {
    super.initState();
    context.read<GameState>().loadProgress();
  }

  void _onSecretTap() {
    final now = DateTime.now();
    if (_firstTapAt == null ||
        now.difference(_firstTapAt!) > const Duration(seconds: 3)) {
      _firstTapAt = now;
      _secretTaps = 1;
      return;
    }
    _secretTaps++;
    if (_secretTaps >= 5) {
      _secretTaps = 0;
      _firstTapAt = null;
      _askParentCode();
    }
  }

  Future<void> _askParentCode() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Acceso restringido'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Código',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, controller.text == _parentCode),
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ParentPanelScreen()),
      );
    } else if (ok == false && controller.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código incorrecto')),
      );
    }
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar de la vaquita del jugador
                  Consumer<GameState>(
                    builder: (_, state, __) {
                      final path = state.vaquitaPhotoPath;
                      if (path == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 8,
                                  offset: Offset(0, 4)),
                            ],
                            image: DecorationImage(
                              image: FileImage(File(path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8));
                    },
                  ),

                  // Título (5 taps rápidos = abrir panel parental)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onSecretTap,
                    child: const Text(
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
                    ),
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

                  const SizedBox(height: 16),

                  // Mapa "Mi vaquita está acá"
                  const MiniMapWidget()
                      .animate(delay: 900.ms)
                      .fadeIn()
                      .slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
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
