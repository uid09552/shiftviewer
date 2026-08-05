import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/auth_gate.dart';
import 'services/app_settings.dart';
import 'services/auth_service.dart';
import 'services/shift_data_controller.dart';

void main() {
  runApp(const ShiftViewerApp());
}

class ShiftViewerApp extends StatelessWidget {
  const ShiftViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsController()..load(),
        ),
        // Data controller starts with default settings; HomeScreen re-syncs it
        // with the loaded/edited settings before each refresh.
        ChangeNotifierProvider(
          create: (_) => ShiftDataController(const AppSettings()),
        ),
        // Auth reads the OIDC config from the settings controller above.
        ChangeNotifierProvider(
          create: (ctx) => AuthController(ctx.read<SettingsController>()),
        ),
      ],
      child: MaterialApp(
        title: 'Shift Viewer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3B82F6),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}
