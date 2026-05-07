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

  List<String> _extractRawPassengerNames() {
    final dynamic billetsData =
        reservation.rawData['billets'] ?? reservation.rawData['tickets'];

    if (billetsData is List) {
      return billetsData.map((item) {
        if (item is Map<String, dynamic>) {
          return (item['nomPassager'] ??
                  item['passagerNom'] ??
                  item['nom'] ??
                  '')
              .toString()
              .trim();
        }

        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          return (map['nomPassager'] ??
                  map['passagerNom'] ??
                  map['nom'] ??
                  '')
              .toString()
              .trim();
        }

        return '';
      }).toList();
    }

    return [];
  }

  List<String> _buildPassengerDisplayList() {
    final responsible = _safe(
      reservation.clientNom,
      fallback: 'Responsable',
    );

    final rawPassengers = _extractRawPassengerNames();

    if (rawPassengers.isEmpty) {
      return List.generate(
        reservation.nombrePlace,
        (index) => index == 0
            ? responsible
            : 'Invité N$index de $responsible',
      );
    }

    final List<String> result = [];
    int inviteIndex = 1;

    for (int i = 0; i < rawPassengers.length; i++) {
      final current = rawPassengers[i];

      if (i == 0) {
        result.add(current.isEmpty ? responsible : current);
        continue;
      }

      final isUnnamed = current.isEmpty;
      final looksLikeDefaultDuplicate =
          current.toLowerCase() == responsible.toLowerCase();

      if (isUnnamed || looksLikeDefaultDuplicate) {
        result.add('Invité N$inviteIndex de $responsible');
        inviteIndex++;
      } else {
        result.add(current);
      }
    }

    while (result.length < reservation.nombrePlace) {
      result.add('Invité N$inviteIndex de $responsible');
      inviteIndex++;
    }

    return result;
  }

  String _buildQrData() {
    final passengers = _buildPassengerDisplayList().join(', ');

    return [
      'RESERVATION_ID:${reservation.id}',
      'TRAJET:${reservation.trajetLabel}',
      'DATE:${reservation.dateDepart}',
      'HEURE:${reservation.heureFormatee}',
      'RESPONSABLE:${_safe(reservation.clientNom)}',
      'PASSAGERS:$passengers',
      'NB_PLACES:${reservation.nombrePlace}',
      'STATUT:${reservation.statut}',
    ].join('|');
  }

  @override
  Widget build(BuildContext context) {
    final qrData = _buildQrData();
    final passengers = _buildPassengerDisplayList();

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
                _DetailRow(
                  label: 'Trajet',
                  value: _safe(reservation.trajetLabel),
                ),
                _DetailRow(
                  label: 'Date',
                  value: _safe(reservation.dateDepart),
                ),
                _DetailRow(
                  label: 'Heure',
                  value: _safe(reservation.heureFormatee),
                ),
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
                  label: 'Montant',
                  value: _safe(reservation.prixFormate),
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