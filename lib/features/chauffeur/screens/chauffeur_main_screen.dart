import 'package:flutter/material.dart';
import 'package:transia_mobile/features/chauffeur/screens/chauffeur_history_screen.dart';
import 'package:transia_mobile/features/chauffeur/screens/chauffeur_home_screen.dart';
import 'package:transia_mobile/features/chauffeur/screens/chauffeur_scan_trip_list_screen.dart';
import 'package:transia_mobile/features/client/screens/profile_screen.dart';

class ChauffeurMainScreen extends StatefulWidget {
  final int initialIndex;

  const ChauffeurMainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<ChauffeurMainScreen> createState() => _ChauffeurMainScreenState();
}

class _ChauffeurMainScreenState extends State<ChauffeurMainScreen> {
  late int selectedIndex;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
    pages = const [
      ChauffeurHomeScreen(),
      ChauffeurScanTripListScreen(),
      ChauffeurHistoryScreen(),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: theme.bottomNavigationBarTheme.backgroundColor ??
                theme.cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.22 : 0.07),
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
            backgroundColor:
                theme.bottomNavigationBarTheme.backgroundColor ??
                    theme.cardColor,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF3158F5),
            unselectedItemColor:
                theme.bottomNavigationBarTheme.unselectedItemColor ??
                    theme.disabledColor,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            iconSize: 24,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner_rounded),
                label: 'Scan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded),
                label: 'Historique',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}