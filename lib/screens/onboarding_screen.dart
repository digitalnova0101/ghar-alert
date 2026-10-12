import 'package:flutter/material.dart';

import '../app_state.dart';
import '../db.dart';
import '../l10n.dart';
import '../theme.dart';
import '../widgets/breathing_shield.dart';
import 'permissions_screen.dart';
import 'settings_tab.dart';
import 'shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  final _name = TextEditingController(text: AppState.myName.value ?? '');
  int _i = 0;
  static const _count = 5;

  @override
  void dispose() {
    _page.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    if (_i == 3) {
      final n = _name.text.trim();
      if (n.isEmpty) return;
      await AppState.setName(n);
      Db.touchMember().ignore();
    }
    if (_i == _count - 1) {
      await AppState.setOnboarded();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
      return;
    }
    _page.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.l, Sp.s, Sp.s, 0),
              child: Row(
                children: [
                  _dots(),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => showLanguageSheet(context),
                    icon: const Icon(Icons.translate_rounded, size: 18),
                    label: Text(langName(AppState.lang.value)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _i = i),
                children: [
                  _intro(C.safe, Icons.shield_rounded, tr('ob1_title'), tr('ob1_body')),
                  _intro(C.danger, Icons.campaign_rounded, tr('ob2_title'), tr('ob2_body')),
                  _intro(C.brand, Icons.people_rounded, tr('ob3_title'), tr('ob3_body')),
                  _namePage(),
                  _permPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.l, 0, Sp.l, Sp.l),
              child: ListenableBuilder(
                listenable: _name,
                builder: (context, _) => FilledButton(
                  onPressed: (_i == 3 && _name.text.trim().isEmpty) ? null : _next,
                  child: Text(_i == _count - 1 ? tr('get_started') : tr('next')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dots() {
    return Row(
      children: [
        for (var i = 0; i < _count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(right: 6),
            width: i == _i ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == _i ? C.brand : C.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }

  Widget _intro(Color color, IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.all(Sp.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BreathingShield(color: color, icon: icon, size: 120),
          const SizedBox(height: Sp.xl),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: Sp.m),
          Text(body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: C.muted, height: 1.5)),
        ],
      ),
    );
  }

  Widget _namePage() {
    return Padding(
      padding: const EdgeInsets.all(Sp.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('ob_name_title'), style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: Sp.s),
          Text(tr('ob_name_body'), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: C.muted)),
          const SizedBox(height: Sp.xl),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            maxLength: 30,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            decoration: InputDecoration(hintText: tr('name_hint')),
            onSubmitted: (_) => _next(),
          ),
        ],
      ),
    );
  }

  Widget _permPage() {
    return ListView(
      padding: const EdgeInsets.all(Sp.xl),
      children: [
        Text(tr('ob_perm_title'), style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: Sp.s),
        Text(tr('ob_perm_body'), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: C.muted)),
        const SizedBox(height: Sp.xl),
        const PermissionsList(),
      ],
    );
  }
}
