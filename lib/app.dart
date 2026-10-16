import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization/app_locale.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/app_providers.dart';

class LinkoraApp extends ConsumerWidget {
  const LinkoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final currentTheme = ref.watch(themeOptionProvider);

    return MaterialApp.router(
      title: 'LINKORA',
      debugShowCheckedModeBanner: false,
      theme: currentTheme == ThemeOption.amoled ? AppTheme.amoledTheme : AppTheme.darkTheme,
      routerConfig: appRouter,
      locale: currentLocale,
      supportedLocales: const [
        AppLocale.enLocale,
        AppLocale.kmLocale,
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
