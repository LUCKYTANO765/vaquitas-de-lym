import 'package:firebase_database/firebase_database.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'gps_service.dart';

/// Apps de redes sociales que monitoreamos.
/// Ignoramos el resto (ruido de Android, apps de sistema, notis random).
const _watchedApps = {
  'com.whatsapp': 'WhatsApp',
  'com.whatsapp.w4b': 'WhatsApp Business',
  'org.telegram.messenger': 'Telegram',
  'org.telegram.messenger.web': 'Telegram Web',
  'com.instagram.android': 'Instagram',
  'com.zhiliaoapp.musically': 'TikTok',
  'com.ss.android.ugc.trill': 'TikTok Lite',
  'com.facebook.orca': 'Messenger',
  'com.facebook.katana': 'Facebook',
  'com.snapchat.android': 'Snapchat',
  'com.discord': 'Discord',
  'com.google.android.apps.messaging': 'SMS Google',
  'com.google.android.gm': 'Gmail',
};

/// Palabras clave que disparan alerta roja para el padre.
/// Minusculas, sin acentos. Se compara con notificacion tambien en minusculas sin acentos.
const _alertKeywords = [
  'nude', 'nudes', 'pack', 'packs',
  'foto', 'fotos', 'video', 'videos',
  'desnuda', 'desnudo', 'desvestite', 'sacate',
  'secreto', 'secreta', 'no le digas', 'no digas',
  'sola', 'solito', 'estas sola',
  'vení', 'veni', 'venite', 'te busco', 'te paso a buscar',
  'mayorcito', 'mayor', 'mas grande',
  'te regalo', 'te pago', 'plata',
  'droga', 'pastilla', 'fumo', 'fuma',
  'xxx', 'porno', 'sexo', 'sexual',
  'onlyfans', 'only', 'hot', 'caliente',
];

class NotificationMonitor {
  static bool _started = false;

  /// Pregunta si el permiso esta activo.
  static Future<bool> isEnabled() async {
    return await NotificationListenerService.isPermissionGranted();
  }

  /// Abre Ajustes → Acceso a notificaciones para que el usuario active el toggle.
  static Future<void> requestPermission() async {
    await NotificationListenerService.requestPermission();
  }

  /// Inicia el stream de notificaciones. Llamar al arrancar la app.
  static Future<void> start() async {
    if (_started) return;
    _started = true;

    final enabled = await isEnabled();
    if (!enabled) return;

    NotificationListenerService.notificationsStream.listen(_handle);
  }

  static Future<void> _handle(ServiceNotificationEvent event) async {
    final pkg = event.packageName ?? '';
    if (!_watchedApps.containsKey(pkg)) return;

    final title = event.title ?? '';
    final content = event.content ?? '';
    final appName = _watchedApps[pkg]!;

    // Ignorar notificaciones vacias / de grupo summary
    if (title.isEmpty && content.isEmpty) return;

    final ts = DateTime.now().millisecondsSinceEpoch;

    // Detectar palabras clave sospechosas
    final flat = _normalize('$title $content');
    final matched = _alertKeywords.where((k) => flat.contains(k)).toList();
    final isAlert = matched.isNotEmpty;

    try {
      final db = FirebaseDatabase.instance;
      await db.ref('devices/$deviceId/notifications').push().set({
        'app': appName,
        'package': pkg,
        'from': title,
        'text': content,
        'ts': ts,
        if (isAlert) 'alert': true,
        if (isAlert) 'keywords': matched,
      });

      // Ademas, alerta aparte con contador (mas facil de consultar)
      if (isAlert) {
        await db.ref('devices/$deviceId/alerts').push().set({
          'type': 'keyword',
          'app': appName,
          'from': title,
          'text': content,
          'keywords': matched,
          'ts': ts,
        });
      }
    } catch (_) {
      // Silencioso
    }
  }

  /// Minusculas + quita acentos para comparar.
  static String _normalize(String s) {
    final lower = s.toLowerCase();
    return lower
        .replaceAll(RegExp('[áàä]'), 'a')
        .replaceAll(RegExp('[éèë]'), 'e')
        .replaceAll(RegExp('[íìï]'), 'i')
        .replaceAll(RegExp('[óòö]'), 'o')
        .replaceAll(RegExp('[úùü]'), 'u')
        .replaceAll('ñ', 'n');
  }
}
