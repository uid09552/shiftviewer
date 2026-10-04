import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_helpers.dart';
import '../../models/admin_models.dart';
import '../../services/admin_api.dart';
import 'admin_common.dart';

String roleLabel(AppLocalizations l10n, ShiftRole r) => switch (r) {
  ShiftRole.admin => l10n.admRoleAdmin,
  ShiftRole.planner => l10n.admRolePlanner,
  ShiftRole.viewer => l10n.admRoleViewer,
};

String roleHint(AppLocalizations l10n, ShiftRole r) => switch (r) {
  ShiftRole.admin => l10n.admRoleAdminHint,
  ShiftRole.planner => l10n.admRolePlannerHint,
  ShiftRole.viewer => l10n.admRoleViewerHint,
};

/// The organization's sign-in accounts and their roles. shift-admin only: the
/// accounts live in the identity provider, this decides who belongs here and
/// what they may do.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with AdminApiState<UsersScreen> {
  List<OrganizationUser> _users = [];
  bool _loading = true;
  Object? _error;
  final Set<String> _busy = {};

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
      final list = await api.users();
      list.sort((a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
      if (mounted) setState(() => _users = list);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleRole(OrganizationUser u, ShiftRole role, bool on) async {
    final next = ShiftRole.values
        .where((r) => r == role ? on : u.roles.contains(r))
        .toList();
    setState(() => _busy.add(u.id));
    try {
      final updated = await api.updateUserRoles(u.id, next);
      if (!mounted) return;
      setState(() {
        final i = _users.indexWhere((x) => x.id == u.id);
        if (i >= 0) _users[i] = updated;
      });
      showAdminMessage(context, context.l10n.admRolesSaved);
    } catch (e) {
      if (mounted) showAdminError(context, e);
    } finally {
      if (mounted) setState(() => _busy.remove(u.id));
    }
  }

  Future<void> _remove(OrganizationUser u) async {
    final l10n = context.l10n;
    final ok = await confirmAction(
      context,
      title: l10n.admRemoveUser,
      message: l10n.admRemoveUserMessage(u.displayName),
      confirmLabel: l10n.admRemove,
    );
    if (!ok) return;
    try {
      await api.removeUser(u.id);
      _load();
    } catch (e) {
      if (mounted) showAdminError(context, e);
    }
  }

  Future<void> _create() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CreateUserDialog(api: api),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.admUsers)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.person_add_alt),
        label: Text(l10n.admAddUser),
      ),
      body: AdminLoadState(
        loading: _loading,
        error: _error,
        onRetry: _load,
        builder: () => _users.isEmpty
            ? AdminEmpty(l10n.admNoUsers)
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: _users.length,
                itemBuilder: (_, i) {
                  final u = _users[i];
                  final busy = _busy.contains(u.id);
                  return ExpansionTile(
                    leading: CircleAvatar(
                      child: Icon(u.enabled ? Icons.person : Icons.person_off),
                    ),
                    title: Text(u.displayName),
                    subtitle: Text([
                      if (u.email != null) u.email!,
                      u.roles.isEmpty
                          ? l10n.admNoRoles
                          : u.roles.map((r) => roleLabel(l10n, r)).join(', '),
                    ].join(' · ')),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    children: [
                      if (u.username != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(l10n.admUsernameValue(u.username!),
                              style: theme.textTheme.bodySmall),
                        ),
                      for (final r in ShiftRole.values)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(roleLabel(l10n, r)),
                          subtitle: Text(roleHint(l10n, r)),
                          value: u.roles.contains(r),
                          onChanged: busy ? null : (v) => _toggleRole(u, r, v ?? false),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.error),
                          onPressed: busy ? null : () => _remove(u),
                          icon: const Icon(Icons.person_remove_outlined),
                          label: Text(l10n.admRemoveUser),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _CreateUserDialog extends StatefulWidget {
  final AdminApi api;

  const _CreateUserDialog({required this.api});

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _password = TextEditingController();
  bool _temporary = true;
  final Set<ShiftRole> _roles = {ShiftRole.viewer};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_username, _email, _first, _last, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _opt(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.api.createUser(
        username: _username.text.trim(),
        email: _opt(_email),
        firstName: _opt(_first),
        lastName: _opt(_last),
        password: _opt(_password),
        temporaryPassword: _temporary,
        roles: ShiftRole.values.where(_roles.contains).toList(),
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
      title: Text(l10n.admAddUser),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _username,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.username),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
              ),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.admEmail),
              ),
              TextFormField(
                controller: _first,
                decoration: InputDecoration(labelText: l10n.admFirstName),
              ),
              TextFormField(
                controller: _last,
                decoration: InputDecoration(labelText: l10n.admLastName),
              ),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  helperText: l10n.admPasswordHint,
                  helperMaxLines: 3,
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.admTemporaryPassword),
                value: _temporary,
                onChanged: (v) => setState(() => _temporary = v ?? true),
              ),
              const Divider(),
              for (final r in ShiftRole.values)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(roleLabel(l10n, r)),
                  value: _roles.contains(r),
                  onChanged: (v) => setState(
                      () => (v ?? false) ? _roles.add(r) : _roles.remove(r)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.admCreate),
        ),
      ],
    );
  }
}
