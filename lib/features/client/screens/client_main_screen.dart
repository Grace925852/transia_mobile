import 'package:flutter/material.dart';
import 'package:transia_mobile/features/client/screens/client_home_screen.dart';
import 'package:transia_mobile/features/client/screens/profile_screen.dart';
import 'package:transia_mobile/features/client/screens/reservations_screen.dart';

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

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
    pages = const [
      ClientHomeScreen(showScaffold: false),
      ReservationsScreen(),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
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
            backgroundColor: Colors.white,
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
                icon: Icon(Icons.event_note_rounded),
                label: 'Réserv.',
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