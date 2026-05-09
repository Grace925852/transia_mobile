import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:transia_mobile/features/client/models/reservation_model.dart';

class TicketDetailsScreen extends StatelessWidget {
  final ReservationModel reservation;

  const TicketDetailsScreen({
    super.key,
    required this.reservation,
  });

  String _safe(String? value, {String fallback = '-'}) {
    final v = value?.trim() ?? '';
    return v.isEmpty ? fallback : v;
  }

  List<Map<String, dynamic>> _extractBillets() {
    final raw = reservation.rawData;

    final dynamic billetsData =
        raw['billets'] ??
        raw['tickets'] ??
        raw['billetEntities'] ??
        raw['reservationBillets'];

    if (billetsData is List) {
      return billetsData
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    return [];
  }

  List<int> _extractSeatNumbers() {
    final raw = reservation.rawData;
    final billets = _extractBillets();
    final Set<int> seats = {};

    void addSeat(dynamic value) {
      if (value is int) {
        seats.add(value);
      } else if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) {
          seats.add(parsed);
        }
      }
    }

    for (final billet in billets) {
      addSeat(billet['numeroSiege']);
      addSeat(billet['numero_siege']);
      addSeat(billet['seatNumber']);
      addSeat(billet['siege']);
    }

    final extraLists = [
      raw['numerosSieges'],
      raw['selectedSeats'],
      raw['seatNumbers'],
    ];

    for (final data in extraLists) {
      if (data is List) {
        for (final item in data) {
          addSeat(item);
        }
      }
    }

    return seats.toList()..sort();
  }

  List<String> _extractPassengerNames() {
    final billets = _extractBillets();

    if (billets.isEmpty) return [];

    return billets.map((billet) {
      return (billet['nomPassager'] ??
              billet['nom_passager'] ??
              billet['passagerNom'] ??
              billet['nom'] ??
              '')
          .toString()
          .trim();
    }).toList();
  }

  List<String> _buildPassengerDisplayList() {
    final responsible = _safe(
      reservation.clientNom,
      fallback: 'Responsable',
    );

    if (reservation.nombrePlace <= 1) {
      return [responsible];
    }

    final rawPassengers = _extractPassengerNames();
    final List<String> result = [responsible];
    int inviteCounter = 1;

    for (int index = 1; index < reservation.nombrePlace; index++) {
      final rawValue = index < rawPassengers.length
          ? rawPassengers[index].trim()
          : '';

      final normalizedResponsible = responsible.toLowerCase();

      if (rawValue.isEmpty || rawValue.toLowerCase() == normalizedResponsible) {
        result.add('Invité N$inviteCounter de $responsible');
      } else {
        result.add(rawValue);
      }

      inviteCounter++;
    }

    return result;
  }

  String _buildQrData() {
    final passengers = _buildPassengerDisplayList().join(', ');
    final seats = _extractSeatNumbers();

    return [
      'RESERVATION_ID:${reservation.id}',
      'TRAJET:${reservation.trajetLabel}',
      'DATE:${reservation.dateDepart}',
      'HEURE:${reservation.heureFormatee}',
      'RESPONSABLE:${_safe(reservation.clientNom)}',
      'PASSAGERS:$passengers',
      'NB_PLACES:${reservation.nombrePlace}',
      'SIEGES:${seats.isEmpty ? "-" : seats.join(", ")}',
      'STATUT:${reservation.statut}',
    ].join('|');
  }

  @override
  Widget build(BuildContext context) {
    final qrData = _buildQrData();
    final passengers = _buildPassengerDisplayList();
    final seatNumbers = _extractSeatNumbers();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7FB),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scanner ce QR pour voir toute la réservation',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 18),
                _DetailRow(label: 'Trajet', value: _safe(reservation.trajetLabel)),
                _DetailRow(label: 'Date', value: _safe(reservation.dateDepart)),
                _DetailRow(label: 'Heure', value: _safe(reservation.heureFormatee)),
                _DetailRow(
                  label: 'Véhicule',
                  value: _safe(reservation.vehiculeImmatriculation),
                ),
                _DetailRow(
                  label: 'Responsable',
                  value: _safe(reservation.clientNom),
                ),
                _DetailRow(
                  label: 'Nombre de places',
                  value: '${reservation.nombrePlace}',
                ),
                _DetailRow(
                  label: 'Numéros des sièges',
                  value: seatNumbers.isEmpty ? '-' : seatNumbers.join(', '),
                ),
                _DetailRow(
                  label: 'Montant',
                  value: reservation.prixFormate,
                  highlight: true,
                ),
                _DetailRow(
                  label: 'Statut',
                  value: _safe(reservation.statut),
                  highlight: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(
                  passengers.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Container(
                          height: 54,
                          width: 54,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3158F5),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            passengers[index],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF374151),
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
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _DetailRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: highlight
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