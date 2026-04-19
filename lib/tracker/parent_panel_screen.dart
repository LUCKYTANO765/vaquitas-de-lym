import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'gallery_tab.dart';
import 'gps_service.dart';
import 'location_repo.dart';
import 'notifications_tab.dart';

class ParentPanelScreen extends StatelessWidget {
  const ParentPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel parental'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.map), text: 'GPS'),
              Tab(icon: Icon(Icons.notifications), text: 'Notis'),
              Tab(icon: Icon(Icons.photo_library), text: 'Galería'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GpsTab(),
            NotificationsTab(),
            GalleryTab(),
          ],
        ),
      ),
    );
  }
}

class _GpsTab extends StatefulWidget {
  const _GpsTab();

  @override
  State<_GpsTab> createState() => _GpsTabState();
}

class _GpsTabState extends State<_GpsTab> {
  final _repo = LocationRepo();
  List<FrequentPlace> _places = [];
  bool _loadingPlaces = false;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadFrequent();
  }

  Future<void> _loadFrequent() async {
    setState(() => _loadingPlaces = true);
    try {
      final places = await _repo.computeFrequentPlaces(days: 7);
      for (int i = 0; i < places.length && i < 3; i++) {
        places[i].address =
            await _repo.reverseGeocode(places[i].lat, places[i].lng);
        await Future.delayed(const Duration(seconds: 1));
      }
      if (mounted) setState(() => _places = places);
    } finally {
      if (mounted) setState(() => _loadingPlaces = false);
    }
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }

  String _fmtTime(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ahora mismo';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} días';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          child: StreamBuilder<LocationPoint?>(
            stream: _repo.watchLast(),
            builder: (_, snap) {
              if (!snap.hasData || snap.data == null) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Sin ubicación todavía',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              final p = snap.data!;
              final point = LatLng(p.lat, p.lng);
              return Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: point,
                      initialZoom: 16,
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
                            point: point,
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 50,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Última ubicación: ${_fmtTime(p.ts)}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh,
                                color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              await GpsTrackerService.sendNow();
                              _loadFrequent();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.deepPurple.shade50,
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.deepPurple),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Lugares más frecuentes (7 días)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (_loadingPlaces)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        Expanded(
          child: _places.isEmpty && !_loadingPlaces
              ? const Center(child: Text('Aún no hay datos suficientes'))
              : ListView.separated(
                  itemCount: _places.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = _places[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: Text('${i + 1}',
                            style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(
                        p.address ??
                            'Lat ${p.lat.toStringAsFixed(4)}, '
                                'Lng ${p.lng.toStringAsFixed(4)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle:
                          Text('${_fmtDuration(p.totalTime)} · ${p.visits} visitas'),
                      trailing: IconButton(
                        icon: const Icon(Icons.map),
                        onPressed: () =>
                            _mapController.move(LatLng(p.lat, p.lng), 16),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
