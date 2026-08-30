import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'screens/auth_gate.dart';
import 'services/app_settings.dart';
import 'services/auth_service.dart';
import 'services/shift_data_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Month and weekday names for every supported locale, so DateFormat can be
  // used with an explicit locale tag rather than only the system one.
  await initializeDateFormatting();
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
      // Rebuild on settings changes so switching the language takes effect
      // immediately, without a restart.
      child: Consumer<SettingsController>(
        builder: (context, settings, _) => MaterialApp(
          onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
          debugShowCheckedModeBanner: false,
          locale: settings.settings.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
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
      ),
    );
  }
}
