import 'package:flutter/material.dart';

import '../db.dart';
import '../l10n.dart';
import 'alerts_tab.dart';
import 'family_tab.dart';
import 'home_tab.dart';
import 'lock_gate.dart';
import 'settings_tab.dart';
import 'stats_tab.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Db.touchMember().ignore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) Db.touchMember().ignore();
  }

  void goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return LockGate(
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            HomeTab(onSeeAll: () => goTo(1)),
            const AlertsTab(),
            const StatsTab(),
            const FamilyTab(),
            const SettingsTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: goTo,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.shield_outlined),
              selectedIcon: const Icon(Icons.shield_rounded),
              label: tr('tab_home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.notifications_none_rounded),
              selectedIcon: const Icon(Icons.notifications_rounded),
              label: tr('tab_alerts'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: const Icon(Icons.insights_rounded),
              label: tr('tab_stats'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_outline_rounded),
              selectedIcon: const Icon(Icons.people_rounded),
              label: tr('tab_family'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: tr('tab_settings'),
            ),
          ],
        ),
      ),
    );
  }
}
