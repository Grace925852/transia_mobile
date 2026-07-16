import 'package:flutter/material.dart';
import 'package:transia_mobile/core/settings/app_preferences_controller.dart';
import 'package:transia_mobile/features/client/screens/client_colis_list_screen.dart';
import 'package:transia_mobile/features/client/screens/client_home_screen.dart';
import 'package:transia_mobile/features/client/screens/profile_screen.dart';
import 'package:transia_mobile/features/client/screens/reservations_screen.dart';
import 'package:transia_mobile/features/client/screens/tracking_list_screen.dart';

class ClientMainScreen extends StatefulWidget {
  final int initialIndex;

  const ClientMainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<ClientMainScreen> createState() => _ClientMainScreenState();
}

class _ClientMainScreenState extends State<ClientMainScreen> {
  late int selectedIndex;
  late final List<Widget> pages;

  AppPreferencesController get prefs => AppPreferencesController.instance;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
    pages = const [
      ClientHomeScreen(showScaffold: false),
      ReservationsScreen(),
      ClientColisListScreen(),
      TrackingListScreen(),
      ProfileScreen(),
    ];
  }

  String tr({
    required String fr,
    required String en,
    required String es,
    required String ar,
  }) {
    return prefs.tr(fr: fr, en: en, es: es, ar: ar);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = theme.bottomNavigationBarTheme;

    return AnimatedBuilder(
      animation: prefs,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(
            index: selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: navTheme.backgroundColor ?? theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.22 : 0.07,
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: selectedIndex,
                onTap: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                backgroundColor: navTheme.backgroundColor ?? theme.cardColor,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor:
                    navTheme.selectedItemColor ?? const Color(0xFF3158F5),
                unselectedItemColor:
                    navTheme.unselectedItemColor ?? const Color(0xFF9CA3AF),
                selectedFontSize: 11,
                unselectedFontSize: 11,
                iconSize: 24,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_rounded),
                    label: tr(
                      fr: 'Accueil',
                      en: 'Home',
                      es: 'Inicio',
                      ar: 'الرئيسية',
                    ),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.event_note_rounded),
                    label: tr(
                      fr: 'Réserv.',
                      en: 'Bookings',
                      es: 'Reserv.',
                      ar: 'الحجوزات',
                    ),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.inventory_2_outlined),
                    activeIcon: const Icon(Icons.inventory_2_rounded),
                    label: tr(
                      fr: 'Colis',
                      en: 'Parcels',
                      es: 'Paquetes',
                      ar: 'الطرود',
                    ),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.location_on_outlined),
                    activeIcon: const Icon(Icons.location_on_rounded),
                    label: tr(
                      fr: 'Suivi',
                      en: 'Tracking',
                      es: 'Seguim.',
                      ar: 'التتبع',
                    ),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person_outline_rounded),
                    activeIcon: const Icon(Icons.person_rounded),
                    label: tr(
                      fr: 'Profil',
                      en: 'Profile',
                      es: 'Perfil',
                      ar: 'الملف',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}