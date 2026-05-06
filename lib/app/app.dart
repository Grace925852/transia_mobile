import 'package:flutter/material.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/app/theme.dart';

class TransiaApp extends StatelessWidget {
  const TransiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Transia',
      theme: appTheme,
      routerConfig: appRouter,
    );
  }
}