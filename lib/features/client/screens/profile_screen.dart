import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/settings/app_preferences_controller.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SecureStorageService storage = SecureStorageService();
  final AppPreferencesController prefs = AppPreferencesController.instance;

  String fullName = 'Client';
  String username = '';

  bool notificationsEnabled = true;
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
    final sharedPrefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      notificationsEnabled =
          sharedPrefs.getBool('pref_notifications') ?? true;
      favoriteDepartureCity =
          sharedPrefs.getString('pref_departure_city') ?? 'Lomé';
      defaultSeats = sharedPrefs.getInt('pref_default_seats') ?? 1;
      preferredPayment =
          sharedPrefs.getString('pref_payment') ?? 'Flooz';
    });
  }

  Future<void> sauvegarderPreferenceBool(String key, bool value) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    await sharedPrefs.setBool(key, value);
  }

  Future<void> sauvegarderPreferenceString(String key, String value) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    await sharedPrefs.setString(key, value);
  }

  Future<void> sauvegarderPreferenceInt(String key, int value) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    await sharedPrefs.setInt(key, value);
  }

  Future<void> deconnexion() async {
    await storage.clearSession();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  String get initiales {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'CL';
    if (parts.length == 1) {
      final first = parts.first;
      return first.substring(0, first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  String tr({
    required String fr,
    required String en,
    required String es,
    required String ar,
  }) {
    return prefs.tr(fr: fr, en: en, es: es, ar: ar);
  }

  List<DropdownMenuItem<String>> _languageItems(Color textColor) {
    return [
      DropdownMenuItem(
        value: 'fr',
        child: Text(
          'Français',
          style: TextStyle(color: textColor),
        ),
      ),
      DropdownMenuItem(
        value: 'en',
        child: Text(
          'English',
          style: TextStyle(color: textColor),
        ),
      ),
      DropdownMenuItem(
        value: 'es',
        child: Text(
          'Español',
          style: TextStyle(color: textColor),
        ),
      ),
      DropdownMenuItem(
        value: 'ar',
        child: Text(
          'العربية',
          style: TextStyle(color: textColor),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: prefs,
      builder: (context, _) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        final backgroundColor = theme.scaffoldBackgroundColor;
        final cardColor = theme.cardColor;
        final primaryBlue = const Color(0xFF3158F5);
        final titleColor =
            theme.textTheme.titleLarge?.color ??
            (isDark ? Colors.white : const Color(0xFF374151));
        final normalTextColor =
            theme.textTheme.bodyLarge?.color ??
            (isDark ? Colors.white : const Color(0xFF374151));
        final subtitleColor =
            theme.textTheme.bodyMedium?.color ??
            (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280));
        final iconBoxColor =
            isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5FF);
        final borderColor =
            isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
        final fieldFillColor =
            isDark ? const Color(0xFF0F172A) : Colors.white;

        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
              children: [
                Text(
                  tr(
                    fr: 'Profil',
                    en: 'Profile',
                    es: 'Perfil',
                    ar: 'الملف الشخصي',
                  ),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: primaryBlue,
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
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        username,
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle(
                  title: tr(
                    fr: 'Navigation',
                    en: 'Navigation',
                    es: 'Navegación',
                    ar: 'التنقل',
                  ),
                  color: titleColor,
                ),
                _ProfileTile(
                  icon: Icons.history_rounded,
                  title: tr(
                    fr: 'Historique',
                    en: 'History',
                    es: 'Historial',
                    ar: 'السجل',
                  ),
                  subtitle: tr(
                    fr: 'Voir les réservations payées déjà passées',
                    en: 'View paid reservations already completed',
                    es: 'Ver las reservas pagadas ya finalizadas',
                    ar: 'عرض الحجوزات المدفوعة والمنتهية',
                  ),
                  cardColor: cardColor,
                  iconBoxColor: iconBoxColor,
                  iconColor: primaryBlue,
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                  trailingColor: subtitleColor,
                  onTap: () {
                    context.push(AppRoutes.history);
                  },
                ),
                const SizedBox(height: 8),
                _SectionTitle(
                  title: tr(
                    fr: 'Préférences',
                    en: 'Preferences',
                    es: 'Preferencias',
                    ar: 'التفضيلات',
                  ),
                  color: titleColor,
                ),
                _SwitchTile(
                  icon: Icons.notifications_none_rounded,
                  title: tr(
                    fr: 'Notifications',
                    en: 'Notifications',
                    es: 'Notificaciones',
                    ar: 'الإشعارات',
                  ),
                  subtitle: tr(
                    fr: 'Recevoir les alertes de réservation',
                    en: 'Receive reservation alerts',
                    es: 'Recibir alertas de reserva',
                    ar: 'تلقي تنبيهات الحجز',
                  ),
                  value: notificationsEnabled,
                  cardColor: cardColor,
                  iconBoxColor: iconBoxColor,
                  iconColor: primaryBlue,
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                  activeColor: primaryBlue,
                  onChanged: (value) async {
                    setState(() {
                      notificationsEnabled = value;
                    });
                    await sauvegarderPreferenceBool(
                      'pref_notifications',
                      value,
                    );
                  },
                ),
                _SwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: tr(
                    fr: 'Mode sombre',
                    en: 'Dark mode',
                    es: 'Modo oscuro',
                    ar: 'الوضع الداكن',
                  ),
                  subtitle: tr(
                    fr: 'Activer le thème sombre dans l’application',
                    en: 'Enable dark theme in the app',
                    es: 'Activar el tema oscuro en la aplicación',
                    ar: 'تفعيل الوضع الداكن في التطبيق',
                  ),
                  value: prefs.isDarkMode,
                  cardColor: cardColor,
                  iconBoxColor: iconBoxColor,
                  iconColor: primaryBlue,
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                  activeColor: primaryBlue,
                  onChanged: (value) async {
                    await prefs.setDarkMode(value);
                  },
                ),
                _DropdownTile<String>(
                  icon: Icons.language_rounded,
                  title: tr(
                    fr: 'Langue',
                    en: 'Language',
                    es: 'Idioma',
                    ar: 'اللغة',
                  ),
                  subtitle: tr(
                    fr: 'Choisissez votre langue préférée',
                    en: 'Choose your preferred language',
                    es: 'Elija su idioma preferido',
                    ar: 'اختر لغتك المفضلة',
                  ),
                  value: prefs.languageCode,
                  items: _languageItems(normalTextColor),
                  cardColor: cardColor,
                  iconBoxColor: iconBoxColor,
                  iconColor: primaryBlue,
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                  fieldFillColor: fieldFillColor,
                  borderColor: borderColor,
                  onChanged: (value) async {
                    if (value == null) return;
                    await prefs.setLanguageCode(value);
                  },
                ),
                _DropdownTile<String>(
                  icon: Icons.location_city_outlined,
                  title: tr(
                    fr: 'Ville de départ favorite',
                    en: 'Favorite departure city',
                    es: 'Ciudad de salida favorita',
                    ar: 'مدينة الانطلاق المفضلة',
                  ),
                  subtitle: tr(
                    fr: 'Ville proposée par défaut',
                    en: 'Default suggested city',
                    es: 'Ciudad sugerida por defecto',
                    ar: 'المدينة المقترحة افتراضيًا',
                  ),
                  value: favoriteDepartureCity,
                  items: ['Lomé', 'Kpalimé', 'Atakpamé', 'Sokodé', 'Kara']
                      .map(
                        (city) => DropdownMenuItem<String>(
                          value: city,
                          child: Text(
                            city,
                            style: TextStyle(color: normalTextColor),
                          ),
                        ),
                      )
                      .toList(),
                  cardColor: cardColor,
                  iconBoxColor: iconBoxColor,
                  iconColor: primaryBlue,
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                  fieldFillColor: fieldFillColor,
                  borderColor: borderColor,
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() {
                      favoriteDepartureCity = value;
                    });
                    await sauvegarderPreferenceString(
                      'pref_departure_city',
                      value,
                    );
                  },
                ),
                _DropdownTile<int>(
                  icon: Icons.event_seat_outlined,
                  title: tr(
                    fr: 'Nombre de sièges par défaut',
                    en: 'Default number of seats',
                    es: 'Número de asientos por defecto',
                    ar: 'عدد المقاعد الافتراضي',
                  ),
                  subtitle: tr(
                    fr: 'Valeur proposée lors d’une réservation',
                    en: 'Suggested value during booking',
                    es: 'Valor sugerido al reservar',
                    ar: 'القيمة المقترحة أثناء الحجز',
                  ),
                  value: defaultSeats,
                  items: [1, 2, 3, 4, 5]
                      .map(
                        (seat) => DropdownMenuItem<int>(
                          value: seat,
                          child: Text(
                            seat.toString(),
                            style: TextStyle(color: normalTextColor),
                          ),
                        ),
                      )
                      .toList(),
                  cardColor: cardColor,
                  iconBoxColor: iconBoxColor,
                  iconColor: primaryBlue,
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                  fieldFillColor: fieldFillColor,
                  borderColor: borderColor,
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() {
                      defaultSeats = value;
                    });
                    await sauvegarderPreferenceInt(
                      'pref_default_seats',
                      value,
                    );
                  },
                ),
                _DropdownTile<String>(
                  icon: Icons.account_balance_wallet_outlined,
                  title: tr(
                    fr: 'Moyen de paiement préféré',
                    en: 'Preferred payment method',
                    es: 'Método de pago preferido',
                    ar: 'طريقة الدفع المفضلة',
                  ),
                  subtitle: tr(
                    fr: 'Option préselectionnée',
                    en: 'Preselected option',
                    es: 'Opción preseleccionada',
                    ar: 'الخيار المحدد مسبقًا',
                  ),
                  value: preferredPayment,
                  items: ['Flooz', 'TMoney']
                      .map(
                        (payment) => DropdownMenuItem<String>(
                          value: payment,
                          child: Text(
                            payment,
                            style: TextStyle(color: normalTextColor),
                          ),
                        ),
                      )
                      .toList(),
                  cardColor: cardColor,
                  iconBoxColor: iconBoxColor,
                  iconColor: primaryBlue,
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                  fieldFillColor: fieldFillColor,
                  borderColor: borderColor,
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() {
                      preferredPayment = value;
                    });
                    await sauvegarderPreferenceString(
                      'pref_payment',
                      value,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _SectionTitle(
                  title: tr(
                    fr: 'Compte',
                    en: 'Account',
                    es: 'Cuenta',
                    ar: 'الحساب',
                  ),
                  color: titleColor,
                ),
                _ProfileTile(
                  icon: Icons.logout_rounded,
                  title: tr(
                    fr: 'Déconnexion',
                    en: 'Log out',
                    es: 'Cerrar sesión',
                    ar: 'تسجيل الخروج',
                  ),
                  subtitle: tr(
                    fr: 'Quitter votre session',
                    en: 'End your session',
                    es: 'Cerrar su sesión',
                    ar: 'إنهاء جلستك',
                  ),
                  cardColor: cardColor,
                  iconBoxColor: iconBoxColor,
                  iconColor: primaryBlue,
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                  trailingColor: subtitleColor,
                  onTap: deconnexion,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionTitle({
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color cardColor;
  final Color iconBoxColor;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color trailingColor;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cardColor,
    required this.iconBoxColor,
    required this.iconColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.trailingColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardColor,
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
                    color: iconBoxColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: trailingColor,
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
  final Color cardColor;
  final Color iconBoxColor;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.cardColor,
    required this.iconBoxColor,
    required this.iconColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: iconBoxColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
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
  final List<DropdownMenuItem<T>> items;
  final Color cardColor;
  final Color iconBoxColor;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color fieldFillColor;
  final Color borderColor;
  final ValueChanged<T?> onChanged;

  const _DropdownTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.items,
    required this.cardColor,
    required this.iconBoxColor,
    required this.iconColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.fieldFillColor,
    required this.borderColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF374151);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: iconBoxColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<T>(
                  value: value,
                  items: items,
                  onChanged: onChanged,
                  dropdownColor: fieldFillColor,
                  iconEnabledColor: subtitleColor,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: fieldFillColor,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF3158F5),
                        width: 1.4,
                      ),
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