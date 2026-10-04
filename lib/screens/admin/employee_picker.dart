import 'package:flutter/material.dart';

import '../../l10n/l10n_helpers.dart';
import '../../models/models.dart';

/// Lets the user tick any number of employees, with search and select-all.
/// Resolves to the picked ids, or null when cancelled.
Future<Set<String>?> pickEmployees(
  BuildContext context,
  List<Employee> employees,
  Set<String> initial,
) => showDialog<Set<String>>(
  context: context,
  builder: (_) => _EmployeePicker(employees: employees, initial: initial),
);

class _EmployeePicker extends StatefulWidget {
  final List<Employee> employees;
  final Set<String> initial;

  const _EmployeePicker({required this.employees, required this.initial});

  @override
  State<_EmployeePicker> createState() => _EmployeePickerState();
}

class _EmployeePickerState extends State<_EmployeePicker> {
  late final Set<String> _picked = {...widget.initial};
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = _filter.toLowerCase();
    final visible = widget.employees
        .where((e) => q.isEmpty || e.name.toLowerCase().contains(q))
        .toList();
    final allVisiblePicked =
        visible.isNotEmpty && visible.every((e) => _picked.contains(e.id));

    return AlertDialog(
      title: Text(l10n.admPeople(_picked.length)),
      contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      content: SizedBox(
        width: 400,
        height: 480,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.admSearchEmployees,
                ),
                onChanged: (v) => setState(() => _filter = v.trim()),
              ),
            ),
            CheckboxListTile(
              title: Text(l10n.admSelectAll),
              value: allVisiblePicked,
              onChanged: (v) => setState(() {
                for (final e in visible) {
                  (v ?? false) ? _picked.add(e.id) : _picked.remove(e.id);
                }
              }),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: visible.length,
                itemBuilder: (_, i) {
                  final e = visible[i];
                  return CheckboxListTile(
                    dense: true,
                    title: Text(e.name),
                    value: _picked.contains(e.id),
                    onChanged: (v) => setState(
                        () => (v ?? false) ? _picked.add(e.id) : _picked.remove(e.id)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _picked),
          child: Text(l10n.admDone),
        ),
      ],
    );
  }
}
