import 'package:flutter/material.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/app/theme.dart';
import 'package:transia_mobile/core/settings/app_preferences_controller.dart';

class TransiaApp extends StatelessWidget {
  const TransiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppPreferencesController.instance,
      builder: (context, _) {
        final prefs = AppPreferencesController.instance;

        return Directionality(
          textDirection: prefs.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Transia',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: prefs.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: appRouter,
          ),
        );
      },
    );
  }
}