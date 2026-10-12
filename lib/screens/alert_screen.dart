import 'package:flutter/material.dart';

import '../alarm_service.dart';
import '../db.dart';
import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../native.dart';
import '../theme.dart';
import '../widgets/category_ui.dart';
import '../widgets/common.dart';
import '../widgets/emergency_sheet.dart';
import '../widgets/swipe_confirm.dart';
import 'shell.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key, required this.alertId, this.autoAck = false});
  final String alertId;
  final bool autoAck;

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> with SingleTickerProviderStateMixin {
  late final Stream<AlertItem?> _stream = Db.alert(widget.alertId);
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat(reverse: true);
  bool _ackSeen = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoAck) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _acknowledge());
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _acknowledge() async {
    await cancelAlarm();
    try {
      await Db.acknowledge(widget.alertId);
    } catch (_) {
      if (mounted) showSnack(context, tr('save_failed'));
    }
  }

  void _close() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: StreamBuilder<AlertItem?>(
          stream: _stream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final a = snap.data;
            if (a == null) {
              return _Missing(onClose: _close);
            }
            if (a.acked && !_ackSeen) {
              _ackSeen = true;
              cancelAlarm();
            }
            return _content(a);
          },
        ),
      ),
    );
  }

  Widget _content(AlertItem a) {
    final catColor = categoryColor(a.category);
    final size = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        // Photo
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: size.height * 0.58,
          child: Hero(
            tag: 'alert-img-${a.id}',
            child: a.image != null
                ? InteractiveViewer(
                    child: Image.memory(a.image!, fit: BoxFit.cover, width: double.infinity),
                  )
                : Container(color: C.surface2),
          ),
        ),
        // neeche ka gradient
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.22, 0.45, 0.62],
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                    Colors.transparent,
                    C.bg,
                  ],
                ),
              ),
            ),
          ),
        ),
        // laal pulse border jab tak kisi ne nahi dekha
        if (!a.acked)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, _) => DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: C.danger.withValues(alpha: 0.25 + 0.55 * _pulse.value),
                      width: 6,
                    ),
                  ),
                ),
              ),
            ),
          ),
        // top bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.s, vertical: Sp.xs),
            child: Row(
              children: [
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                  onPressed: _close,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
                const Spacer(),
                Pill(categoryLabel(a.category), color: catColor, icon: categoryIcon(a.category)),
                const SizedBox(width: Sp.s),
              ],
            ),
          ),
        ),
        // neeche ka panel
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Sp.l, 0, Sp.l, Sp.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    if (!a.acked) const PulseDot(color: C.danger, size: 8),
                    Text(
                      '${a.camera} · ${formatTime(a.createdAt)}',
                      style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700),
                    ),
                  ]),
                  const SizedBox(height: Sp.s),
                  Text(a.reason, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: Sp.xl),
                  if (a.acked)
                    _AckBanner(a: a)
                  else
                    SwipeConfirm(label: tr('swipe_ack'), onConfirm: _acknowledge),
                  const SizedBox(height: Sp.m),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.videocam_rounded,
                          label: tr('live'),
                          onTap: () async {
                            await cancelAlarm();
                            final ok = await Native.openSeeEasy();
                            if (!ok && mounted) showSnack(context, tr('seeeasy_missing'));
                          },
                        ),
                      ),
                      const SizedBox(width: Sp.s),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.sos_rounded,
                          label: tr('emergency'),
                          color: C.danger,
                          onTap: () => showEmergencySheet(context),
                        ),
                      ),
                      const SizedBox(width: Sp.s),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.volume_off_rounded,
                          label: tr('silence'),
                          onTap: () async {
                            await cancelAlarm();
                            if (mounted) showSnack(context, tr('silenced'));
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AckBanner extends StatelessWidget {
  const _AckBanner({required this.a});
  final AlertItem a;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Sp.l),
      decoration: BoxDecoration(
        gradient: C.safeGradient,
        borderRadius: BorderRadius.circular(Sp.radius),
        border: Border.all(color: C.safe.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const IconBubble(Icons.visibility_rounded, color: C.safe),
          const SizedBox(width: Sp.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('is_watching', {'name': a.ackBy!}),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                if (a.responseTime != null)
                  Text(
                    tr('responded_in', {'t': shortDuration(a.responseTime!)}),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap, this.color = C.text});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GCard(
      padding: const EdgeInsets.symmetric(vertical: Sp.m),
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: color)),
        ],
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
          ),
          Expanded(
            child: EmptyState(icon: Icons.image_not_supported_rounded, title: tr('alert_missing')),
          ),
        ],
      ),
    );
  }
}
