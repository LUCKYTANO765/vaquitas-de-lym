import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'main_menu_screen.dart';

/// 🎬 ENDING: Lym pregunta "¿Quieres mi vaquita?"
/// Botón SÍ activo — Botón NO deshabilitado para siempre
class EndingScreen extends StatefulWidget {
  const EndingScreen({super.key});

  @override
  State<EndingScreen> createState() => _EndingScreenState();
}

class _EndingScreenState extends State<EndingScreen>
    with TickerProviderStateMixin {
  bool _showDialog = false;
  bool _heartsBurst = false;
  late AnimationController _noShakeController;
  late Animation<double> _noShakeAnim;

  @override
  void initState() {
    super.initState();

    // Animación de shake para el botón NO
    _noShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _noShakeAnim = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _noShakeController, curve: Curves.elasticIn),
    );

    // Mostrar el diálogo de Lym después de 2s
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showDialog = true);
    });
  }

  @override
  void dispose() {
    _noShakeController.dispose();
    super.dispose();
  }

  void _onSiPressed() {
    setState(() => _heartsBurst = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainMenuScreen()),
          (_) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFB6C1), Color(0xFFFF69B4)], // rosa romántico
          ),
        ),
        child: Stack(
          children: [
            // Estrellas de fondo
            ..._buildStars(),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Castillo / escena de rescate
                  if (!_showDialog) _buildRescueScene(),

                  // Diálogo de Lym
                  if (_showDialog && !_heartsBurst) _buildLymDialog(),

                  // Explosión de corazones al presionar SÍ
                  if (_heartsBurst) _buildHeartsExplosion(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRescueScene() {
    return Column(
      children: [
        const Text('🏰', style: TextStyle(fontSize: 80))
            .animate()
            .fadeIn(duration: 800.ms),
        const SizedBox(height: 16),
        const Text(
          '¡Rescataste a la Princesa Lym!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black38, offset: Offset(2, 2))],
          ),
          textAlign: TextAlign.center,
        ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3),
        const SizedBox(height: 8),
        const Text('👸 🐄',
                style: TextStyle(fontSize: 60))
            .animate(delay: 800.ms)
            .fadeIn()
            .scale(begin: const Offset(0.5, 0.5)),
      ],
    );
  }

  Widget _buildLymDialog() {
    return Column(
      children: [
        // Personaje Lym
        const Text('👸', style: TextStyle(fontSize: 80))
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.3, 0.3)),

        const SizedBox(height: 20),

        // Burbuja de diálogo
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: const Column(
            children: [
              Text(
                'Lym dice:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '¿Quieres mi vaquita? 🐄💕',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE91E63),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
            .animate(delay: 300.ms)
            .fadeIn()
            .slideY(begin: 0.2),

        const SizedBox(height: 32),

        // Botones SÍ y NO
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ Botón SÍ — funciona, grande, brillante
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 48, vertical: 20),
                textStyle: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 8,
              ),
              onPressed: _onSiPressed,
              child: const Text('❤️  SÍ'),
            )
                .animate(delay: 600.ms)
                .fadeIn()
                .scale(begin: const Offset(0.5, 0.5)),

            const SizedBox(width: 24),

            // ❌ Botón NO — SIEMPRE DISABLED, gris, pequeño, con tooltip burlón
            Tooltip(
              message: 'Esta opción no existe 😏',
              child: AnimatedBuilder(
                animation: _noShakeAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(_noShakeAnim.value, 0),
                  child: child,
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.grey.shade500,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    textStyle: const TextStyle(
                        fontSize: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: null, // 🔒 SIEMPRE NULL — nunca activo
                  child: const Text('no...'),
                ),
              ),
            )
                .animate(delay: 600.ms)
                .fadeIn(),
          ],
        ),
      ],
    );
  }

  Widget _buildHeartsExplosion() {
    return Column(
      children: [
        Image.asset(
          'assets/images/princesa vaca.png',
          height: 220,
          fit: BoxFit.contain,
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.3, 0.3))
            .then()
            .shake(duration: 600.ms),
        const SizedBox(height: 24),
        const Text(
          '¡Las vaquitas de Lym son tuyas! 🐄💕',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black38, offset: Offset(2, 2))],
          ),
          textAlign: TextAlign.center,
        )
            .animate(delay: 500.ms)
            .fadeIn(),
      ],
    );
  }

  List<Widget> _buildStars() {
    return List.generate(
      20,
      (i) => Positioned(
        top: (i * 47.3) % MediaQuery.of(context).size.height,
        left: (i * 83.7) % MediaQuery.of(context).size.width,
        child: Text(
          i % 3 == 0 ? '⭐' : (i % 3 == 1 ? '🌸' : '💫'),
          style: TextStyle(fontSize: 12 + (i % 4) * 4.0),
        )
            .animate(delay: Duration(milliseconds: i * 100))
            .fadeIn(duration: 800.ms),
      ),
    );
  }
}
