import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'settings_screen.dart';

/// Authentication gate shown until the user completes the OIDC PKCE flow.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);
    final busy = auth.status == AuthStatus.authenticating;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.calendar_month,
                    size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text('Shift Viewer',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Sign in to view your shift schedule',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(height: 32),
                if (auth.status == AuthStatus.error && auth.errorMessage != null)
                  _errorBox(context, auth.errorMessage!),
                if (!auth.isLoginSupported)
                  _errorBox(
                      context, 'Login is not supported on this platform.'),
                FilledButton.icon(
                  onPressed:
                      (busy || !auth.isLoginSupported) ? null : auth.login,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: Text(busy ? 'Redirecting…' : 'Sign in'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('Connection settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorBox(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline,
              size: 18, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(color: scheme.onErrorContainer, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
