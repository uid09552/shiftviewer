import 'package:flutter/material.dart';

import '../../l10n/l10n_helpers.dart';
import '../../models/models.dart';
import '../../services/admin_api.dart';
import 'admin_common.dart';

/// Capabilities, grouped by skill group. Within a group a higher level can
/// cover for a lower one, which is what the optimizer's skill downgrade weighs.
class CapabilitiesScreen extends StatefulWidget {
  const CapabilitiesScreen({super.key});

  @override
  State<CapabilitiesScreen> createState() => _CapabilitiesScreenState();
}

class _CapabilitiesScreenState extends State<CapabilitiesScreen>
    with AdminApiState<CapabilitiesScreen> {
  List<Capability> _caps = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await api.capabilities();
      if (mounted) setState(() => _caps = list);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([Capability? c]) async {
    final groups = {
      for (final x in _caps)
        if (x.skillGroup != null && x.skillGroup!.isNotEmpty) x.skillGroup!,
    }.toList()
      ..sort();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _CapabilityDialog(api: api, capability: c, groups: groups),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Capability c) async {
    final l10n = context.l10n;
    final ok = await confirmAction(
      context,
      title: l10n.admDeleteCapability,
      message: l10n.admDeleteCapabilityMessage(c.name),
    );
    if (!ok) return;
    try {
      await api.deleteCapability(c.id);
      _load();
    } catch (e) {
      if (mounted) showAdminError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final grouped = <String?, List<Capability>>{};
    for (final c in _caps) {
      final g = (c.skillGroup?.isEmpty ?? true) ? null : c.skillGroup;
      grouped.putIfAbsent(g, () => []).add(c);
    }
    final keys = grouped.keys.toList()
      ..sort((a, b) => a == null ? 1 : b == null ? -1 : a.compareTo(b));
    for (final list in grouped.values) {
      list.sort((a, b) => a.level != b.level
          ? a.level.compareTo(b.level)
          : a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.admCapabilities)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: Text(l10n.admAddCapability),
      ),
      body: AdminLoadState(
        loading: _loading,
        error: _error,
        onRetry: _load,
        builder: () => _caps.isEmpty
            ? AdminEmpty(l10n.noCapabilities)
            : ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                  for (final g in keys) ...[
                    AdminSectionHeader(g ?? l10n.admNoSkillGroup),
                    for (final c in grouped[g]!)
                      ListTile(
                        title: Text(c.name),
                        subtitle: g == null ? null : Text(l10n.skillLevel(c.level)),
                        onTap: () => _edit(c),
                        trailing: IconButton(
                          tooltip: l10n.delete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(c),
                        ),
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _CapabilityDialog extends StatefulWidget {
  final AdminApi api;
  final Capability? capability;
  final List<String> groups;

  const _CapabilityDialog({
    required this.api,
    required this.capability,
    required this.groups,
  });

  @override
  State<_CapabilityDialog> createState() => _CapabilityDialogState();
}

class _CapabilityDialogState extends State<_CapabilityDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.capability?.name ?? '');
  late final TextEditingController _group =
      TextEditingController(text: widget.capability?.skillGroup ?? '');
  late int _level = widget.capability?.level ?? 1;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _group.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final group = _group.text.trim();
      await widget.api.saveCapability(
        id: widget.capability?.id,
        name: _name.text.trim(),
        level: _level,
        skillGroup: group.isEmpty ? null : group,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showAdminError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.capability == null
          ? l10n.admAddCapability
          : l10n.admEditCapability),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.admName),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 12),
            Autocomplete<String>(
              initialValue: _group.value,
              optionsBuilder: (v) => widget.groups.where(
                  (g) => g.toLowerCase().contains(v.text.toLowerCase())),
              onSelected: (g) => _group.text = g,
              fieldViewBuilder: (ctx, controller, focus, _) {
                controller.addListener(() => _group.text = controller.text);
                return TextField(
                  controller: controller,
                  focusNode: focus,
                  decoration: InputDecoration(
                    labelText: l10n.admSkillGroup,
                    helperText: l10n.admSkillGroupHint,
                    helperMaxLines: 3,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            IntStepper(
              label: l10n.admLevel,
              value: _level,
              min: 1,
              max: 10,
              onChanged: (v) => setState(() => _level = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
