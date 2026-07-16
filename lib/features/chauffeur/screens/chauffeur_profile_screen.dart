import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/network/self_service.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/chauffeur/models/chauffeur_trip_model.dart';
import 'package:transia_mobile/features/chauffeur/services/chauffeur_service.dart';
import 'package:transia_mobile/shared/widgets/user_avatar.dart';

class ChauffeurProfileScreen extends StatefulWidget {
  const ChauffeurProfileScreen({super.key});

  @override
  State<ChauffeurProfileScreen> createState() => _ChauffeurProfileScreenState();
}

class _ChauffeurProfileScreenState extends State<ChauffeurProfileScreen> {
  final SecureStorageService storage = SecureStorageService();

  late final ApiClient apiClient;
  late final ChauffeurService chauffeurService;
  late final SelfService selfService;

  bool isLoading = true;
  String fullName = 'Chauffeur';
  String username = '';
  String? photoBase64;
  List<ChauffeurTripModel> allTrips = [];

  @override
  void initState() {
    super.initState();
    apiClient = ApiClient(storage);
    chauffeurService = ChauffeurService(apiClient: apiClient);
    selfService = SelfService(apiClient: apiClient);
    chargerDonnees();
  }

  Future<void> chargerDonnees() async {
    setState(() {
      isLoading = true;
    });

    try {
      final name = await storage.getFullName();
      final phone = await storage.getTelephone();
      final trips = await chauffeurService.getTrips();
      final profil = await selfService.getMyProfil();

      if (!mounted) return;

      setState(() {
        fullName = (name != null && name.trim().isNotEmpty) ? name : 'Chauffeur';
        username = phone ?? '';
        photoBase64 = profil?.photoProfil;
        allTrips = trips;
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

  Future<void> logout() async {
    await storage.clearSession();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  DateTime? _parseTripDate(ChauffeurTripModel trip) {
    try {
      if (trip.dateDepart.trim().isEmpty) return null;
      final hour = trip.heureFormatee.trim().isEmpty ? '00:00' : trip.heureFormatee;
      return DateTime.parse('${trip.dateDepart} $hour:00');
    } catch (_) {
      return null;
    }
  }

  List<ChauffeurTripModel> get historiqueTrips {
    final now = DateTime.now();
    return allTrips.where((trip) {
      final date = _parseTripDate(trip);
      if (date == null) return false;
      return date.isBefore(now);
    }).toList()
      ..sort((a, b) {
        final da = _parseTripDate(a) ?? DateTime(1900);
        final db = _parseTripDate(b) ?? DateTime(1900);
        return db.compareTo(da);
      });
  }

  String get initiales {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'CH';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: chargerDonnees,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
            children: [
              const Text(
                'Profil chauffeur',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    UserAvatar(
                      photoBase64: photoBase64,
                      initiales: initiales,
                      radius: 34,
                      fontSize: 22,
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
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      value: '${allTrips.length}',
                      label: 'Trajets',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      value: '${historiqueTrips.length}',
                      label: 'Effectués',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Historique des voyages',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 12),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (historiqueTrips.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 52,
                        color: Color(0xFF9CA3AF),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Aucun voyage effectué pour le moment',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...historiqueTrips.map(
                  (trip) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _ProfileRow(
                            label: 'Date',
                            value: trip.dateDepart.isEmpty ? '-' : trip.dateDepart,
                          ),
                          _ProfileRow(
                            label: 'Heure',
                            value: trip.heureFormatee.isEmpty ? '-' : trip.heureFormatee,
                          ),
                          _ProfileRow(
                            label: 'Véhicule',
                            value: trip.vehiculeImmatriculation.isEmpty
                                ? '-'
                                : trip.vehiculeImmatriculation,
                          ),
                          _ProfileRow(
                            label: 'Statut',
                            value: trip.statut.isEmpty ? 'TERMINÉ' : trip.statut,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.editProfile),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier mon profil'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: logout,
                  child: const Text('Déconnexion'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({
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

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({
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
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
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