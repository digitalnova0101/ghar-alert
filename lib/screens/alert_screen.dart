import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../alarm_service.dart';
import '../format.dart';
import '../name_dialog.dart';
import '../native.dart';
import 'home_screen.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key, required this.alertId, this.autoAck = false});
  final String alertId;
  final bool autoAck;

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  late final DocumentReference<Map<String, dynamic>> _doc =
      FirebaseFirestore.instance.collection('alerts').doc(widget.alertId);
  bool _busy = false;
  bool _ackSeen = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoAck) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _acknowledge());
    }
  }

  Future<void> _acknowledge() async {
    if (_busy) return;
    setState(() => _busy = true);
    await cancelAlarm();
    try {
      var name = await getMyName();
      if (name == null && mounted) name = await askMyName(context);
      name ??= 'Koi';
      final me = name;
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(_doc);
        if (snap.data()?['ackBy'] == null) {
          tx.update(_doc, {'ackBy': me, 'ackAt': FieldValue.serverTimestamp()});
        }
      });
    } catch (e) {
      _snack('Save nahi hua, internet check karo');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openLive() async {
    await cancelAlarm();
    final ok = await Native.openSeeEasy();
    if (!ok) _snack('SeeEasy app nahi mila');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _close() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: scheme.errorContainer,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(icon: const Icon(Icons.close), onPressed: _close),
          title: const Text('Ghar Alert'),
        ),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _doc.snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(child: Text('Alert load nahi hua'));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snap.data!.data();
            if (data == null) {
              return const Center(child: Text('Yeh alert ab maujood nahi hai'));
            }

            final ackBy = data['ackBy'] as String?;
            if (ackBy != null && !_ackSeen) {
              _ackSeen = true;
              cancelAlarm();
            }
            final image = data['image'];

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Text(
                    data['camera'] ?? 'Camera',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['reason'] ?? '',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: scheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatTime(data['createdAt'] as Timestamp?),
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                  const SizedBox(height: 16),
                  if (image is Blob)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: InteractiveViewer(
                        child: Image.memory(image.bytes, fit: BoxFit.cover),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (ackBy != null)
                    Card(
                      color: Colors.green.shade700,
                      child: ListTile(
                        leading: const Icon(Icons.visibility, color: Colors.white),
                        title: Text(
                          '$ackBy dekh raha hai',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          formatTime(data['ackAt'] as Timestamp?),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 64,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError,
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _busy ? null : _acknowledge,
                        icon: const Icon(Icons.front_hand),
                        label: const Text('Main dekh raha hoon'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openLive,
                          icon: const Icon(Icons.videocam),
                          label: const Text('Live dekho'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await cancelAlarm();
                            _snack('Is phone ka alarm chup');
                          },
                          icon: const Icon(Icons.volume_off),
                          label: const Text('Chup karo'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
