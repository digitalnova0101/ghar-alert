import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alarm_service.dart';

Future<String?> getMyName() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(Prefs.myName);
}

/// Naam poochta hai (family ko pata chale kisne alert dekha). Save karke return.
Future<String?> askMyName(BuildContext context, {String? current}) async {
  final controller = TextEditingController(text: current ?? '');
  final name = await showDialog<String>(
    context: context,
    barrierDismissible: current != null,
    builder: (ctx) => AlertDialog(
      title: const Text('Aapka naam'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Jaise: Ahmed, Ammi, Bhai',
          helperText: 'Alert dekhne par family ko yahi naam dikhega',
        ),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (name == null || name.isEmpty) return current;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(Prefs.myName, name);
  return name;
}
