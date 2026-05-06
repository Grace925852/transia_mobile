import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/chauffeur/models/chauffeur_trip_model.dart';
import 'package:transia_mobile/features/chauffeur/services/chauffeur_service.dart';

class ChauffeurHomeScreen extends StatefulWidget {
  const ChauffeurHomeScreen({super.key});

  @override
  State<ChauffeurHomeScreen> createState() => _ChauffeurHomeScreenState();
}

class _ChauffeurHomeScreenState extends State<ChauffeurHomeScreen> {
  late final SecureStorageService secureStorageService;
  late final ApiClient apiClient;
  late final ChauffeurService chauffeurService;

  bool isLoading = true;
  String chauffeurName = 'Chauffeur';
  String chauffeurPhone = '';
  List<ChauffeurTripModel> trips = [];
  Map<String, int> passengerCounts = {};

  @override
  void initState() {
    super.initState();
    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);
    chauffeurService = ChauffeurService(apiClient: apiClient);
    chargerDonnees();
  }

  Future<void> chargerDonnees() async {
    setState(() {
      isLoading = true;
    });

    try {
      final name = await secureStorageService.getFullName();
      final phone = await secureStorageService.getUsername();
      final result = await chauffeurService.getTrips();

      final Map<String, int> counts = {};
      for (final trip in result) {
        counts[trip.id] = await chauffeurService.getPassengerCountForTrip(trip.id);
      }

      if (!mounted) return;

      setState(() {
        chauffeurName =
            (name != null && name.trim().isNotEmpty) ? name : 'Chauffeur';
        chauffeurPhone = phone ?? '';
        trips = result;
        passengerCounts = counts;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
        ),
      );
    }
  }

  String get initiales {
    final parts = chauffeurName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'CH';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final currentTrip = trips.isNotEmpty ? trips.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
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
                          const SizedBox(height: 4),
                          Text(
                            chauffeurPhone,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.16),
                      child: Text(
                        initiales,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                        value: '${trips.length}',
                        label: 'Trajets',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        value: currentTrip == null
                            ? '0'
                            : '${passengerCounts[currentTrip.id] ?? 0}',
                        label: 'Passagers du jour',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: currentTrip == null
                      ? const Column(
                          children: [
                            Icon(
                              Icons.directions_bus_outlined,
                              size: 52,
                              color: Color(0xFF9CA3AF),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Aucun trajet disponible',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Trajet en vedette',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _InfoRow(
                              label: 'Trajet',
                              value: currentTrip.trajetLabel,
                            ),
                            _InfoRow(
                              label: 'Date',
                              value: currentTrip.dateDepart.isEmpty
                                  ? '-'
                                  : currentTrip.dateDepart,
                            ),
                            _InfoRow(
                              label: 'Heure',
                              value: currentTrip.heureFormatee.isEmpty
                                  ? '-'
                                  : currentTrip.heureFormatee,
                            ),
                            _InfoRow(
                              label: 'Véhicule',
                              value: currentTrip.vehiculeImmatriculation.isEmpty
                                  ? '-'
                                  : currentTrip.vehiculeImmatriculation,
                            ),
                            _InfoRow(
                              label: 'Passagers',
                              value:
                                  '${passengerCounts[currentTrip.id] ?? 0}',
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: () {
                                  context.push(
                                    AppRoutes.chauffeurPassengers,
                                    extra: currentTrip,
                                  );
                                },
                                child: const Text('Voir les passagers'),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Tous les trajets',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 12),
                if (trips.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Aucun trajet trouvé.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  )
                else
                  ...trips.map(
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.trajetLabel,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _MiniInfo(
                                icon: Icons.calendar_today_outlined,
                                text: trip.dateDepart.isEmpty
                                    ? '-'
                                    : trip.dateDepart,
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
                              _MiniInfo(
                                icon: Icons.group_outlined,
                                text:
                                    '${passengerCounts[trip.id] ?? 0} passagers',
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
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
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
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
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }
}