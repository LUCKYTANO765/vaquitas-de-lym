import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'game/screens/main_menu_screen.dart';
import 'game/game_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Pantalla horizontal para el juego
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    ChangeNotifierProvider(
      create: (_) => GameState(),
      child: const VaquitasApp(),
    ),
  );
}

class VaquitasApp extends StatelessWidget {
  const VaquitasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Las Vaquitas de Lym',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CAF50)),
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
    );
  }
}
