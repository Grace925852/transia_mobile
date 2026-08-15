/*import 'package:flutter/material.dart';
import 'package:transia_mobile/features/chauffeur/screens/chauffeur_main_screen.dart';
import 'package:transia_mobile/features/client/screens/client_main_screen.dart';

void main() {
  runApp(const MyApp());
}

const bool launchChauffeurOnly = true;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: launchChauffeurOnly
          ? const ChauffeurMainScreen()
          : const ClientMainScreen(),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:transia_mobile/app/app.dart';
import 'package:transia_mobile/core/settings/app_preferences_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferencesController.instance.load();
  runApp(const TransiaApp());
}
