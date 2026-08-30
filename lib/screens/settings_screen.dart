import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_helpers.dart';
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

  /// Empty means "follow the device locale".
  late String _languageCode;

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
    _languageCode = s.languageCode;
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
      languageCode: _languageCode,
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final l10n = context.l10n;
    final client = ShiftApiClient(_currentDraft());
    try {
      await client.ping();
      setState(() {
        _testOk = true;
        _testResult = l10n.connectionSuccessful;
      });
    } on ApiException catch (e) {
      final code = e.statusCode;
      setState(() {
        _testOk = false;
        _testResult = l10n.connectionFailed(
            code == null ? e.message : l10n.errorWithCode(e.message, code));
      });
    } catch (e) {
      setState(() {
        _testOk = false;
        _testResult = l10n.connectionFailed('$e');
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
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(l10n.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionLabel(context, l10n.sectionServer),
            TextFormField(
              controller: _baseUrl,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.apiBaseUrl,
                hintText: 'http://localhost:8080/api/v1',
                prefixIcon: const Icon(Icons.link),
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return l10n.fieldRequired;
                final uri = Uri.tryParse(t);
                if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                  return l10n.enterValidUrl;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _sectionLabel(context, l10n.sectionSignIn),
            TextFormField(
              controller: _oidcIssuer,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.issuerUrl,
                hintText: 'http://localhost/auth/realms/shift',
                prefixIcon: const Icon(Icons.security),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _oidcClientId,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.clientId,
                helperText: l10n.clientIdHelper,
                prefixIcon: const Icon(Icons.apps),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _oidcRedirectUri,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.redirectUri,
                hintText: 'http://localhost:8900/auth/callback',
                prefixIcon: const Icon(Icons.u_turn_left),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _sectionLabel(context, l10n.sectionManualLogin),
            TextFormField(
              controller: _username,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.username,
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: l10n.password,
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
              decoration: InputDecoration(
                labelText: l10n.bearerToken,
                helperText: l10n.bearerTokenHelper,
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _sectionLabel(context, l10n.sectionCalendarScope),
            TextFormField(
              controller: _employeeId,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.employeeIdOptional,
                helperText: l10n.employeeIdHelper,
                prefixIcon: const Icon(Icons.badge_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _sectionLabel(context, l10n.sectionAppearance),
            DropdownButtonFormField<String>(
              initialValue: _languageCode,
              decoration: InputDecoration(
                labelText: l10n.language,
                prefixIcon: const Icon(Icons.translate),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: '', child: Text(l10n.languageSystem)),
                DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
                DropdownMenuItem(value: 'de', child: Text(l10n.languageGerman)),
              ],
              onChanged: (v) => setState(() => _languageCode = v ?? ''),
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
              label: Text(l10n.testConnection),
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
