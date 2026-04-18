import 'dart:convert';
import 'dart:math' as math;
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'gps_service.dart';

class LocationPoint {
  final double lat;
  final double lng;
  final int ts;
  final double? accuracy;

  LocationPoint({
    required this.lat,
    required this.lng,
    required this.ts,
    this.accuracy,
  });

  DateTime get when => DateTime.fromMillisecondsSinceEpoch(ts);

  static LocationPoint fromMap(Map data) {
    return LocationPoint(
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      ts: (data['ts'] as num).toInt(),
      accuracy: data['accuracy'] != null
          ? (data['accuracy'] as num).toDouble()
          : null,
    );
  }
}

class FrequentPlace {
  final double lat;
  final double lng;
  final int visits;
  final Duration totalTime;
  String? address; // se llena con geocoding inverso

  FrequentPlace({
    required this.lat,
    required this.lng,
    required this.visits,
    required this.totalTime,
    this.address,
  });
}

class LocationRepo {
  final _db = FirebaseDatabase.instance;

  /// Stream de la ultima ubicacion (en vivo).
  Stream<LocationPoint?> watchLast() {
    return _db.ref('devices/$deviceId/last').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw == null) return null;
      return LocationPoint.fromMap(Map<String, dynamic>.from(raw as Map));
    });
  }

  /// Trae el historial completo (ordenado por ts asc).
  Future<List<LocationPoint>> fetchHistory({int? sinceTs}) async {
    final snap = await _db.ref('devices/$deviceId/history').get();
    final raw = snap.value;
    if (raw == null) return [];
    final map = Map<String, dynamic>.from(raw as Map);
    final list = map.values
        .map((v) => LocationPoint.fromMap(Map<String, dynamic>.from(v as Map)))
        .where((p) => sinceTs == null || p.ts >= sinceTs)
        .toList();
    list.sort((a, b) => a.ts.compareTo(b.ts));
    return list;
  }

  /// Calcula los lugares mas frecuentes agrupando puntos cercanos (<radiusM metros).
  /// Devuelve top N ordenado por tiempo total descendente.
  Future<List<FrequentPlace>> computeFrequentPlaces({
    int days = 7,
    double radiusM = 100,
    int topN = 5,
  }) async {
    final since =
        DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    final history = await fetchHistory(sinceTs: since);
    if (history.isEmpty) return [];

    // Clustering simple: cada punto va al primer cluster cuyo centroide esta a <radiusM
    final clusters = <_Cluster>[];
    for (final p in history) {
      _Cluster? match;
      for (final c in clusters) {
        if (_haversine(c.lat, c.lng, p.lat, p.lng) <= radiusM) {
          match = c;
          break;
        }
      }
      if (match == null) {
        clusters.add(_Cluster(p.lat, p.lng)..points.add(p));
      } else {
        match.points.add(p);
        // recalcular centroide
        match.lat =
            match.points.map((e) => e.lat).reduce((a, b) => a + b) /
                match.points.length;
        match.lng =
            match.points.map((e) => e.lng).reduce((a, b) => a + b) /
                match.points.length;
      }
    }

    // Calcular tiempo total: cada punto vale 15 min (intervalo de tracking)
    const tickMs = 15 * 60 * 1000;
    final places = clusters.map((c) {
      return FrequentPlace(
        lat: c.lat,
        lng: c.lng,
        visits: c.points.length,
        totalTime: Duration(milliseconds: c.points.length * tickMs),
      );
    }).toList();

    places.sort((a, b) => b.totalTime.compareTo(a.totalTime));
    return places.take(topN).toList();
  }

  /// Geocoding inverso usando Nominatim (OpenStreetMap, gratis, sin API key).
  /// IMPORTANTE: tiene limite de 1 req/seg, no abusar.
  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&accept-language=es',
      );
      final res = await http.get(
        uri,
        headers: {'User-Agent': 'VaquitasDeLym/1.0 (parental)'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Distancia haversine en metros entre dos coords.
  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180);
}

class _Cluster {
  double lat;
  double lng;
  final points = <LocationPoint>[];
  _Cluster(this.lat, this.lng);
}
