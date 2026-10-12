import 'dart:async';

import 'package:flutter/material.dart';

import '../db.dart';
import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// "Abhi ki photo": purane phone se dono cameras ki taaza photo mangwata hai.
class SnapshotScreen extends StatefulWidget {
  const SnapshotScreen({super.key});

  @override
  State<SnapshotScreen> createState() => _SnapshotScreenState();
}

class _SnapshotScreenState extends State<SnapshotScreen> {
  final _stream = Db.snapshots();
  DateTime _requestedAt = DateTime.now();
  bool _timedOut = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _request();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _request() async {
    setState(() {
      _requestedAt = DateTime.now().subtract(const Duration(seconds: 5));
      _timedOut = false;
    });
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 45), () {
      if (mounted) setState(() => _timedOut = true);
    });
    try {
      await Db.requestSnapshot();
    } catch (_) {
      if (mounted) showSnack(context, tr('save_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('snapshot_now')),
        actions: [
          IconButton(onPressed: _request, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: StreamBuilder<List<Snapshot>>(
        stream: _stream,
        builder: (context, snap) {
          final list = snap.data ?? const <Snapshot>[];
          final fresh = list.where((s) => s.createdAt != null && s.createdAt!.isAfter(_requestedAt)).length;
          final waiting = fresh < list.length || list.isEmpty;
          return ListView(
            padding: const EdgeInsets.all(Sp.l),
            children: [
              if (waiting && !_timedOut)
                _banner(Icons.downloading_rounded, C.brand, tr('snapshot_waiting'), loading: true)
              else if (waiting && _timedOut)
                _banner(Icons.cloud_off_rounded, C.warn, tr('snapshot_timeout'))
              else
                _banner(Icons.check_circle_rounded, C.safe, tr('snapshot_ready')),
              const SizedBox(height: Sp.l),
              for (final s in list) ...[
                _card(s, s.createdAt != null && s.createdAt!.isAfter(_requestedAt)),
                const SizedBox(height: Sp.l),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _banner(IconData icon, Color color, String text, {bool loading = false}) {
    return GCard(
      borderColor: color.withValues(alpha: 0.4),
      child: Row(
        children: [
          if (loading)
            SizedBox(
              width: 36,
              height: 36,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
              ),
            )
          else
            IconBubble(icon, color: color, size: 36),
          const SizedBox(width: Sp.m),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _card(Snapshot s, bool fresh) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Sp.radius),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: s.image == null
                ? Container(color: C.surface2)
                : InteractiveViewer(
                    child: Image.memory(s.image!, fit: BoxFit.cover, gaplessPlayback: true)),
          ),
          Positioned(
            left: Sp.m,
            top: Sp.m,
            child: Pill(s.camera, color: Colors.white, icon: Icons.videocam_rounded),
          ),
          Positioned(
            right: Sp.m,
            bottom: Sp.m,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                fresh ? formatTime(s.createdAt) : '${tr('old_photo')} · ${timeAgo(s.createdAt)}',
                style: TextStyle(
                  color: fresh ? Colors.white : C.warn,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
