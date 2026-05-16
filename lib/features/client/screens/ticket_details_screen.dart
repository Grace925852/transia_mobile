import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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

  List<_PassengerTicketData> _buildTicketData() {
    final passengers = _buildPassengerDisplayList();
    final seats = _extractSeatNumbers();
    final total = passengers.length;

    return List.generate(passengers.length, (index) {
      final seat = index < seats.length ? seats[index] : '-';
      return _PassengerTicketData(
        ticketIndex: index + 1,
        totalTickets: total,
        passengerName: passengers[index],
        seatNumber: seat,
      );
    });
  }

  String _buildQrDataForTicket(_PassengerTicketData ticket) {
    return [
      'RESERVATION_ID:${reservation.id}',
      'TICKET_INDEX:${ticket.ticketIndex}/${ticket.totalTickets}',
      'PASSAGER:${ticket.passengerName}',
      'TRAJET:${reservation.trajetLabel}',
      'DATE:${reservation.dateDepart}',
      'HEURE:${reservation.heureFormatee}',
      'SIEGE:${ticket.seatNumber}',
      'PRIX:${reservation.prixFormate}',
      'STATUT:${reservation.statut}',
    ].join('|');
  }

  Future<Uint8List> _buildPdf() async {
    final pdf = pw.Document();
    final tickets = _buildTicketData();

    for (final ticket in tickets) {
      final qrImage = await pw.Barcode.qrCode().toSvg(
        _buildQrDataForTicket(ticket),
        width: 140,
        height: 140,
      );

      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(24),
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue700, width: 1.5),
                borderRadius: pw.BorderRadius.circular(16),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TRANSIA',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue700,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue50,
                          borderRadius: pw.BorderRadius.circular(20),
                        ),
                        child: pw.Text(
                          '${ticket.ticketIndex}/${ticket.totalTickets}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 18),
                  pw.Center(
                    child: pw.SizedBox(
                      width: 140,
                      height: 140,
                      child: pw.SvgImage(svg: qrImage),
                    ),
                  ),
                  pw.SizedBox(height: 18),
                  _pdfRow('Passager', ticket.passengerName),
                  _pdfRow('Trajet', reservation.trajetLabel),
                  _pdfRow('Date', reservation.dateDepart),
                  _pdfRow('Heure', reservation.heureFormatee),
                  _pdfRow('Siège', ticket.seatNumber),
                  _pdfRow('Prix', reservation.prixFormate),
                  _pdfRow('Réservation', reservation.id),
                  _pdfRow('Statut', reservation.statut),
                  pw.Spacer(),
                  pw.Text(
                    'Billet généré pour la réservation ${reservation.id}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            flex: 5,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    final bytes = await _buildPdf();

    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'tickets_${reservation.id}',
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final mutedColor =
        theme.textTheme.bodyMedium?.color ?? const Color(0xFF6B7280);
    final normalTextColor =
        theme.textTheme.bodyLarge?.color ?? const Color(0xFF374151);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: mutedColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
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

  Widget _buildTicketCard(
    BuildContext context,
    _PassengerTicketData ticket,
  ) {
    final theme = Theme.of(context);
    final titleColor =
        theme.textTheme.titleLarge?.color ?? const Color(0xFF374151);
    final qrData = _buildQrDataForTicket(ticket);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${ticket.ticketIndex}/${ticket.totalTickets}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3158F5),
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.confirmation_number_rounded,
                color: Color(0xFF3158F5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF111827)
                    : const Color(0xFFF6F7FB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 150,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            ticket.passengerName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            tr(fr: 'Trajet', en: 'Trip', es: 'Trayecto', ar: 'الرحلة'),
            reservation.trajetLabel,
          ),
          _buildInfoRow(
            context,
            tr(fr: 'Date', en: 'Date', es: 'Fecha', ar: 'التاريخ'),
            reservation.dateDepart,
          ),
          _buildInfoRow(
            context,
            tr(fr: 'Heure', en: 'Time', es: 'Hora', ar: 'الوقت'),
            reservation.heureFormatee,
          ),
          _buildInfoRow(
            context,
            tr(fr: 'Siège', en: 'Seat', es: 'Asiento', ar: 'المقعد'),
            ticket.seatNumber,
          ),
          _buildInfoRow(
            context,
            tr(fr: 'Prix', en: 'Price', es: 'Precio', ar: 'السعر'),
            reservation.prixFormate,
            highlight: true,
          ),
          _buildInfoRow(
            context,
            tr(
              fr: 'ID réservation',
              en: 'Reservation ID',
              es: 'ID reserva',
              ar: 'معرف الحجز',
            ),
            reservation.id,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tickets = _buildTicketData();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          tr(
            fr: 'Mes billets',
            en: 'My tickets',
            es: 'Mis boletos',
            ar: 'تذاكري',
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _downloadPdf(context),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: tr(
              fr: 'Télécharger en PDF',
              en: 'Download PDF',
              es: 'Descargar PDF',
              ar: 'تنزيل PDF',
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFF3158F5),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr(
                      fr: 'Téléchargez tous les billets de cette réservation en PDF.',
                      en: 'Download all tickets for this booking as PDF.',
                      es: 'Descargue todos los boletos de esta reserva en PDF.',
                      ar: 'قم بتنزيل جميع تذاكر هذا الحجز بصيغة PDF.',
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _downloadPdf(context),
                  child: Text(
                    tr(
                      fr: 'PDF',
                      en: 'PDF',
                      es: 'PDF',
                      ar: 'PDF',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...tickets.map((ticket) => _buildTicketCard(context, ticket)),
        ],
      ),
    );
  }
}

class _PassengerTicketData {
  final int ticketIndex;
  final int totalTickets;
  final String passengerName;
  final String seatNumber;

  _PassengerTicketData({
    required this.ticketIndex,
    required this.totalTickets,
    required this.passengerName,
    required this.seatNumber,
  });
}