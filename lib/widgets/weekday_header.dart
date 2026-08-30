import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n_helpers.dart';

/// Mon–Sun column labels for the month grids, in the current language.
class WeekdayHeader extends StatelessWidget {
  const WeekdayHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final labels =
        DateFormat.E(context.dateLocale).dateSymbols.STANDALONESHORTWEEKDAYS;
    // Dart intl weekday order is Sun..Sat; reorder to Mon..Sun.
    final ordered = [
      labels[1], labels[2], labels[3], labels[4], labels[5], labels[6],
      labels[0],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          for (final l in ordered)
            Expanded(
              child: Center(
                child: Text(l, style: Theme.of(context).textTheme.labelSmall),
              ),
            ),
        ],
      ),
    );
  }
}
