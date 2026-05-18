import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/chauffeur/models/chauffeur_passenger_model.dart';
import 'package:transia_mobile/features/chauffeur/models/chauffeur_trip_model.dart';
import 'package:transia_mobile/features/chauffeur/services/chauffeur_service.dart';

class ChauffeurTripPassengersScreen extends StatefulWidget {
  final ChauffeurTripModel trip;

  const ChauffeurTripPassengersScreen({
    super.key,
    required this.trip,
  });

  @override
  State<ChauffeurTripPassengersScreen> createState() =>
      _ChauffeurTripPassengersScreenState();
}

class _ChauffeurTripPassengersScreenState
    extends State<ChauffeurTripPassengersScreen> {
  late final SecureStorageService secureStorageService;
  late final ApiClient apiClient;
  late final ChauffeurService chauffeurService;

  bool isLoading = true;
  List<ChauffeurPassengerModel> passengers = [];
  bool hasChanged = false;

  int get expectedCount => passengers.length;
  int get presentCount => passengers.where((e) => e.present).length;

  @override
  void initState() {
    super.initState();
    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);
    chauffeurService = ChauffeurService(apiClient: apiClient);
    loadPassengers();
  }

  Future<void> loadPassengers() async {
    setState(() => isLoading = true);

    try {
      final result =
          await chauffeurService.getPaidPassengersForTrip(widget.trip.id);

      if (!mounted) return;
      setState(() {
        passengers = result;
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

  Future<void> markPresent(ChauffeurPassengerModel passenger) async {
    if (passenger.present) return;

    await chauffeurService.markPassengerPresent(
      tripId: widget.trip.id,
      billetId: passenger.billetId,
    );

    setState(() {
      passengers = passengers.map((e) {
        if (e.billetId == passenger.billetId) {
          return e.copyWith(present: true);
        }
        return e;
      }).toList();
      hasChanged = true;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Client marqué présent.')),
    );
  }

  Future<void> openScanScreen() async {
    final result = await context.push(
      AppRoutes.chauffeurScan,
      extra: {
        'trip': widget.trip,
        'passengers': passengers,
      },
    );

    if (!mounted) return;

    if (result is String && result.isNotEmpty) {
      await loadPassengers();
      setState(() {
        hasChanged = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passager marqué présent avec succès.'),
        ),
      );
    }
  }

  Future<void> openReportProblemScreen() async {
    final result = await context.push(
      AppRoutes.chauffeurReportProblem,
      extra: widget.trip,
    );

    if (!mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Problème signalé avec succès.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presentPassengers = passengers.where((e) => e.present).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {
        context.pop(hasChanged);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FF),
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(hasChanged),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          title: const Text('Détail du trajet'),
          actions: [
            IconButton(
              onPressed: openScanScreen,
              icon: const Icon(Icons.qr_code_scanner_rounded),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: loadPassengers,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.trip.trajetLabel,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(label: 'Date', value: widget.trip.dateDepart),
                    _InfoRow(label: 'Heure', value: widget.trip.heureFormatee),
                    _InfoRow(
                      label: 'Véhicule',
                      value: widget.trip.vehiculeImmatriculation,
                    ),
                    _InfoRow(label: 'Clients attendus', value: '$expectedCount'),
                    _InfoRow(label: 'Présents', value: '$presentCount'),
                    _InfoRow(
                      label: 'Restants',
                      value: '${(expectedCount - presentCount).clamp(0, 9999)}',
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: openScanScreen,
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: const Text('Scanner et cocher présent'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: openReportProblemScreen,
                        icon: const Icon(Icons.report_problem_outlined),
                        label: const Text('Signaler un problème'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (passengers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'Aucun passager trouvé pour ce trajet.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                )
              else ...[
                const Text(
                  'Clients déjà présents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 10),
                if (presentPassengers.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'Aucun client présent pour le moment.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  )
                else
                  ...presentPassengers.map(
                    (passenger) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                passenger.passagerNom,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                            Text(
                              passenger.siege,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                const Text(
                  'Clients à marquer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 10),
                ...passengers.map(
                  (passenger) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  passenger.passagerNom,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ),
                              _StatusBadge(
                                text: passenger.present ? 'Présent' : 'En attente',
                                color: passenger.present
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF3158F5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _MiniInfo(
                            icon: Icons.event_seat_outlined,
                            text: 'Siège : ${passenger.siege}',
                          ),
                          const SizedBox(height: 6),
                          _MiniInfo(
                            icon: Icons.badge_outlined,
                            text: 'Billet : ${passenger.billetId}',
                          ),
                          const SizedBox(height: 6),
                          _MiniInfo(
                            icon: Icons.receipt_long_outlined,
                            text: 'Réservation : ${passenger.reservationId}',
                          ),
                          if (passenger.clientResponsable.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _MiniInfo(
                              icon: Icons.person_outline_rounded,
                              text:
                                  'Responsable : ${passenger.clientResponsable}',
                            ),
                          ],
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: passenger.present
                                  ? null
                                  : () => markPresent(passenger),
                              child: Text(
                                passenger.present
                                    ? 'Déjà présent'
                                    : 'Client présent',
                              ),
                            ),
                          ),
                        ],
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
              value.isEmpty ? '-' : value,
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
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
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

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}