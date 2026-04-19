import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'gps_service.dart';

class GalleryTab extends StatelessWidget {
  const GalleryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance
          .ref('devices/$deviceId/gallery')
          .orderByChild('date')
          .onValue,
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final raw = snap.data!.snapshot.value;
        if (raw == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'La galería aún no fue escaneada.\nAparece a las 2 AM con WiFi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final map = Map<String, dynamic>.from(raw as Map);
        final items = map.entries.map((e) {
          final v = Map<String, dynamic>.from(e.value as Map);
          return _GalleryItem(key: e.key, data: v);
        }).toList();
        // Más recientes primero
        items.sort((a, b) => (b.data['date'] as int? ?? 0)
            .compareTo(a.data['date'] as int? ?? 0));

        return GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _Thumb(item: items[i]),
        );
      },
    );
  }
}

class _GalleryItem {
  final String key;
  final Map<String, dynamic> data;
  const _GalleryItem({required this.key, required this.data});
}

class _Thumb extends StatelessWidget {
  final _GalleryItem item;
  const _Thumb({required this.item});

  Future<void> _requestDownload(BuildContext context) async {
    final downloaded = item.data['downloaded'] == true;
    final originalUrl = item.data['original'] as String?;

    if (downloaded && originalUrl != null) {
      // Ya está lista: abrir en pantalla completa
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _FullImage(url: originalUrl),
        ),
      );
      return;
    }

    // Marcar para descarga
    await FirebaseDatabase.instance
        .ref('devices/$deviceId/gallery/${item.key}')
        .update({'download': true});

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pedido enviado. Llegará cuando el celu esté en WiFi.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thumbUrl = item.data['thumb'] as String?;
    final downloaded = item.data['downloaded'] == true;
    final pending = item.data['download'] == true && !downloaded;
    final isVideo = item.data['type'] == 'video';

    return GestureDetector(
      onTap: () => _requestDownload(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumbUrl != null)
            Image.network(thumbUrl, fit: BoxFit.cover)
          else
            Container(color: Colors.grey.shade300),
          // Badge video
          if (isVideo)
            const Positioned(
              bottom: 4,
              left: 4,
              child: Icon(Icons.play_circle, color: Colors.white, size: 20),
            ),
          // Badge descarga pendiente
          if (pending)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ),
                ),
              ),
            ),
          // Badge descargada
          if (downloaded)
            const Positioned(
              top: 4,
              right: 4,
              child: Icon(Icons.check_circle, color: Colors.green, size: 20),
            ),
        ],
      ),
    );
  }
}

class _FullImage extends StatelessWidget {
  final String url;
  const _FullImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Guardar en mi galería',
            onPressed: () async {
              // Descargar a Storage local del padre
              final ref = FirebaseStorage.instance.refFromURL(url);
              final data = await ref.getData();
              if (data == null) return;
              // Guardar en Downloads del dispositivo padre
              // (requiere path_provider si queremos guardar en disco;
              //  por ahora solo muestra la imagen)
            },
          ),
        ],
      ),
      body: InteractiveViewer(
        child: Center(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
