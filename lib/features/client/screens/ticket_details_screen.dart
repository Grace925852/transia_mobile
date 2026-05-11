import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:transia_mobile/core/settings/app_preferences_controller.dart';
import 'package:transia_mobile/features/client/models/reservation_model.dart';

class TicketDetailsScreen extends StatelessWidget {
  final ReservationModel reservation;

  const TicketDetailsScreen({
    super.key,
    required this.reservation,
  });

  AppPreferencesController get prefs => AppPreferencesController.instance;

  String tr({
    required String fr,
    required String en,
    required String es,
    required String ar,
  }) {
    return prefs.tr(fr: fr, en: en, es: es, ar: ar);
  }

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

  List<String> _extractSeatNumbers() {
    final raw = reservation.rawData;
    final billets = _extractBillets();
    final Set<String> seats = {};

    void addSeat(dynamic value) {
      if (value == null) return;

      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        seats.add(text);
      }
    }

    for (final billet in billets) {
      addSeat(billet['numeroSiege']);
      addSeat(billet['numero_siege']);
      addSeat(billet['seatNumber']);
      addSeat(billet['siege']);
    }

    final extraLists = [
      raw['siegesChoisis'],
      raw['selectedSeats'],
      raw['seatNumbers'],
      raw['numerosSieges'],
    ];

    for (final data in extraLists) {
      if (data is List) {
        for (final item in data) {
          addSeat(item);
        }
      }
    }

    final result = seats.toList();
    result.sort((a, b) {
      final na = int.tryParse(a);
      final nb = int.tryParse(b);
      if (na != null && nb != null) return na.compareTo(nb);
      return a.compareTo(b);
    });
    return result;
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
    final theme = Theme.of(context);
    final qrData = _buildQrData();
    final passengers = _buildPassengerDisplayList();
    final seatNumbers = _extractSeatNumbers();
    final titleColor =
        theme.textTheme.titleLarge?.color ?? const Color(0xFF374151);
    final mutedColor =
        theme.textTheme.bodyMedium?.color ?? const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          tr(
            fr: 'Mon billet',
            en: 'My ticket',
            es: 'Mi boleto',
            ar: 'تذكرتي',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF111827)
                        : const Color(0xFFF6F7FB),
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
                Text(
                  tr(
                    fr: 'Scanner ce QR pour voir toute la réservation',
                    en: 'Scan this QR to view the full reservation',
                    es: 'Escanee este QR para ver toda la reserva',
                    ar: 'امسح رمز QR هذا لعرض الحجز بالكامل',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                  tr(
                    fr: 'Détails du trajet',
                    en: 'Trip details',
                    es: 'Detalles del trayecto',
                    ar: 'تفاصيل الرحلة',
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 18),
                _DetailRow(
                  label: tr(fr: 'Trajet', en: 'Trip', es: 'Trayecto', ar: 'الرحلة'),
                  value: _safe(reservation.trajetLabel),
                ),
                _DetailRow(
                  label: tr(fr: 'Date', en: 'Date', es: 'Fecha', ar: 'التاريخ'),
                  value: _safe(reservation.dateDepart),
                ),
                _DetailRow(
                  label: tr(fr: 'Heure', en: 'Time', es: 'Hora', ar: 'الوقت'),
                  value: _safe(reservation.heureFormatee),
                ),
                _DetailRow(
                  label: tr(fr: 'Véhicule', en: 'Vehicle', es: 'Vehículo', ar: 'المركبة'),
                  value: _safe(reservation.vehiculeImmatriculation),
                ),
                _DetailRow(
                  label: tr(fr: 'Responsable', en: 'Responsible', es: 'Responsable', ar: 'المسؤول'),
                  value: _safe(reservation.clientNom),
                ),
                _DetailRow(
                  label: tr(
                    fr: 'Nombre de places',
                    en: 'Number of seats',
                    es: 'Número de plazas',
                    ar: 'عدد الأماكن',
                  ),
                  value: '${reservation.nombrePlace}',
                ),
                _DetailRow(
                  label: tr(
                    fr: 'Numéros des sièges',
                    en: 'Seat numbers',
                    es: 'Números de asiento',
                    ar: 'أرقام المقاعد',
                  ),
                  value: seatNumbers.isEmpty ? '-' : seatNumbers.join(', '),
                ),
                _DetailRow(
                  label: tr(fr: 'Montant', en: 'Amount', es: 'Monto', ar: 'المبلغ'),
                  value: reservation.prixFormate,
                  highlight: true,
                ),
                _DetailRow(
                  label: tr(fr: 'Statut', en: 'Status', es: 'Estado', ar: 'الحالة'),
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
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(
                    fr: 'Liste des passagers',
                    en: 'Passenger list',
                    es: 'Lista de pasajeros',
                    ar: 'قائمة المسافرين',
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: theme.textTheme.bodyLarge?.color,
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
    final theme = Theme.of(context);
    final mutedColor =
        theme.textTheme.bodyMedium?.color ?? const Color(0xFF6B7280);
    final normalTextColor =
        theme.textTheme.bodyLarge?.color ?? const Color(0xFF374151);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: mutedColor,
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
                    : normalTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}