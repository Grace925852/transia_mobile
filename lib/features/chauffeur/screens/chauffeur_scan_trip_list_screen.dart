import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/chauffeur/models/chauffeur_trip_model.dart';
import 'package:transia_mobile/features/chauffeur/services/chauffeur_service.dart';

class ChauffeurScanTripListScreen extends StatefulWidget {
  const ChauffeurScanTripListScreen({super.key});

  @override
  State<ChauffeurScanTripListScreen> createState() =>
      _ChauffeurScanTripListScreenState();
}

class _ChauffeurScanTripListScreenState
    extends State<ChauffeurScanTripListScreen> {
  late final SecureStorageService secureStorageService;
  late final ApiClient apiClient;
  late final ChauffeurService chauffeurService;

  bool isLoading = true;
  List<ChauffeurTripModel> trips = [];

  @override
  void initState() {
    super.initState();
    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);
    chauffeurService = ChauffeurService(apiClient: apiClient);
    loadTrips();
  }

  DateTime? _tripDateTime(ChauffeurTripModel trip) {
    final date = trip.dateDepart.trim();
    final time = trip.heureFormatee.trim();

    if (date.isEmpty) return null;

    try {
      final safeTime = time.isEmpty
          ? '00:00:00'
          : (time.length == 5 ? '$time:00' : time);
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

  Future<void> loadTrips() async {
    setState(() => isLoading = true);

    try {
      final result = await chauffeurService.getTrips();

      result.sort((a, b) {
        final aDate = _tripDateTime(a) ?? DateTime(2100);
        final bDate = _tripDateTime(b) ?? DateTime(2100);
        return aDate.compareTo(bDate);
      });

      final filtered = result.where(_isUpcomingTrip).toList();

      if (!mounted) return;
      setState(() {
        trips = filtered;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadTrips,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
            children: [
              Text(
                'Scan des trajets à venir',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choisissez un trajet à venir pour scanner les QR codes et marquer les clients présents.',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 18),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (trips.isEmpty)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    'Aucun trajet à venir disponible pour le scan.',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                )
              else
                ...trips.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final trip = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          final passengers =
                              await chauffeurService.getPaidPassengersForTrip(trip.id);

                          if (!context.mounted) return;

                          context.push(
                            AppRoutes.chauffeurScan,
                            extra: {
                              'trip': trip,
                              'passengers': passengers,
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: index == 0
                                ? Border.all(
                                    color: const Color(0xFF3158F5),
                                    width: 1.2,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 52,
                                width: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF0FF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: Color(0xFF3158F5),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (index == 0)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEAF0FF),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: const Text(
                                          'Prochain trajet',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF3158F5),
                                          ),
                                        ),
                                      ),
                                    Text(
                                      trip.trajetLabel,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: theme.textTheme.titleMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${trip.dateDepart} • ${trip.heureFormatee}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: theme.textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      trip.vehiculeImmatriculation,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: theme.textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: Color(0xFF9CA3AF),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}