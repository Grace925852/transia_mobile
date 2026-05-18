import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/chauffeur/models/chauffeur_trip_model.dart';
import 'package:transia_mobile/features/chauffeur/services/chauffeur_service.dart';

class ChauffeurHistoryScreen extends StatefulWidget {
  const ChauffeurHistoryScreen({super.key});

  @override
  State<ChauffeurHistoryScreen> createState() => _ChauffeurHistoryScreenState();
}

class _ChauffeurHistoryScreenState extends State<ChauffeurHistoryScreen> {
  late final SecureStorageService secureStorageService;
  late final ApiClient apiClient;
  late final ChauffeurService chauffeurService;

  bool isLoading = true;
  List<ChauffeurTripModel> historyTrips = [];

  @override
  void initState() {
    super.initState();
    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);
    chauffeurService = ChauffeurService(apiClient: apiClient);
    loadHistory();
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

  bool _isPastTrip(ChauffeurTripModel trip) {
    final tripDate = _tripDateTime(trip);
    if (tripDate == null) return false;
    return tripDate.isBefore(DateTime.now());
  }

  Future<void> loadHistory() async {
    setState(() => isLoading = true);

    try {
      final trips = await chauffeurService.getTrips();

      trips.sort((a, b) {
        final aDate = _tripDateTime(a) ?? DateTime(1900);
        final bDate = _tripDateTime(b) ?? DateTime(1900);
        return bDate.compareTo(aDate);
      });

      final filtered = trips.where(_isPastTrip).toList();

      if (!mounted) return;
      setState(() {
        historyTrips = filtered;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
        ),
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
          onRefresh: loadHistory,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
            children: [
              Text(
                'Historique des trajets',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Retrouvez ici uniquement les trajets déjà passés.',
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
              else if (historyTrips.isEmpty)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    'Aucun trajet dans l’historique.',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                )
              else
                ...historyTrips.map(
                  (trip) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        context.push(
                          AppRoutes.chauffeurPassengers,
                          extra: trip,
                        );
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
                              text: trip.heureFormatee.isEmpty
                                  ? '-'
                                  : trip.heureFormatee,
                            ),
                            const SizedBox(height: 6),
                            _MiniInfo(
                              icon: Icons.directions_bus_outlined,
                              text: trip.vehiculeImmatriculation.isEmpty
                                  ? '-'
                                  : trip.vehiculeImmatriculation,
                            ),
                            const SizedBox(height: 6),
                            const _MiniInfo(
                              icon: Icons.history_rounded,
                              text: 'Trajet passé',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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