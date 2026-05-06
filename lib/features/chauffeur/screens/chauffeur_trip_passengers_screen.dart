import 'package:flutter/material.dart';
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
  int passengerCount = 0;
  List<ChauffeurPassengerModel> passengers = [];

  @override
  void initState() {
    super.initState();
    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);
    chauffeurService = ChauffeurService(apiClient: apiClient);
    chargerPassagers();
  }

  Future<void> chargerPassagers() async {
    setState(() => isLoading = true);

    try {
      final count =
          await chauffeurService.getPassengerCountForTrip(widget.trip.id);
      final result =
          await chauffeurService.getPassengersForTrip(widget.trip.id);

      if (!mounted) return;
      setState(() {
        passengerCount = count;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF374151)),
        title: const Text(
          'Passagers du trajet',
          style: TextStyle(
            color: Color(0xFF374151),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: chargerPassagers,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: chargerPassagers,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.trip.trajetLabel,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TopRow(label: 'Date', value: widget.trip.dateDepart),
                  _TopRow(label: 'Heure', value: widget.trip.heureFormatee),
                  _TopRow(
                    label: 'Véhicule',
                    value: widget.trip.vehiculeImmatriculation,
                  ),
                  _TopRow(label: 'Réservés', value: '$passengerCount'),
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.groups_rounded,
                      size: 54,
                      color: Color(0xFF9CA3AF),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Aucun passager trouvé',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...passengers.map(
                (passenger) => Padding(
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
                          passenger.nomPassager,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _PassengerRow(
                          label: 'Responsable',
                          value: passenger.responsable,
                        ),
                        _PassengerRow(
                          label: 'Statut',
                          value: passenger.statut,
                        ),
                        _PassengerRow(
                          label: 'Réservation',
                          value: passenger.reservationId,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  final String label;
  final String value;

  const _TopRow({
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
              value.isEmpty ? '-' : value,
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

class _PassengerRow extends StatelessWidget {
  final String label;
  final String value;

  const _PassengerRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}