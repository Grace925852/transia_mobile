import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/network/self_service.dart';
import 'package:transia_mobile/core/settings/app_preferences_controller.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/client/models/trajet_model.dart';
import 'package:transia_mobile/features/client/models/ville_model.dart';
import 'package:transia_mobile/features/client/services/trajet_service.dart';
import 'package:transia_mobile/features/client/services/ville_service.dart';
import 'package:transia_mobile/shared/widgets/user_avatar.dart';

class ClientHomeScreen extends StatefulWidget {
  final bool showScaffold;

  const ClientHomeScreen({
    super.key,
    this.showScaffold = true,
  });

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  String? villeDepart;
  String? villeArrivee;
  DateTime? selectedDate;

  List<VilleModel> villes = [];
  List<TrajetModel> trajets = [];
  List<TrajetModel> trajetsAffiches = [];

  bool isLoadingData = true;
  bool isSearching = false;

  late final SecureStorageService secureStorageService;
  late final ApiClient apiClient;
  late final VilleService villeService;
  late final TrajetService trajetService;
  late final SelfService selfService;

  String clientNomConnecte = 'Client';
  String? clientPhotoBase64;

  AppPreferencesController get prefs => AppPreferencesController.instance;

  @override
  void initState() {
    super.initState();

    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);
    villeService = VilleService(apiClient: apiClient);
    trajetService = TrajetService(apiClient: apiClient);
    selfService = SelfService(apiClient: apiClient);

    chargerNomClient();
    chargerDonnees();
  }

  String tr({
    required String fr,
    required String en,
    required String es,
    required String ar,
  }) {
    return prefs.tr(fr: fr, en: en, es: es, ar: ar);
  }

  Future<void> chargerNomClient() async {
    final nom = await secureStorageService.getFullName();
    final profil = await selfService.getMyProfil();

    if (!mounted) return;

    setState(() {
      clientNomConnecte =
          (nom != null && nom.trim().isNotEmpty)
              ? nom
              : tr(
                  fr: 'Client',
                  en: 'Client',
                  es: 'Cliente',
                  ar: 'العميل',
                );
      clientPhotoBase64 = profil?.photoProfil;
    });
  }

  String get initialesClient {
    final parts = clientNomConnecte.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'CL';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  String get dateText {
    if (selectedDate == null) {
      return tr(
        fr: 'jj/mm/aaaa',
        en: 'dd/mm/yyyy',
        es: 'dd/mm/aaaa',
        ar: 'يوم/شهر/سنة',
      );
    }

    final day = selectedDate!.day.toString().padLeft(2, '0');
    final month = selectedDate!.month.toString().padLeft(2, '0');
    final year = selectedDate!.year.toString();

    return '$day/$month/$year';
  }

  Future<void> chargerDonnees() async {
    setState(() {
      isLoadingData = true;
    });

    try {
      final villesResult = await villeService.getVilles();
      final trajetsResult = await trajetService.getTrajets();

      final futurs = trajetsResult.where(_isUpcomingTrajet).toList();

      if (!mounted) return;

      setState(() {
        villes = villesResult;
        trajets = futurs;
        trajetsAffiches = futurs;
        isLoadingData = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingData = false;
      });

      afficherMessage(e.toString().replaceAll('Exception: ', ''));
    }
  }

  DateTime _todayOnly() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> choisirDate() async {
    final today = _todayOnly();

    final result = await showDatePicker(
      context: context,
      initialDate:
          selectedDate != null && !selectedDate!.isBefore(today)
              ? selectedDate!
              : today,
      firstDate: today,
      lastDate: DateTime(today.year + 2),
    );

    if (result != null) {
      setState(() {
        selectedDate = result;
      });
      await appliquerFiltres();
    }
  }

  DateTime? _parseTrajetDateTime(TrajetModel trajet) {
    try {
      final rawDate = trajet.dateDepart.trim();
      final rawTime =
          trajet.heureFormatee.trim().isEmpty
              ? '00:00'
              : trajet.heureFormatee.trim();

      int year;
      int month;
      int day;

      if (rawDate.contains('-')) {
        final parts = rawDate.split('-');
        if (parts.length != 3) return null;
        year = int.parse(parts[0]);
        month = int.parse(parts[1]);
        day = int.parse(parts[2]);
      } else if (rawDate.contains('/')) {
        final parts = rawDate.split('/');
        if (parts.length != 3) return null;
        day = int.parse(parts[0]);
        month = int.parse(parts[1]);
        year = int.parse(parts[2]);
      } else {
        return null;
      }

      final timeParts = rawTime.split(':');
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute =
          timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  bool _isUpcomingTrajet(TrajetModel trajet) {
    final dt = _parseTrajetDateTime(trajet);
    if (dt == null) return true;
    return dt.isAfter(DateTime.now());
  }

  Future<void> appliquerFiltres() async {
    final depart = villeDepart?.trim().toLowerCase() ?? '';
    final arrivee = villeArrivee?.trim().toLowerCase() ?? '';

    if (depart.isEmpty && arrivee.isEmpty && selectedDate == null) {
      setState(() {
        trajetsAffiches = trajets.where(_isUpcomingTrajet).toList();
      });
      return;
    }

    if (depart.isNotEmpty && arrivee.isNotEmpty && depart == arrivee) {
      setState(() {
        trajetsAffiches = [];
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    try {
      final filtered = trajets.where((trajet) {
        final matchDepart =
            depart.isEmpty
                ? true
                : trajet.villeDepart.trim().toLowerCase().contains(depart);

        final matchArrivee =
            arrivee.isEmpty
                ? true
                : trajet.villeArrivee.trim().toLowerCase().contains(arrivee);

        final matchDate =
            selectedDate == null ? true : _sameDate(trajet.dateDepart, selectedDate!);

        final differentCities =
            trajet.villeDepart.trim().toLowerCase() !=
            trajet.villeArrivee.trim().toLowerCase();

        final upcoming = _isUpcomingTrajet(trajet);

        return matchDepart &&
            matchArrivee &&
            matchDate &&
            differentCities &&
            upcoming;
      }).toList();

      if (!mounted) return;

      setState(() {
        trajetsAffiches = filtered;
      });
    } catch (e) {
      if (!mounted) return;
      afficherMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
      }
    }
  }

  bool _sameDate(String rawDate, DateTime selected) {
    final day = selected.day.toString().padLeft(2, '0');
    final month = selected.month.toString().padLeft(2, '0');
    final year = selected.year.toString();

    final formats = ['$day/$month/$year', '$year-$month-$day'];

    return formats.contains(rawDate.trim());
  }

  void reinitialiserRecherche() {
    setState(() {
      villeDepart = null;
      villeArrivee = null;
      selectedDate = null;
      trajetsAffiches = trajets.where(_isUpcomingTrajet).toList();
    });

    afficherMessage(
      tr(
        fr: 'Filtres réinitialisés.',
        en: 'Filters reset.',
        es: 'Filtros reiniciados.',
        ar: 'تمت إعادة تعيين الفلاتر.',
      ),
    );
  }

  Future<void> _setVilleDepart(String value) async {
    final cleaned = value.trim();

    if (cleaned.isEmpty) {
      setState(() {
        villeDepart = null;
      });
      await appliquerFiltres();
      return;
    }

    if (villeArrivee != null &&
        villeArrivee!.trim().toLowerCase() == cleaned.toLowerCase()) {
      afficherMessage(
        tr(
          fr: "La ville de départ doit être différente de la ville d'arrivée.",
          en: 'Departure city must be different from arrival city.',
          es: 'La ciudad de salida debe ser diferente de la de llegada.',
          ar: 'يجب أن تكون مدينة الانطلاق مختلفة عن مدينة الوصول.',
        ),
      );
      return;
    }

    setState(() {
      villeDepart = cleaned;
    });

    await appliquerFiltres();
  }

  Future<void> _setVilleArrivee(String value) async {
    final cleaned = value.trim();

    if (cleaned.isEmpty) {
      setState(() {
        villeArrivee = null;
      });
      await appliquerFiltres();
      return;
    }

    if (villeDepart != null &&
        villeDepart!.trim().toLowerCase() == cleaned.toLowerCase()) {
      afficherMessage(
        tr(
          fr: "La ville d'arrivée doit être différente de la ville de départ.",
          en: 'Arrival city must be different from departure city.',
          es: 'La ciudad de llegada debe ser diferente de la de salida.',
          ar: 'يجب أن تكون مدينة الوصول مختلفة عن مدينة الانطلاق.',
        ),
      );
      return;
    }

    setState(() {
      villeArrivee = cleaned;
    });

    await appliquerFiltres();
  }

  void afficherMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<String> get nomsVilles {
    return villes.map((ville) => ville.nomVille).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: prefs,
      builder: (context, _) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final primaryBlue = const Color(0xFF3158F5);
        final backgroundColor = theme.scaffoldBackgroundColor;
        final textColor =
            theme.textTheme.bodyLarge?.color ??
            (isDark ? Colors.white : const Color(0xFF374151));

        final content = SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: chargerDonnees,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildTopSection(primaryBlue, textColor, isDark),
                const SizedBox(height: 24),
                _buildSuggestionsSection(primaryBlue, textColor, isDark),
                const SizedBox(height: 26),
                _buildTripsSection(primaryBlue, textColor, isDark),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );

        if (!widget.showScaffold) {
          return Container(
            color: backgroundColor,
            child: content,
          );
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          body: content,
        );
      },
    );
  }

  Widget _buildTopSection(Color primaryBlue, Color textColor, bool isDark) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 205,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [
                      Color(0xFF0F172A),
                      Color(0xFF081225),
                    ]
                  : [
                      primaryBlue,
                      const Color(0xFF1F3EDB),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  clientNomConnecte,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              UserAvatar(
                photoBase64: clientPhotoBase64,
                initiales: initialesClient,
                radius: 26,
                backgroundColor: Colors.white.withOpacity(0.20),
                fontSize: 16,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 100, 18, 0),
          child: _buildSearchCard(primaryBlue, textColor, isDark),
        ),
      ],
    );
  }

  Widget _buildSearchCard(Color primaryBlue, Color textColor, bool isDark) {
    final cardColor = Theme.of(context).cardColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(
            tr(
              fr: 'Rechercher un trajet',
              en: 'Search for a trip',
              es: 'Buscar un trayecto',
              ar: 'البحث عن رحلة',
            ),
            textColor,
          ),
          const SizedBox(height: 16),
          _label(
            tr(
              fr: 'Ville de départ',
              en: 'Departure city',
              es: 'Ciudad de salida',
              ar: 'مدينة الانطلاق',
            ),
            textColor,
          ),
          const SizedBox(height: 6),
          _SearchableCityField(
            icon: Icons.location_on_outlined,
            hintText: tr(
              fr: 'Sélectionnez une ville',
              en: 'Select a city',
              es: 'Seleccione una ciudad',
              ar: 'اختر مدينة',
            ),
            initialValue: villeDepart,
            excludedValue: villeArrivee,
            cities: nomsVilles,
            onChanged: (value) async {
              await _setVilleDepart(value);
            },
          ),
          const SizedBox(height: 14),
          _label(
            tr(
              fr: "Ville d'arrivée",
              en: 'Arrival city',
              es: 'Ciudad de llegada',
              ar: 'مدينة الوصول',
            ),
            textColor,
          ),
          const SizedBox(height: 6),
          _SearchableCityField(
            icon: Icons.near_me_outlined,
            hintText: tr(
              fr: 'Sélectionnez une ville',
              en: 'Select a city',
              es: 'Seleccione una ciudad',
              ar: 'اختر مدينة',
            ),
            initialValue: villeArrivee,
            excludedValue: villeDepart,
            cities: nomsVilles,
            onChanged: (value) async {
              await _setVilleArrivee(value);
            },
          ),
          const SizedBox(height: 14),
          _label(
            tr(
              fr: 'Date de départ',
              en: 'Departure date',
              es: 'Fecha de salida',
              ar: 'تاريخ الانطلاق',
            ),
            textColor,
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: choisirDate,
            child: _InputDisplayBox(
              icon: Icons.access_time_rounded,
              text: dateText,
              trailingIcon: Icons.calendar_month_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection(
    Color primaryBlue,
    Color textColor,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: primaryBlue,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                tr(
                  fr: 'Suggestions IA',
                  en: 'AI Suggestions',
                  es: 'Sugerencias IA',
                  ar: 'اقتراحات الذكاء الاصطناعي',
                ),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SuggestionCard(
            icon: Icons.access_time_rounded,
            title: tr(
              fr: 'Actualisation dynamique',
              en: 'Dynamic refresh',
              es: 'Actualización dinámica',
              ar: 'تحديث ديناميكي',
            ),
            subtitle: tr(
              fr: 'Tirez vers le bas pour recharger les trajets',
              en: 'Pull down to refresh trips',
              es: 'Deslice hacia abajo para recargar los trayectos',
              ar: 'اسحب للأسفل لتحديث الرحلات',
            ),
            backgroundColor:
                isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F4FF),
            iconColor: primaryBlue,
            titleColor: primaryBlue,
            subtitleColor:
                isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6A7FB8),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsSection(Color primaryBlue, Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${tr(
              fr: 'Trajets disponibles',
              en: 'Available trips',
              es: 'Trayectos disponibles',
              ar: 'الرحلات المتاحة',
            )} (${trajetsAffiches.length})',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 14),
          if (isLoadingData || isSearching)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (trajetsAffiches.isEmpty)
            _EmptyTrajetCard(
              title: tr(
                fr: 'Aucun trajet disponible',
                en: 'No trip available',
                es: 'Ningún trayecto disponible',
                ar: 'لا توجد رحلات متاحة',
              ),
              subtitle: tr(
                fr: 'Ajustez les filtres ou réinitialisez la page.',
                en: 'Adjust filters or reset the page.',
                es: 'Ajuste los filtros o reinicie la página.',
                ar: 'عدّل الفلاتر أو أعد ضبط الصفحة.',
              ),
              resetLabel: tr(
                fr: 'Réinitialiser',
                en: 'Reset',
                es: 'Restablecer',
                ar: 'إعادة التعيين',
              ),
              onReset: reinitialiserRecherche,
            )
          else
            GridView.builder(
              itemCount: trajetsAffiches.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.50,
              ),
              itemBuilder: (context, index) {
                final trajet = trajetsAffiches[index];

                return _TripCard(
                  trajet: trajet,
                  iconColor: _getTripColor(index),
                  buttonColor: primaryBlue,
                  reserveLabel: tr(
                    fr: 'Réserver',
                    en: 'Book',
                    es: 'Reservar',
                    ar: 'احجز',
                  ),
                  vehicleLabel: tr(
                    fr: 'Véhicule',
                    en: 'Vehicle',
                    es: 'Vehículo',
                    ar: 'مركبة',
                  ),
                  onReserve: () {
                    context.push(
                      AppRoutes.tripDetail,
                      extra: trajet,
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Color _getTripColor(int index) {
    final colors = [
      const Color(0xFF4CD964),
      const Color(0xFF9B2FF3),
      const Color(0xFFE86D10),
      const Color(0xFF3B82F6),
      const Color(0xFFEF4444),
    ];

    return colors[index % colors.length];
  }

  Widget _title(String text, Color textColor) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  Widget _label(String text, Color textColor) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: textColor.withOpacity(0.75),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _SearchableCityField extends StatefulWidget {
  final IconData icon;
  final String hintText;
  final String? initialValue;
  final String? excludedValue;
  final List<String> cities;
  final ValueChanged<String> onChanged;

  const _SearchableCityField({
    required this.icon,
    required this.hintText,
    required this.initialValue,
    required this.excludedValue,
    required this.cities,
    required this.onChanged,
  });

  @override
  State<_SearchableCityField> createState() => _SearchableCityFieldState();
}

class _SearchableCityFieldState extends State<_SearchableCityField> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void didUpdateWidget(covariant _SearchableCityField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if ((widget.initialValue ?? '') != controller.text) {
      controller.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor =
        isDark ? const Color(0xFF111827) : const Color(0xFFF6F7FB);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final hintColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF);
    final popupColor = Theme.of(context).cardColor;

    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        final excluded = widget.excludedValue?.trim().toLowerCase() ?? '';

        final baseCities = widget.cities.where((city) {
          return excluded.isEmpty || city.toLowerCase() != excluded;
        });

        if (query.isEmpty) {
          return baseCities;
        }

        return baseCities.where(
          (city) => city.toLowerCase().contains(query),
        );
      },
      onSelected: (value) {
        controller.text = value;
        widget.onChanged(value);
      },
      fieldViewBuilder: (
        context,
        textController,
        focusNode,
        onFieldSubmitted,
      ) {
        if (textController.text != controller.text) {
          textController.text = controller.text;
          textController.selection = TextSelection.fromPosition(
            TextPosition(offset: textController.text.length),
          );
        }

        return Container(
          height: 52,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: TextField(
            controller: textController,
            focusNode: focusNode,
            onChanged: widget.onChanged,
            style: TextStyle(
              fontSize: 15,
              color: textColor,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.hintText,
              hintStyle: TextStyle(
                fontSize: 14,
                color: hintColor,
              ),
              prefixIcon: Icon(
                widget.icon,
                color: hintColor,
                size: 22,
              ),
              suffixIcon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: hintColor,
                size: 25,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 14,
              ),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: MediaQuery.of(context).size.width - 72,
              constraints: const BoxConstraints(maxHeight: 210),
              decoration: BoxDecoration(
                color: popupColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);

                  return ListTile(
                    dense: true,
                    title: Text(
                      option,
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InputDisplayBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final IconData? trailingIcon;

  const _InputDisplayBox({
    required this.icon,
    required this.text,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor =
        isDark ? const Color(0xFF111827) : const Color(0xFFF6F7FB);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final hintColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF);

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: hintColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: textColor,
              ),
            ),
          ),
          if (trailingIcon != null)
            Icon(
              trailingIcon,
              color: hintColor,
              size: 21,
            ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;

  const _SuggestionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.iconColor,
    required this.titleColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                    height: 1.25,
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

class _TripCard extends StatelessWidget {
  final TrajetModel trajet;
  final Color iconColor;
  final Color buttonColor;
  final String reserveLabel;
  final String vehicleLabel;
  final VoidCallback onReserve;

  const _TripCard({
    required this.trajet,
    required this.iconColor,
    required this.buttonColor,
    required this.reserveLabel,
    required this.vehicleLabel,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final titleColor = isDark ? Colors.white : const Color(0xFF374151);
    final subtitleColor =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280);
    final chipColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F2F6);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 13, 12, 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_bus_filled_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${trajet.villeDepart} → ${trajet.villeArrivee}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              trajet.statut,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _InfoLine(
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFF4CD964),
            text: trajet.villeDepart,
            textColor: subtitleColor,
          ),
          const SizedBox(height: 4),
          _InfoLine(
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFFE5485D),
            text: trajet.villeArrivee,
            textColor: subtitleColor,
          ),
          const SizedBox(height: 4),
          _InfoLine(
            icon: Icons.access_time_rounded,
            iconColor: subtitleColor,
            text: trajet.heureFormatee,
            textColor: subtitleColor,
          ),
          const SizedBox(height: 4),
          _InfoLine(
            icon: Icons.directions_bus_rounded,
            iconColor: subtitleColor,
            text: trajet.vehiculeImmatriculation.isEmpty
                ? vehicleLabel
                : trajet.vehiculeImmatriculation,
            textColor: subtitleColor,
          ),
          const Spacer(),
          Container(
            height: 1,
            color: borderColor,
          ),
          const SizedBox(height: 8),
          Text(
            trajet.prixFormate,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: onReserve,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: Text(
                reserveLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final Color textColor;

  const _InfoLine({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 14,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyTrajetCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String resetLabel;
  final VoidCallback onReset;

  const _EmptyTrajetCard({
    required this.title,
    required this.subtitle,
    required this.resetLabel,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final titleColor = isDark ? Colors.white : const Color(0xFF374151);
    final subtitleColor =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 44,
            color: subtitleColor,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(resetLabel),
          ),
        ],
      ),
    );
  }
}