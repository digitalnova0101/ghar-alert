import 'package:flutter/material.dart';

import '../db.dart';
import '../l10n.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class CamerasScreen extends StatefulWidget {
  const CamerasScreen({super.key});

  @override
  State<CamerasScreen> createState() => _CamerasScreenState();
}

class _CamerasScreenState extends State<CamerasScreen> {
  final _status = Db.status();
  final _config = Db.config();

  Future<void> _set(String name, CameraConfig c) async {
    try {
      await Db.setCamera(name, c);
    } catch (_) {
      if (mounted) showSnack(context, tr('save_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('cameras'))),
      body: StreamBuilder<SystemStatus>(
        stream: _status,
        builder: (context, sSnap) => StreamBuilder<HomeConfig>(
          stream: _config,
          builder: (context, cSnap) {
            final status = sSnap.data ?? SystemStatus();
            final cfg = cSnap.data ?? HomeConfig();
            final names = {...status.cameras.keys, ...cfg.cameras.keys}.toList()..sort();
            if (names.isEmpty) {
              return EmptyState(
                icon: Icons.videocam_off_rounded,
                title: tr('no_cameras_yet'),
                subtitle: tr('no_cameras_sub'),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(Sp.l),
              children: [
                Text(tr('cameras_explain'), style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: Sp.l),
                for (final name in names) ...[
                  _card(name, cfg.cameras[name] ?? CameraConfig(), status.cameras[name] == true && status.online),
                  const SizedBox(height: Sp.m),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _card(String name, CameraConfig c, bool live) {
    return GCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBubble(Icons.videocam_rounded, color: c.enabled ? C.info : C.faint),
              const SizedBox(width: Sp.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                      !c.enabled ? tr('paused') : (live ? tr('cam_live') : tr('cam_no_video')),
                      style: TextStyle(
                        color: !c.enabled ? C.faint : (live ? C.safe : C.warn),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: c.enabled,
                onChanged: (v) => _set(name, CameraConfig(enabled: v, sensitivity: c.sensitivity)),
              ),
            ],
          ),
          if (c.enabled) ...[
            const SizedBox(height: Sp.l),
            Text(tr('sensitivity'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: Sp.s),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 'low', label: Text(tr('sens_low'))),
                  ButtonSegment(value: 'medium', label: Text(tr('sens_medium'))),
                  ButtonSegment(value: 'high', label: Text(tr('sens_high'))),
                ],
                selected: {c.sensitivity},
                onSelectionChanged: (s) =>
                    _set(name, CameraConfig(enabled: c.enabled, sensitivity: s.first)),
              ),
            ),
            const SizedBox(height: Sp.s),
            Text(tr('sens_${c.sensitivity}_hint'), style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
