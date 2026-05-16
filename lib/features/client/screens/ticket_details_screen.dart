import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:transia_mobile/core/settings/app_preferences_controller.dart';
import 'package:transia_mobile/features/client/models/reservation_model.dart';

class TicketDetailsScreen extends StatefulWidget {
  final ReservationModel reservation;

  const TicketDetailsScreen({super.key, required this.reservation});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
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
    final raw = widget.reservation.rawData;

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
    final raw = widget.reservation.rawData;
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
      widget.reservation.clientNom,
      fallback: 'Responsable',
    );

    if (widget.reservation.nombrePlace <= 1) {
      return [responsible];
    }

    final rawPassengers = _extractPassengerNames();
    final List<String> result = [responsible];
    int inviteCounter = 1;

    for (int index = 1; index < widget.reservation.nombrePlace; index++) {
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
      'RESERVATION_ID:${widget.reservation.id}',
      'TICKET_INDEX:${ticket.ticketIndex}/${ticket.totalTickets}',
      'PASSAGER:${ticket.passengerName}',
      'TRAJET:${widget.reservation.trajetLabel}',
      'DATE:${widget.reservation.dateDepart}',
      'HEURE:${widget.reservation.heureFormatee}',
      'SIEGE:${ticket.seatNumber}',
      'PRIX:${widget.reservation.prixFormate}',
      'STATUT:${widget.reservation.statut}',
    ].join('|');
  }

  String _buildDateTimeLine() {
    final date = _safe(widget.reservation.dateDepart);
    final time = _safe(widget.reservation.heureFormatee);

    if (date == '-' && time == '-') return '-';
    if (date == '-') return time;
    if (time == '-') return date;

    return '$date • $time';
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
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            flex: 5,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _buildSingleTicketPdf(_PassengerTicketData ticket) async {
    final pdf = pw.Document();

    final qrSvg = await pw.Barcode.qrCode().toSvg(
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
                    child: pw.SvgImage(svg: qrSvg),
                  ),
                ),
                pw.SizedBox(height: 18),
                _pdfRow('Passager', ticket.passengerName),
                _pdfRow('Trajet', widget.reservation.trajetLabel),
                _pdfRow('Date / Heure', _buildDateTimeLine()),
                _pdfRow('Siège', ticket.seatNumber),
                _pdfRow('Prix', widget.reservation.prixFormate),
                _pdfRow('Réservation', widget.reservation.id),
                _pdfRow('Statut', widget.reservation.statut),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> _buildSelectedTicketsPdf(
    List<_PassengerTicketData> selectedTickets,
  ) async {
    final pdf = pw.Document();

    for (final ticket in selectedTickets) {
      final qrSvg = await pw.Barcode.qrCode().toSvg(
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
                      child: pw.SvgImage(svg: qrSvg),
                    ),
                  ),
                  pw.SizedBox(height: 18),
                  _pdfRow('Passager', ticket.passengerName),
                  _pdfRow('Trajet', widget.reservation.trajetLabel),
                  _pdfRow('Date / Heure', _buildDateTimeLine()),
                  _pdfRow('Siège', ticket.seatNumber),
                  _pdfRow('Prix', widget.reservation.prixFormate),
                  _pdfRow('Réservation', widget.reservation.id),
                  _pdfRow('Statut', widget.reservation.statut),
                ],
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  Future<List<int>?> _showTicketSelectionDialog(
    List<_PassengerTicketData> tickets,
  ) async {
    final selected = List<bool>.filled(tickets.length, true);

    return showDialog<List<int>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text(
                tr(
                  fr: 'Choisir les billets',
                  en: 'Choose tickets',
                  es: 'Elegir boletos',
                  ar: 'اختر التذاكر',
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(tickets.length, (index) {
                      final ticket = tickets[index];
                      return CheckboxListTile(
                        value: selected[index],
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          '${ticket.ticketIndex}/${ticket.totalTickets}',
                        ),
                        subtitle: Text(
                          '${ticket.passengerName} • ${tr(fr: 'Siège', en: 'Seat', es: 'Asiento', ar: 'المقعد')} ${ticket.seatNumber}',
                        ),
                        onChanged: (value) {
                          setLocalState(() {
                            selected[index] = value ?? false;
                          });
                        },
                      );
                    }),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    tr(
                      fr: 'Annuler',
                      en: 'Cancel',
                      es: 'Cancelar',
                      ar: 'إلغاء',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final indexes = <int>[];
                    for (int i = 0; i < selected.length; i++) {
                      if (selected[i]) indexes.add(i);
                    }
                    Navigator.pop(dialogContext, indexes);
                  },
                  child: Text(
                    tr(
                      fr: 'Télécharger',
                      en: 'Download',
                      es: 'Descargar',
                      ar: 'تنزيل',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _downloadTickets(BuildContext context) async {
    try {
      final tickets = _buildTicketData();

      if (tickets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                fr: 'Aucun billet disponible.',
                en: 'No ticket available.',
                es: 'No hay boletos disponibles.',
                ar: 'لا توجد تذاكر متاحة.',
              ),
            ),
          ),
        );
        return;
      }

      List<_PassengerTicketData> selectedTickets;

      if (tickets.length == 1) {
        selectedTickets = [tickets.first];
      } else {
        final selectedIndexes = await _showTicketSelectionDialog(tickets);

        if (selectedIndexes == null) return;

        if (selectedIndexes.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr(
                  fr: 'Veuillez sélectionner au moins un billet.',
                  en: 'Please select at least one ticket.',
                  es: 'Seleccione al menos un boleto.',
                  ar: 'يرجى اختيار تذكرة واحدة على الأقل.',
                ),
              ),
            ),
          );
          return;
        }

        selectedTickets = selectedIndexes.map((i) => tickets[i]).toList();
      }

      final bytes = selectedTickets.length == 1
          ? await _buildSingleTicketPdf(selectedTickets.first)
          : await _buildSelectedTicketsPdf(selectedTickets);

      final fileName = selectedTickets.length == 1
          ? 'billet_${widget.reservation.id}_${selectedTickets.first.ticketIndex}.pdf'
          : 'billets_${widget.reservation.id}.pdf';

      await Printing.sharePdf(bytes: bytes, filename: fileName);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              fr: 'PDF prêt. Choisissez maintenant où l’enregistrer ou le partager.',
              en: 'PDF ready. Now choose where to save or share it.',
              es: 'PDF listo. Ahora elija dónde guardarlo o compartirlo.',
              ar: 'ملف PDF جاهز. اختر الآن مكان حفظه أو مشاركته.',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              fr: 'Impossible de préparer le PDF des billets.',
              en: 'Unable to prepare tickets PDF.',
              es: 'No se pudo preparar el PDF de los boletos.',
              ar: 'تعذر إعداد ملف PDF للتذاكر.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _shareSingleTicket(
    BuildContext context,
    _PassengerTicketData ticket,
  ) async {
    final bytes = await _buildSingleTicketPdf(ticket);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'billet_${widget.reservation.id}_${ticket.ticketIndex}.pdf',
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
              style: TextStyle(fontSize: 14, color: mutedColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: highlight ? const Color(0xFF3158F5) : normalTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, _PassengerTicketData ticket) {
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
              IconButton(
                onPressed: () => _shareSingleTicket(context, ticket),
                icon: const Icon(Icons.share_rounded, color: Color(0xFF3158F5)),
                tooltip: tr(
                  fr: 'Partager ce billet',
                  en: 'Share this ticket',
                  es: 'Compartir este boleto',
                  ar: 'مشاركة هذه التذكرة',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
            widget.reservation.trajetLabel,
          ),
          _buildInfoRow(
            context,
            tr(
              fr: 'Date / Heure',
              en: 'Date / Time',
              es: 'Fecha / Hora',
              ar: 'التاريخ / الوقت',
            ),
            _buildDateTimeLine(),
          ),
          _buildInfoRow(
            context,
            tr(fr: 'Siège', en: 'Seat', es: 'Asiento', ar: 'المقعد'),
            ticket.seatNumber,
          ),
          _buildInfoRow(
            context,
            tr(fr: 'Prix', en: 'Price', es: 'Precio', ar: 'السعر'),
            widget.reservation.prixFormate,
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
            widget.reservation.id,
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
                const Icon(Icons.download_rounded, color: Color(0xFF3158F5)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr(
                      fr: 'Téléchargez les billets de cette réservation en PDF.',
                      en: 'Download tickets for this booking as PDF.',
                      es: 'Descargue los boletos de esta reserva en PDF.',
                      ar: 'قم بتنزيل تذاكر هذا الحجز بصيغة PDF.',
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _downloadTickets(context),
                  child: Text(
                    tr(
                      fr: 'Télécharger',
                      en: 'Download',
                      es: 'Descargar',
                      ar: 'تنزيل',
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
