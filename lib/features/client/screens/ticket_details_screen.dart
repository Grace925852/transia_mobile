import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:transia_mobile/features/client/models/reservation_model.dart';

class TicketDetailsScreen extends StatelessWidget {
  final ReservationModel reservation;

  const TicketDetailsScreen({
    super.key,
    required this.reservation,
  });

  List<String> _extractPassengerNames() {
    final rawBillets = reservation.rawData['billets'];

    if (rawBillets is List) {
      return rawBillets
          .whereType<Map>()
          .map((e) => (e['nomPassager'] ?? '').toString().trim())
          .where((name) => name.isNotEmpty)
          .toList();
    }

    return [];
  }

  String _buildReservationQrData() {
    final passengers = _extractPassengerNames();

    final passengerBlock = passengers.isEmpty
        ? reservation.clientNom
        : passengers.join(', ');

    return [
      'RESERVATION_ID:${reservation.id}',
      'TRAJET:${reservation.villeDepart}-${reservation.villeArrivee}',
      'DATE:${reservation.dateDepart}',
      'HEURE:${reservation.heureFormatee}',
      'RESPONSABLE:${reservation.clientNom}',
      'PASSAGERS:$passengerBlock',
      'NB_PLACES:${reservation.nombrePlace}',
      'STATUT:${reservation.statut}',
    ].join('|');
  }

  @override
  Widget build(BuildContext context) {
    final passengers = _extractPassengerNames();
    final qrData = _buildReservationQrData();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF374151)),
        title: const Text(
          'Mon billet',
          style: TextStyle(
            color: Color(0xFF374151),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text(
                  'Billet de réservation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 220,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Scanner ce QR pour voir toute la réservation',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Détails du trajet',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 16),
                _TicketRow(
                  label: 'Trajet',
                  value: reservation.trajetLabel,
                ),
                _TicketRow(
                  label: 'Date',
                  value: reservation.dateDepart.isEmpty
                      ? '-'
                      : reservation.dateDepart,
                ),
                _TicketRow(
                  label: 'Heure',
                  value: reservation.heureFormatee.isEmpty
                      ? '-'
                      : reservation.heureFormatee,
                ),
                _TicketRow(
                  label: 'Véhicule',
                  value: reservation.vehiculeImmatriculation.isEmpty
                      ? '-'
                      : reservation.vehiculeImmatriculation,
                ),
                _TicketRow(
                  label: 'Responsable',
                  value: reservation.clientNom,
                ),
                _TicketRow(
                  label: 'Nombre de places',
                  value: '${reservation.nombrePlace}',
                ),
                _TicketRow(
                  label: 'Montant',
                  value: reservation.prixFormate,
                  highlighted: true,
                ),
                _TicketRow(
                  label: 'Statut',
                  value: reservation.statut,
                  highlighted: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Liste des passagers',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 14),
                if (passengers.isEmpty)
                  Text(
                    reservation.clientNom,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  ...List.generate(
                    passengers.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            height: 28,
                            width: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3158F5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              passengers[index],
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF374151),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SelectableText(
              qrData,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;

  const _TicketRow({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
                color: highlighted
                    ? const Color(0xFF3158F5)
                    : const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}