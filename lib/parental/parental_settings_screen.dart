import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';

class ParentalSettingsScreen extends StatelessWidget {
  const ParentalSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes de Control Parental'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestión de Progreso',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.red),
              title: const Text('Reiniciar Todo el Progreso'),
              subtitle: const Text('Borra niveles y puntuaciones guardadas'),
              onTap: () => _showResetDialog(context),
            ),
            const SizedBox(height: 20),
            const Text(
              'Estadísticas del Jugador',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Consumer<GameState>(
              builder: (_, state, __) => Column(
                children: [
                  _StatTile(
                      label: 'Nivel Máximo Alcanzado',
                      value: '${state.currentLevel}'),
                  _StatTile(label: 'Puntuación Total', value: '${state.score}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Estás seguro?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<GameState>().resetGame();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Progreso reiniciado con éxito')),
              );
            },
            child: const Text('REINICIAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }
}
