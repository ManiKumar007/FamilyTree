import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'router/app_router.dart';
import 'l10n/app_localizations.dart';

// Initial locale provider (set from main.dart with saved preference)
final initialLocaleProvider = Provider<Locale>((ref) => const Locale('en'));

// Locale provider for managing app language
final localeProvider = StateProvider<Locale>((ref) {
  return ref.watch(initialLocaleProvider);
});

class MyFamilyTreeApp extends ConsumerWidget {
  const MyFamilyTreeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Vansh',
      theme: appTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('hi'), // Hindi
        Locale('ta'), // Tamil
        Locale('te'), // Telugu
        Locale('bn'), // Bengali
        Locale('mr'), // Marathi
        Locale('gu'), // Gujarati
        Locale('kn'), // Kannada
      ],
    );
  }
}
