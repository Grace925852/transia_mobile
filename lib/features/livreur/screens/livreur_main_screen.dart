import 'package:flutter/material.dart';
import 'package:transia_mobile/features/livreur/screens/livreur_colis_list_screen.dart';
import 'package:transia_mobile/features/livreur/screens/livreur_home_screen.dart';
import 'package:transia_mobile/features/livreur/screens/livreur_profile_screen.dart';
import 'package:transia_mobile/features/livreur/screens/livreur_tournees_screen.dart';

class LivreurMainScreen extends StatefulWidget {
  final int initialIndex;

  const LivreurMainScreen({super.key, this.initialIndex = 0});

  @override
  State<LivreurMainScreen> createState() => _LivreurMainScreenState();
}

class _LivreurMainScreenState extends State<LivreurMainScreen> {
  late int _selectedIndex;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pages = const [
      LivreurHomeScreen(),
      LivreurTourneesScreen(),
      LivreurColisListScreen(),
      LivreurProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.07),
                blurRadius: 14,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            backgroundColor:
                isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF3158F5),
            unselectedItemColor: const Color(0xFF9CA3AF),
            selectedFontSize: 11,
            unselectedFontSize: 11,
            iconSize: 24,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.alt_route_outlined),
                activeIcon: Icon(Icons.alt_route_rounded),
                label: 'Mes Tournées',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_outlined),
                activeIcon: Icon(Icons.inventory_2_rounded),
                label: 'Livraisons',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
