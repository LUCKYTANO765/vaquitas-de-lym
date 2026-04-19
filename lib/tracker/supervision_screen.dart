import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_monitor.dart';

/// Pantalla de transparencia: el chico ve que esta supervisado.
/// Pide activar acceso a notificaciones (requisito de Android).
/// Solo aparece la primera vez y hasta que acepte (o salte, queda opcional).
class SupervisionScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SupervisionScreen({super.key, required this.onDone});

  @override
  State<SupervisionScreen> createState() => _SupervisionScreenState();
}

class _SupervisionScreenState extends State<SupervisionScreen>
    with WidgetsBindingObserver {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Cuando vuelve de Ajustes, revisa si activo el toggle.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _recheck();
  }

  Future<void> _recheck() async {
    if (_checking) return;
    setState(() => _checking = true);
    final ok = await NotificationMonitor.isEnabled();
    if (ok) {
      await _markSeenAndContinue();
    }
    if (mounted) setState(() => _checking = false);
  }

  Future<void> _markSeenAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('supervision_seen', true);
    if (mounted) widget.onDone();
  }

  Future<void> _activar() async {
    await NotificationMonitor.requestPermission();
    // Al volver de ajustes, didChangeAppLifecycleState detecta y sigue.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CAF50),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield, size: 80, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                '👨‍👧 Modo familia',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Este juego lo supervisa tu papá o mamá para cuidarte si alguien te molesta por redes sociales.\n\n'
                'Van a ver las notificaciones de WhatsApp, Instagram, TikTok y similares, y pueden revisar las fotos de tu galería.\n\n'
                'Es para protegerte, no para espiarte.',
                style: TextStyle(
                    fontSize: 16, color: Colors.white, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _checking ? null : _activar,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Activar modo familia'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _markSeenAndContinue,
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                child: const Text('Más tarde'),
              ),
              const SizedBox(height: 24),
              if (_checking)
                const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
