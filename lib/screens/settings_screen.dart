import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/app_settings.dart';

/// Configure API URL + login information.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _baseUrl;
  late TextEditingController _username;
  late TextEditingController _password;
  late TextEditingController _token;
  late TextEditingController _employeeId;
  late TextEditingController _oidcIssuer;
  late TextEditingController _oidcClientId;
  late TextEditingController _oidcRedirectUri;
  bool _obscurePassword = true;
  bool _testing = false;
  String? _testResult;
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsController>().settings;
    _baseUrl = TextEditingController(text: s.baseUrl);
    _username = TextEditingController(text: s.username);
    _password = TextEditingController(text: s.password);
    _token = TextEditingController(text: s.bearerToken);
    _employeeId = TextEditingController(text: s.employeeId);
    _oidcIssuer = TextEditingController(text: s.oidcIssuer);
    _oidcClientId = TextEditingController(text: s.oidcClientId);
    _oidcRedirectUri = TextEditingController(text: s.oidcRedirectUri);
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _username.dispose();
    _password.dispose();
    _token.dispose();
    _employeeId.dispose();
    _oidcIssuer.dispose();
    _oidcClientId.dispose();
    _oidcRedirectUri.dispose();
    super.dispose();
  }

  AppSettings _currentDraft() {
    // Preserve the (UI-hidden) scopes from the saved settings.
    final existing = context.read<SettingsController>().settings;
    return AppSettings(
      baseUrl: _baseUrl.text.trim(),
      username: _username.text.trim(),
      password: _password.text,
      bearerToken: _token.text.trim(),
      employeeId: _employeeId.text.trim(),
      oidcIssuer: _oidcIssuer.text.trim(),
      oidcClientId: _oidcClientId.text.trim(),
      oidcRedirectUri: _oidcRedirectUri.text.trim(),
      oidcScopes: existing.oidcScopes,
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final client = ShiftApiClient(_currentDraft());
    try {
      await client.ping();
      setState(() {
        _testOk = true;
        _testResult = 'Connection successful';
      });
    } on ApiException catch (e) {
      setState(() {
        _testOk = false;
        _testResult = 'Failed: ${e.message}'
            '${e.statusCode != null ? ' (${e.statusCode})' : ''}';
      });
    } catch (e) {
      setState(() {
        _testOk = false;
        _testResult = 'Failed: $e';
      });
    } finally {
      client.close();
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<SettingsController>().save(_currentDraft());
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionLabel(context, 'Server'),
            TextFormField(
              controller: _baseUrl,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'API base URL',
                hintText: 'http://localhost:8080/api/v1',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Required';
                final uri = Uri.tryParse(t);
                if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                  return 'Enter a valid URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _sectionLabel(context, 'Sign-in (OIDC · PKCE)'),
            TextFormField(
              controller: _oidcIssuer,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Issuer / realm URL',
                hintText: 'http://localhost/auth/realms/shift',
                prefixIcon: Icon(Icons.security),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _oidcClientId,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Client ID',
                helperText: 'Same client as the API gateway · PKCE (S256)',
                prefixIcon: Icon(Icons.apps),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _oidcRedirectUri,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Redirect URI',
                hintText: 'http://localhost:8900/auth/callback',
                prefixIcon: Icon(Icons.u_turn_left),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _sectionLabel(context, 'Manual login (fallback)'),
            TextFormField(
              controller: _username,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _token,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Bearer token (optional)',
                helperText: 'Used instead of username/password when set',
                prefixIcon: Icon(Icons.vpn_key_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _sectionLabel(context, 'Calendar scope'),
            TextFormField(
              controller: _employeeId,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Employee ID (optional)',
                helperText:
                    'Show only this employee\'s roster; leave empty for all',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _testing ? null : _testConnection,
              icon: _testing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering),
              label: const Text('Test connection'),
            ),
            if (_testResult != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(_testOk ? Icons.check_circle : Icons.error,
                        color: _testOk ? Colors.green : Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_testResult!)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}
