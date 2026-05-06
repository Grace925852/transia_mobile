import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SecureStorageService storage = SecureStorageService();

  String fullName = 'Client';
  String username = '';

  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  String selectedLanguage = 'Français';
  String favoriteDepartureCity = 'Lomé';
  int defaultSeats = 1;
  String preferredPayment = 'Flooz';

  @override
  void initState() {
    super.initState();
    chargerInfos();
    chargerPreferences();
  }

  Future<void> chargerInfos() async {
    final name = await storage.getFullName();
    final phone = await storage.getUsername();

    if (!mounted) return;

    setState(() {
      fullName = (name != null && name.trim().isNotEmpty) ? name : 'Client';
      username = phone ?? '';
    });
  }

  Future<void> chargerPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      notificationsEnabled = prefs.getBool('pref_notifications') ?? true;
      darkModeEnabled = prefs.getBool('pref_dark_mode') ?? false;
      selectedLanguage = prefs.getString('pref_language') ?? 'Français';
      favoriteDepartureCity = prefs.getString('pref_departure_city') ?? 'Lomé';
      defaultSeats = prefs.getInt('pref_default_seats') ?? 1;
      preferredPayment = prefs.getString('pref_payment') ?? 'Flooz';
    });
  }

  Future<void> sauvegarderPreferenceBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> sauvegarderPreferenceString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> sauvegarderPreferenceInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<void> deconnexion() async {
    await storage.clearSession();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  String get initiales {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'CL';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          children: [
            const Text(
              'Profil',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0xFF3158F5),
                    child: Text(
                      initiales,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionTitle(title: 'Navigation'),
            _ProfileTile(
              icon: Icons.history_rounded,
              title: 'Historique',
              subtitle: 'Voir les réservations payées déjà passées',
              onTap: () {
                context.push(AppRoutes.history);
              },
            ),
            const SizedBox(height: 8),
            _SectionTitle(title: 'Préférences'),
            _SwitchTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Recevoir les alertes de réservation',
              value: notificationsEnabled,
              onChanged: (value) async {
                setState(() {
                  notificationsEnabled = value;
                });
                await sauvegarderPreferenceBool('pref_notifications', value);
              },
            ),
            _SwitchTile(
              icon: Icons.dark_mode_outlined,
              title: 'Mode sombre',
              subtitle: 'Option visuelle simple pour la démo',
              value: darkModeEnabled,
              onChanged: (value) async {
                setState(() {
                  darkModeEnabled = value;
                });
                await sauvegarderPreferenceBool('pref_dark_mode', value);
              },
            ),
            _DropdownTile<String>(
              icon: Icons.language_rounded,
              title: 'Langue',
              subtitle: 'Choisissez votre langue préférée',
              value: selectedLanguage,
              items: const ['Français', 'English'],
              onChanged: (value) async {
                if (value == null) return;
                setState(() {
                  selectedLanguage = value;
                });
                await sauvegarderPreferenceString('pref_language', value);
              },
            ),
            _DropdownTile<String>(
              icon: Icons.location_city_outlined,
              title: 'Ville de départ favorite',
              subtitle: 'Ville proposée par défaut',
              value: favoriteDepartureCity,
              items: const ['Lomé', 'Kpalimé', 'Atakpamé', 'Sokodé', 'Kara'],
              onChanged: (value) async {
                if (value == null) return;
                setState(() {
                  favoriteDepartureCity = value;
                });
                await sauvegarderPreferenceString('pref_departure_city', value);
              },
            ),
            _DropdownTile<int>(
              icon: Icons.event_seat_outlined,
              title: 'Nombre de sièges par défaut',
              subtitle: 'Valeur proposée lors d’une réservation',
              value: defaultSeats,
              items: const [1, 2, 3, 4, 5],
              onChanged: (value) async {
                if (value == null) return;
                setState(() {
                  defaultSeats = value;
                });
                await sauvegarderPreferenceInt('pref_default_seats', value);
              },
            ),
            _DropdownTile<String>(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Moyen de paiement préféré',
              subtitle: 'Option préselectionnée',
              value: preferredPayment,
              items: const ['Flooz', 'TMoney'],
              onChanged: (value) async {
                if (value == null) return;
                setState(() {
                  preferredPayment = value;
                });
                await sauvegarderPreferenceString('pref_payment', value);
              },
            ),
            const SizedBox(height: 8),
            _SectionTitle(title: 'Compte'),
            _ProfileTile(
              icon: Icons.logout_rounded,
              title: 'Déconnexion',
              subtitle: 'Quitter votre session',
              onTap: deconnexion,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF3158F5),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF3158F5),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF3158F5),
          ),
        ],
      ),
    );
  }
}

class _DropdownTile<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  const _DropdownTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF3158F5),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<T>(
                  value: value,
                  items: items
                      .map(
                        (item) => DropdownMenuItem<T>(
                          value: item,
                          child: Text(item.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}