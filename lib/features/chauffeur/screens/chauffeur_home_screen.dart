import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/network/self_service.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/chauffeur/models/chauffeur_trip_model.dart';
import 'package:transia_mobile/features/chauffeur/services/chauffeur_service.dart';
import 'package:transia_mobile/shared/widgets/user_avatar.dart';

class ChauffeurHomeScreen extends StatefulWidget {
  const ChauffeurHomeScreen({super.key});

  @override
  State<ChauffeurHomeScreen> createState() => _ChauffeurHomeScreenState();
}

class _ChauffeurHomeScreenState extends State<ChauffeurHomeScreen> {
  late final SecureStorageService secureStorageService;
  late final ApiClient apiClient;
  late final ChauffeurService chauffeurService;
  late final SelfService selfService;

  bool isLoading = true;
  String chauffeurName = 'Chauffeur';
  String chauffeurPhone = '';
  String? photoBase64;

  List<ChauffeurTripModel> allTrips = [];
  List<ChauffeurTripModel> upcomingTrips = [];

  Map<String, int> passengerCounts = {};
  Map<String, int> presentCounts = {};

  @override
  void initState() {
    super.initState();
    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);
    chauffeurService = ChauffeurService(apiClient: apiClient);
    selfService = SelfService(apiClient: apiClient);
    chargerDonnees();
  }

  DateTime? _tripDateTime(ChauffeurTripModel trip) {
    final date = trip.dateDepart.trim();
    final time = trip.heureFormatee.trim();

    if (date.isEmpty) return null;

    try {
      final safeTime = time.isEmpty ? '00:00:00' : (time.length == 5 ? '$time:00' : time);
      return DateTime.parse('${date}T$safeTime');
    } catch (_) {
      return null;
    }
  }

  bool _isUpcomingTrip(ChauffeurTripModel trip) {
    final tripDate = _tripDateTime(trip);
    if (tripDate == null) return true;
    return !tripDate.isBefore(DateTime.now());
  }

  Future<void> chargerDonnees() async {
    setState(() {
      isLoading = true;
    });

    try {
      final name = await secureStorageService.getFullName();
      final phone = await secureStorageService.getTelephone();
      final result = await chauffeurService.getTrips();
      final profil = await selfService.getMyProfil();

      result.sort((a, b) {
        final aDate = _tripDateTime(a) ?? DateTime(2100);
        final bDate = _tripDateTime(b) ?? DateTime(2100);
        return aDate.compareTo(bDate);
      });

      final filteredUpcoming = result.where(_isUpcomingTrip).toList();

      final Map<String, int> counts = {};
      final Map<String, int> presents = {};

      for (final trip in filteredUpcoming) {
        counts[trip.id] = await chauffeurService.getPassengerCountForTrip(trip.id);
        presents[trip.id] = await chauffeurService.getPresentCountForTrip(trip.id);
      }

      if (!mounted) return;

      setState(() {
        final cleanName = name?.trim() ?? '';
        final cleanPhone = phone?.trim() ?? '';

        chauffeurName = cleanName.isNotEmpty ? cleanName : (cleanPhone.isNotEmpty ? cleanPhone : 'Chauffeur');
        chauffeurPhone = cleanPhone;
        photoBase64 = profil?.photoProfil;
        allTrips = result;
        upcomingTrips = filteredUpcoming;
        passengerCounts = counts;
        presentCounts = presents;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
        ),
      );
    }
  }

  String get initiales {
    final clean = chauffeurName.trim();
    if (clean.isEmpty || clean == 'Chauffeur') return 'CH';

    final parts = clean.split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'CH';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : 'CH';
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextTrip = upcomingTrips.isNotEmpty ? upcomingTrips.first : null;
    final nextExpected = nextTrip == null ? 0 : (passengerCounts[nextTrip.id] ?? 0);
    final nextPresent = nextTrip == null ? 0 : (presentCounts[nextTrip.id] ?? 0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: chargerDonnees,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF3158F5),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Espace Chauffeur',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            chauffeurName,
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (chauffeurPhone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              chauffeurPhone,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    UserAvatar(
                      photoBase64: photoBase64,
                      initiales: initiales,
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.16),
                      fontSize: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: '${upcomingTrips.length}',
                        label: 'À venir',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        value: '$nextExpected',
                        label: 'Clients attendus',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        value: '$nextPresent',
                        label: 'Présents',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: nextTrip == null
                      ? Column(
                          children: [
                            Icon(
                              Icons.directions_bus_outlined,
                              size: 52,
                              color: theme.disabledColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Aucun trajet à venir',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prochain trajet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _InfoRow(label: 'Trajet', value: nextTrip.trajetLabel),
                            _InfoRow(label: 'Date', value: nextTrip.dateDepart.isEmpty ? '-' : nextTrip.dateDepart),
                            _InfoRow(label: 'Heure', value: nextTrip.heureFormatee.isEmpty ? '-' : nextTrip.heureFormatee),
                            _InfoRow(
                              label: 'Véhicule',
                              value: nextTrip.vehiculeImmatriculation.isEmpty ? '-' : nextTrip.vehiculeImmatriculation,
                            ),
                            _InfoRow(label: 'Clients attendus', value: '$nextExpected'),
                            _InfoRow(label: 'Présents', value: '$nextPresent'),
                            _InfoRow(
                              label: 'Restants',
                              value: '${(nextExpected - nextPresent).clamp(0, 9999)}',
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final result = await context.push(
                                          AppRoutes.chauffeurPassengers,
                                          extra: nextTrip,
                                        );

                                        if (!mounted) return;

                                        if (result == true) {
                                          await chargerDonnees();
                                        }
                                      },
                                      child: const Text('Voir le trajet'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 52,
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        final passengers =
                                            await chauffeurService.getPaidPassengersForTrip(nextTrip.id);

                                        if (!context.mounted) return;

                                        final result = await context.push(
                                          AppRoutes.chauffeurScan,
                                          extra: {
                                            'trip': nextTrip,
                                            'passengers': passengers,
                                          },
                                        );

                                        if (!mounted) return;

                                        if (result is String && result.isNotEmpty) {
                                          await chargerDonnees();
                                        }
                                      },
                                      child: const Text('Scanner'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Trajets à venir',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 12),
                if (upcomingTrips.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      'Aucun trajet à venir.',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  )
                else
                  ...upcomingTrips.map(
                    (trip) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          final result = await context.push(
                            AppRoutes.chauffeurPassengers,
                            extra: trip,
                          );

                          if (!mounted) return;

                          if (result == true) {
                            await chargerDonnees();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.trajetLabel,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textTheme.titleMedium?.color,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _MiniInfo(
                                icon: Icons.calendar_today_outlined,
                                text: trip.dateDepart.isEmpty ? '-' : trip.dateDepart,
                              ),
                              const SizedBox(height: 6),
                              _MiniInfo(
                                icon: Icons.access_time_outlined,
                                text: trip.heureFormatee.isEmpty ? '-' : trip.heureFormatee,
                              ),
                              const SizedBox(height: 6),
                              _MiniInfo(
                                icon: Icons.directions_bus_outlined,
                                text: trip.vehiculeImmatriculation.isEmpty ? '-' : trip.vehiculeImmatriculation,
                              ),
                              const SizedBox(height: 6),
                              _MiniInfo(
                                icon: Icons.groups_outlined,
                                text: '${passengerCounts[trip.id] ?? 0} clients attendus',
                              ),
                              const SizedBox(height: 6),
                              _MiniInfo(
                                icon: Icons.verified_user_outlined,
                                text: '${presentCounts[trip.id] ?? 0} présents',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3158F5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniInfo({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.disabledColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ],
    );
  }
}