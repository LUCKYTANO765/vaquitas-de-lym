import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Mapa chico que muestra "donde esta mi vaquita" = ubicacion actual del dispositivo.
/// Se refresca cada 30 segundos.
class MiniMapWidget extends StatefulWidget {
  const MiniMapWidget({super.key});

  @override
  State<MiniMapWidget> createState() => _MiniMapWidgetState();
}

class _MiniMapWidgetState extends State<MiniMapWidget> {
  LatLng? _pos;
  String? _error;
  Timer? _timer;
  final _mapCtrl = MapController();

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _error = 'Sin permiso de ubicación');
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final ll = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _pos = ll;
          _error = null;
        });
        _mapCtrl.move(ll, 16);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo obtener ubicación');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Titulo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Mi vaquita está acá 🐄',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          // Mapa o estado
          Positioned.fill(
            top: 30,
            child: _pos == null
                ? Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: _error != null
                        ? Text(_error!,
                            style: const TextStyle(color: Colors.grey))
                        : const CircularProgressIndicator(),
                  )
                : FlutterMap(
                    mapController: _mapCtrl,
                    options: MapOptions(
                      initialCenter: _pos!,
                      initialZoom: 16,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.pinchZoom |
                            InteractiveFlag.drag |
                            InteractiveFlag.doubleTapZoom,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.lym.vaquitas_de_lym',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _pos!,
                            width: 48,
                            height: 48,
                            child: const Text(
                              '🐄',
                              style: TextStyle(fontSize: 34),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          // Boton refresh abajo derecha
          Positioned(
            bottom: 8,
            right: 8,
            child: FloatingActionButton.small(
              heroTag: 'mini_refresh',
              backgroundColor: Colors.white,
              onPressed: _refresh,
              child: const Icon(Icons.my_location, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
