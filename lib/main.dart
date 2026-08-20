import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'l10n/gen/app_localizations.dart';
import 'state/app_state.dart';
import 'state/history_state.dart';
import 'state/update_state.dart';
import 'theme/app_colors.dart';
import 'screens/home_screen.dart';
import 'services/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.obsidian,
    ),
  );
  AppLogger.instance.info('App starting', tag: 'main');
  runApp(const CosmicWishApp());
}

class CosmicWishApp extends StatelessWidget {
  const CosmicWishApp({super.key});

  Locale? _resolveLocale(String code) {
    switch (code) {
      case 'vi':
        return const Locale('vi');
      case 'en':
        return const Locale('en');
      default:
        return null; // 'system' → MaterialApp follows platform locale
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => HistoryState()),
        ChangeNotifierProvider(create: (_) => UpdateState()),
      ],
      // Builder around the whole MaterialApp lets us read AppState
      // and rebuild the entire tree (including MaterialApp's locale
      // resolution) every time AppState notifies. The previous
      // Consumer approach didn't trigger MaterialApp to relocalise
      // because locale resolution happens at MaterialApp construction.
      child: Builder(
        builder: (context) {
          final appState = context.watch<AppState>();
          return MaterialApp(
            title: 'Cosmic Wish',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: AppColors.obsidian,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.gold,
                brightness: Brightness.dark,
              ),
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: _resolveLocale(appState.locale),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
