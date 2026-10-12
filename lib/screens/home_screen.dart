import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../format.dart';
import '../name_dialog.dart';
import '../native.dart';
import 'alert_screen.dart';
import 'setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _db = FirebaseFirestore.instance;
  Timer? _ticker;
  bool _setupComplete = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // "x min pehle" ko taaza rakhne ke liye
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _firstRun());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkSetup();
  }

  Future<void> _firstRun() async {
    if (await getMyName() == null && mounted) {
      await askMyName(context);
    }
    await _checkSetup();
  }

  Future<void> _checkSetup() async {
    final s = await SetupStatus.check();
    if (mounted) setState(() => _setupComplete = s.complete);
  }

  void _openSetup() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const SetupScreen()))
      .then((_) => _checkSetup());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghar Alert'),
        actions: [
          IconButton(
            tooltip: 'Live camera',
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () async {
              final ok = await Native.openSeeEasy();
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('SeeEasy app nahi mila')),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Setup',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSetup,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _statusCard()),
          if (!_setupComplete) SliverToBoxAdapter(child: _setupBanner()),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text('Pichhle alerts',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          _alertList(),
        ],
      ),
    );
  }

  Widget _statusCard() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('status').doc('system').snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final lastSeen = data?['lastSeen'] as Timestamp?;
        final online = lastSeen != null &&
            DateTime.now().difference(lastSeen.toDate()).inMinutes < 3;
        final cameras =
            (data?['cameras'] as Map<String, dynamic>?) ?? <String, dynamic>{};

        final color = online ? Colors.green.shade700 : Colors.red.shade700;
        return Card(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(online ? Icons.shield : Icons.shield_outlined,
                      color: color, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          online ? 'Nazar rakhi ja rahi hai' : 'System band hai',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(online
                            ? 'Last check: ${timeAgo(lastSeen)}'
                            : 'Purana phone, Wi-Fi ya bijli check karo '
                                '(last: ${timeAgo(lastSeen)})'),
                      ],
                    ),
                  ),
                ]),
                if (cameras.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in cameras.entries)
                        Chip(
                          avatar: Icon(
                            e.value == true && online
                                ? Icons.videocam
                                : Icons.videocam_off,
                            size: 18,
                          ),
                          label: Text(e.key),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _setupBanner() {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: scheme.errorContainer,
      child: ListTile(
        leading: Icon(Icons.warning_amber, color: scheme.onErrorContainer),
        title: Text('Setup adhoora hai',
            style: TextStyle(color: scheme.onErrorContainer)),
        subtitle: Text('Silent phone pe alarm ke liye permissions do',
            style: TextStyle(color: scheme.onErrorContainer)),
        trailing: Icon(Icons.chevron_right, color: scheme.onErrorContainer),
        onTap: _openSetup,
      ),
    );
  }

  Widget _alertList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('alerts')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Alerts load nahi hue. Internet check karo.'),
            ),
          );
        }
        if (!snap.hasData) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Abhi tak koi alert nahi aaya 🙂')),
            ),
          );
        }
        return SliverList.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final image = d['image'];
            final ackBy = d['ackBy'] as String?;
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 64,
                  height: 48,
                  child: image is Blob
                      ? Image.memory(image.bytes, fit: BoxFit.cover)
                      : const ColoredBox(color: Colors.black26),
                ),
              ),
              title: Text(d['reason'] ?? '',
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${d['camera'] ?? ''} · ${formatTime(d['createdAt'] as Timestamp?)}'
                '${ackBy != null ? '\n👀 $ackBy ne dekha' : '\n⚠️ Kisi ne nahi dekha'}',
              ),
              isThreeLine: true,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => AlertScreen(alertId: docs[i].id),
              )),
            );
          },
        );
      },
    );
  }
}
