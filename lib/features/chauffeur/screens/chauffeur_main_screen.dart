import 'package:flutter/material.dart';
import 'package:transia_mobile/features/chauffeur/screens/chauffeur_home_screen.dart';
import 'package:transia_mobile/features/chauffeur/screens/chauffeur_profile_screen.dart';

class ChauffeurMainScreen extends StatefulWidget {
  const ChauffeurMainScreen({super.key});

  @override
  State<ChauffeurMainScreen> createState() => _ChauffeurMainScreenState();
}

class _ChauffeurMainScreenState extends State<ChauffeurMainScreen> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    ChauffeurHomeScreen(),
    ChauffeurScanPlaceholderScreen(),
    ChauffeurProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: NavigationBar(
        height: 74,
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class ChauffeurScanPlaceholderScreen extends StatelessWidget {
  const ChauffeurScanPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 60,
                    color: Color(0xFF3158F5),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Scan QR',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Le scan des billets sera branché juste après.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}