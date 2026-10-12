import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../theme.dart';
import '../widgets/breathing_shield.dart';

final _auth = LocalAuthentication();
bool _authenticating = false;

/// Fingerprint / PIN se app kholna.
Future<bool> authenticate() async {
  _authenticating = true;
  try {
    return await _auth.authenticate(
      localizedReason: tr('lock_reason'),
      biometricOnly: false,
      persistAcrossBackgrounding: true,
    );
  } catch (_) {
    return false;
  } finally {
    _authenticating = false;
  }
}

Future<bool> canUseLock() async {
  try {
    return await _auth.isDeviceSupported();
  } catch (_) {
    return false;
  }
}

/// App lock on ho to home dikhane se pehle unlock maangta hai.
/// Alarm wali screen is gate ke bahar hai, taaki khatre mein deri na ho.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.child});
  final Widget child;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  late bool _locked = AppState.lockEnabled.value;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_locked) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_authenticating) return;
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final away = _pausedAt == null ? Duration.zero : DateTime.now().difference(_pausedAt!);
      if (AppState.lockEnabled.value && away.inSeconds > 30) {
        setState(() => _locked = true);
        _unlock();
      }
    }
  }

  Future<void> _unlock() async {
    final ok = await authenticate();
    if (ok && mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) return widget.child;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Sp.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BreathingShield(color: C.brand, icon: Icons.lock_rounded, size: 84),
                const SizedBox(height: Sp.l),
                Text(tr('locked_title'), style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: Sp.s),
                Text(tr('locked_sub'),
                    textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: Sp.xl),
                FilledButton.icon(
                  onPressed: _unlock,
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: Text(tr('unlock')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
