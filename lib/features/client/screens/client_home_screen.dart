import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/client/models/trajet_model.dart';
import 'package:transia_mobile/features/client/models/ville_model.dart';
import 'package:transia_mobile/features/client/services/trajet_service.dart';
import 'package:transia_mobile/features/client/services/ville_service.dart';

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
  final Color primaryBlue = const Color(0xFF3158F5);
  final Color backgroundColor = const Color(0xFFF5F7FF);
  final Color textColor = const Color(0xFF374151);

  String? villeDepart;
  String? villeArrivee;
  int nombreSieges = 1;
  bool siegesRapproches = false;
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

  String clientNomConnecte = 'Client';

  @override
  void initState() {
    super.initState();

    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);
    villeService = VilleService(apiClient: apiClient);
    trajetService = TrajetService(apiClient: apiClient);

    chargerNomClient();
    chargerDonnees();
  }

  Future<void> chargerNomClient() async {
    final nom = await secureStorageService.getFullName();

    if (!mounted) return;

    setState(() {
      clientNomConnecte =
          (nom != null && nom.trim().isNotEmpty) ? nom : 'Client';
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
    if (selectedDate == null) return 'jj/mm/aaaa';

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

      if (!mounted) return;

      setState(() {
        villes = villesResult;
        trajets = trajetsResult;
        trajetsAffiches = trajetsResult;
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

  Future<void> choisirDate() async {
    final now = DateTime.now();

    final result = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );

    if (result != null) {
      setState(() {
        selectedDate = result;
      });
    }
  }

  Future<void> rechercherTrajet() async {
    if (villeDepart == null || villeDepart!.trim().isEmpty) {
      afficherMessage('Veuillez choisir ou saisir la ville de départ.');
      return;
    }

    if (villeArrivee == null || villeArrivee!.trim().isEmpty) {
      afficherMessage("Veuillez choisir ou saisir la ville d'arrivée.");
      return;
    }

    if (selectedDate == null) {
      afficherMessage('Veuillez choisir la date de départ.');
      return;
    }

    setState(() {
      isSearching = true;
    });

    try {
      final result = await trajetService.rechercherTrajets(
        villeDepart: villeDepart!,
        villeArrivee: villeArrivee!,
        dateDepart: selectedDate!,
      );

      if (!mounted) return;

      setState(() {
        trajetsAffiches = result;
      });

      if (result.isEmpty) {
        afficherMessage('Aucun trajet disponible pour cette recherche.');
      } else {
        context.push(
          AppRoutes.tripList,
          extra: {
            'trajets': result,
            'villeDepart': villeDepart!,
            'villeArrivee': villeArrivee!,
            'dateDepart': dateText,
            'nombreSieges': nombreSieges,
          },
        );
      }
    } catch (e) {
      afficherMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
      }
    }
  }

  void reinitialiserRecherche() {
    setState(() {
      villeDepart = null;
      villeArrivee = null;
      selectedDate = null;
      nombreSieges = 1;
      siegesRapproches = false;
      trajetsAffiches = trajets;
    });

    afficherMessage('Recherche réinitialisée.');
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
    final content = SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: chargerDonnees,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildTopSection(),
            const SizedBox(height: 24),
            _buildSuggestionsSection(),
            const SizedBox(height: 26),
            _buildTripsSection(),
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
  }

  Widget _buildTopSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 205,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
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
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initialesClient,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 100, 18, 0),
          child: _buildSearchCard(),
        ),
      ],
    );
  }

  Widget _buildSearchCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Rechercher un trajet'),
          const SizedBox(height: 16),
          _label('Ville de départ'),
          const SizedBox(height: 6),
          _SearchableCityField(
            icon: Icons.location_on_outlined,
            hintText: 'Sélectionnez une ville',
            initialValue: villeDepart,
            cities: nomsVilles,
            onChanged: (value) {
              villeDepart = value;
            },
          ),
          const SizedBox(height: 14),
          _label("Ville d'arrivée"),
          const SizedBox(height: 6),
          _SearchableCityField(
            icon: Icons.near_me_outlined,
            hintText: 'Sélectionnez une ville',
            initialValue: villeArrivee,
            cities: nomsVilles,
            onChanged: (value) {
              villeArrivee = value;
            },
          ),
          const SizedBox(height: 14),
          _label('Date de départ'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: choisirDate,
            child: _InputDisplayBox(
              icon: Icons.access_time_rounded,
              text: dateText,
              trailingIcon: Icons.calendar_month_outlined,
            ),
          ),
          const SizedBox(height: 14),
          _label('Nombre de sièges'),
          const SizedBox(height: 6),
          _SeatSelector(
            value: nombreSieges,
            onChanged: (value) {
              setState(() {
                nombreSieges = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: siegesRapproches,
                  activeColor: textColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  onChanged: (value) {
                    setState(() {
                      siegesRapproches = value ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sièges rapprochés (pour groupes)',
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withOpacity(0.78),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSearching ? null : rechercherTrajet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isSearching
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Rechercher',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                width: 52,
                child: OutlinedButton(
                  onPressed: reinitialiserRecherche,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryBlue,
                    side: BorderSide(color: primaryBlue.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Icon(Icons.refresh_rounded, size: 21),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection() {
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
                'Suggestions IA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _SuggestionCard(
            icon: Icons.trending_up_rounded,
            title: 'Itinéraire rapide disponible',
            subtitle: 'Les trajets programmés sont chargés depuis le serveur',
            backgroundColor: Color(0xFFF0FFF4),
            iconColor: Color(0xFF4CAF50),
            titleColor: Color(0xFF45B85A),
            subtitleColor: Color(0xFF6ABD75),
          ),
          const SizedBox(height: 12),
          const _SuggestionCard(
            icon: Icons.access_time_rounded,
            title: 'Actualisation dynamique',
            subtitle: 'Tirez vers le bas pour recharger les trajets',
            backgroundColor: Color(0xFFF0F4FF),
            iconColor: Color(0xFF3158D4),
            titleColor: Color(0xFF3158D4),
            subtitleColor: Color(0xFF6A7FB8),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trajets disponibles (${trajetsAffiches.length})',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 14),
          if (isLoadingData)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (trajetsAffiches.isEmpty)
            _EmptyTrajetCard(
              onRefresh: chargerDonnees,
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

  Widget _title(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  Widget _label(String text) {
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
  final List<String> cities;
  final ValueChanged<String> onChanged;

  const _SearchableCityField({
    required this.icon,
    required this.hintText,
    required this.initialValue,
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

    if (widget.initialValue == null && controller.text.isNotEmpty) {
      controller.clear();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();

        if (query.isEmpty) {
          return widget.cities;
        }

        return widget.cities.where(
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
        textController.text = controller.text;
        textController.selection = TextSelection.fromPosition(
          TextPosition(offset: textController.text.length),
        );

        textController.addListener(() {
          controller.text = textController.text;
          widget.onChanged(textController.text);
        });

        return Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FB),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: TextField(
            controller: textController,
            focusNode: focusNode,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF111827),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.hintText,
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
              ),
              prefixIcon: Icon(
                widget.icon,
                color: const Color(0xFF9CA3AF),
                size: 22,
              ),
              suffixIcon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF9CA3AF),
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
                color: Colors.white,
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
                      style: const TextStyle(fontSize: 14),
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
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF9CA3AF),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF111827),
              ),
            ),
          ),
          if (trailingIcon != null)
            Icon(
              trailingIcon,
              color: const Color(0xFF9CA3AF),
              size: 21,
            ),
        ],
      ),
    );
  }
}

class _SeatSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _SeatSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.groups_2_outlined,
            color: Color(0xFF9CA3AF),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: value,
                isExpanded: true,
                borderRadius: BorderRadius.circular(14),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 25,
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF111827),
                ),
                items: List.generate(10, (index) {
                  final seat = index + 1;
                  return DropdownMenuItem<int>(
                    value: seat,
                    child: Text(
                      seat == 1 ? '1 siège' : '$seat sièges',
                    ),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
              ),
            ),
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
  final VoidCallback onReserve;

  const _TripCard({
    required this.trajet,
    required this.iconColor,
    required this.buttonColor,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 13, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
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
            style: const TextStyle(
              color: Color(0xFF374151),
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
              color: const Color(0xFFF0F2F6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              trajet.statut,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _InfoLine(
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFF4CD964),
            text: trajet.villeDepart,
          ),
          const SizedBox(height: 4),
          _InfoLine(
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFFE5485D),
            text: trajet.villeArrivee,
          ),
          const SizedBox(height: 4),
          _InfoLine(
            icon: Icons.access_time_rounded,
            iconColor: const Color(0xFF6B7280),
            text: trajet.heureFormatee,
          ),
          const SizedBox(height: 4),
          _InfoLine(
            icon: Icons.directions_bus_rounded,
            iconColor: const Color(0xFF6B7280),
            text: trajet.vehiculeImmatriculation.isEmpty
                ? 'Véhicule'
                : trajet.vehiculeImmatriculation,
          ),
          const Spacer(),
          Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
          const SizedBox(height: 8),
          Text(
            trajet.prixFormate,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF374151),
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
              child: const Text(
                'Réserver',
                style: TextStyle(
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

  const _InfoLine({
    required this.icon,
    required this.iconColor,
    required this.text,
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
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyTrajetCard extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyTrajetCard({
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.directions_bus_outlined,
            size: 44,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 12),
          const Text(
            'Aucun trajet disponible',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ajoutez des trajets depuis Postman puis actualisez la page.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Actualiser'),
          ),
        ],
      ),
    );
  }
}