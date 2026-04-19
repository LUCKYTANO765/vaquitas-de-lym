import 'package:flutter/material.dart';
import 'location_repo.dart';

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = LocationRepo();
    return StreamBuilder<List<NotificationEntry>>(
      stream: repo.watchNotifications(limit: 500),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data!;
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Sin notificaciones todavía.\nActivá el modo familia en el celu del chico.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        // Agrupar por app
        final grouped = <String, List<NotificationEntry>>{};
        for (final n in items) {
          grouped.putIfAbsent(n.app, () => []).add(n);
        }
        // Ordenar apps por notificacion mas reciente
        final apps = grouped.keys.toList()
          ..sort((a, b) => grouped[b]!.first.ts.compareTo(grouped[a]!.first.ts));

        return ListView.builder(
          itemCount: apps.length,
          itemBuilder: (_, i) => _AppSection(
            app: apps[i],
            items: grouped[apps[i]]!,
          ),
        );
      },
    );
  }
}

class _AppSection extends StatefulWidget {
  final String app;
  final List<NotificationEntry> items;
  const _AppSection({required this.app, required this.items});

  @override
  State<_AppSection> createState() => _AppSectionState();
}

class _AppSectionState extends State<_AppSection> {
  bool _expanded = true;

  Color _appColor(String app) {
    switch (app) {
      case 'WhatsApp':
      case 'WhatsApp Business':
        return const Color(0xFF25D366);
      case 'Telegram':
      case 'Telegram Web':
        return const Color(0xFF0088CC);
      case 'Instagram':
        return const Color(0xFFE1306C);
      case 'TikTok':
      case 'TikTok Lite':
        return Colors.black;
      case 'Messenger':
      case 'Facebook':
        return const Color(0xFF1877F2);
      case 'Snapchat':
        return const Color(0xFFFFFC00);
      case 'Discord':
        return const Color(0xFF5865F2);
      case 'Gmail':
        return const Color(0xFFEA4335);
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final col = _appColor(widget.app);
    final alerts = widget.items.where((n) => n.alert).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabecera de la app
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: col.withValues(alpha: 0.12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: col,
                  radius: 16,
                  child: Text(
                    widget.app.isNotEmpty ? widget.app[0] : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.app,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                if (alerts > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$alerts ⚠️',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  '${widget.items.length}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...widget.items.map((n) => _NotifTile(entry: n, appColor: col)),
        const Divider(height: 1, thickness: 2),
      ],
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationEntry entry;
  final Color appColor;
  const _NotifTile({required this.entry, required this.appColor});

  String _fmtTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: entry.alert ? Colors.red.shade50 : null,
      child: ListTile(
        dense: true,
        leading: entry.alert
            ? const Icon(Icons.warning_amber, color: Colors.red)
            : const Icon(Icons.message, color: Colors.grey, size: 20),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.from.isEmpty ? entry.app : entry.from,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: entry.alert ? Colors.red.shade900 : null,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              _fmtTime(entry.when),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            if (entry.keywords.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '⚠️ ${entry.keywords.join(', ')}',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        isThreeLine: entry.keywords.isNotEmpty,
      ),
    );
  }
}
