import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../theme.dart';

IconData categoryIcon(Category c) => switch (c) {
      Category.dog => Icons.pets_rounded,
      Category.person => Icons.directions_walk_rounded,
      Category.animal => Icons.cruelty_free_rounded,
      Category.fire => Icons.local_fire_department_rounded,
      Category.other => Icons.warning_amber_rounded,
    };

Color categoryColor(Category c) => switch (c) {
      Category.dog => C.warn,
      Category.person => C.info,
      Category.animal => const Color(0xFFA78BFA),
      Category.fire => C.danger,
      Category.other => C.muted,
    };

String categoryLabel(Category c) => switch (c) {
      Category.dog => tr('cat_dog'),
      Category.person => tr('cat_person'),
      Category.animal => tr('cat_animal'),
      Category.fire => tr('cat_fire'),
      Category.other => tr('cat_other'),
    };
