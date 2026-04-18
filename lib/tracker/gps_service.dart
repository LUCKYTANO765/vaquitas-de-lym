import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';
import '../firebase_options.dart';

const taskName = 'vaquita_gps_tick';

/// ID del dispositivo (rama en Firebase). Por ahora fijo — un solo chico.
const deviceId = 'vaquita';

/// Llamado por WorkManager en background.
/// Tiene que estar a nivel top-level (no dentro de clase) por requerimiento del plugin.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Inicializar Firebase en este isolate de background
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.android,
      );

      // Chequear permiso ubicacion
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return true; // sin permiso, salimos sin error
      }

      // Tomar ubicacion (timeout 30s)
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );

      // Guardar en Firebase
      final db = FirebaseDatabase.instance;
      final ts = DateTime.now().millisecondsSinceEpoch;

      // Ultima ubicacion (sobrescribe)
      await db.ref('devices/$deviceId/last').set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'accuracy': pos.accuracy,
        'ts': ts,
      });

      // Historial (push genera key unico)
      await db.ref('devices/$deviceId/history').push().set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'ts': ts,
      });
    } catch (_) {
      // Silencioso para no llamar la atencion en logs del chico
    }
    return true;
  });
}

class GpsTrackerService {
  /// Inicializa WorkManager y agenda la tarea periodica.
  /// Llamar UNA VEZ al arrancar la app.
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Cancelar viejas (por si el codigo cambia)
    await Workmanager().cancelByUniqueName(taskName);

    // Agendar tarea periodica cada 15 min (minimo permitido por Android)
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// Pide permisos de ubicacion. Llamar al arrancar la app la primera vez.
  static Future<bool> requestPermissions() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  /// Forzar un envio inmediato (sin esperar 15 min). Util para testing.
  static Future<void> sendNow() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
      final db = FirebaseDatabase.instance;
      final ts = DateTime.now().millisecondsSinceEpoch;
      await db.ref('devices/$deviceId/last').set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'accuracy': pos.accuracy,
        'ts': ts,
      });
      await db.ref('devices/$deviceId/history').push().set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'ts': ts,
      });
    } catch (_) {}
  }
}
