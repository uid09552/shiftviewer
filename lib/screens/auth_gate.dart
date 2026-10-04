import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_settings.dart';
import '../services/auth_service.dart';
import '../services/shift_data_controller.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Enforces authentication: initializes the OIDC flow once settings are loaded,
/// then routes to [LoginScreen] or [HomeScreen] based on auth status.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _initStarted = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final auth = context.watch<AuthController>();

    // Wait until persisted settings are loaded before starting the auth flow,
    // so the OIDC endpoints/client are correct.
    if (!settings.isLoaded) {
      return const _Splash();
    }
    if (!_initStarted) {
      _initStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => auth.initialize());
    }

    // Hand the data layer the session itself rather than a token snapshot: it
    // asks for a token per request, so one that expires mid-session is renewed
    // instead of being sent stale.
    context.read<ShiftDataController>().updateTokenProvider(
          auth.validAccessToken,
        );

    switch (auth.status) {
      case AuthStatus.initializing:
        return const _Splash();
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.authenticating:
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const LoginScreen();
    }
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
