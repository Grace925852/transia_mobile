import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/features/client/models/reservation_model.dart';
import 'package:transia_mobile/features/client/services/payment_status_service.dart';

class PaymentScreen extends StatefulWidget {
  final ReservationModel reservation;

  const PaymentScreen({
    super.key,
    required this.reservation,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final Color primaryBlue = const Color(0xFF3158F5);
  final PaymentStatusService paymentStatusService = PaymentStatusService();

  String paymentMethod = 'Flooz';
  bool isProcessing = false;

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

  List<int> _extractSeatNumbers() {
    final raw = widget.reservation.rawData;
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

  Future<void> effectuerPaiement() async {
    setState(() {
      isProcessing = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    await paymentStatusService.markReservationAsPaid(widget.reservation.id);

    if (!mounted) return;

    setState(() {
      isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Paiement effectué avec succès par $paymentMethod.',
        ),
      ),
    );

    context.go(AppRoutes.reservations);
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
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

  Widget _buildPaymentMethodTile(String method, IconData icon) {
    final isSelected = paymentMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          paymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF3FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? primaryBlue : const Color(0xFFE5E7EB),
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryBlue : const Color(0xFF6B7280),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? primaryBlue : const Color(0xFF374151),
                ),
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected ? primaryBlue : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final montant = widget.reservation.prixFormate;
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
          'Paiement',
          style: TextStyle(
            color: Color(0xFF374151),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
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
                  'Résumé du paiement',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 18),
                _buildInfoRow('Trajet', widget.reservation.trajetLabel),
                _buildInfoRow('Date', widget.reservation.dateDepart),
                _buildInfoRow('Heure', widget.reservation.heureFormatee),
                _buildInfoRow(
                  'Responsable',
                  _safe(widget.reservation.clientNom),
                ),
                _buildInfoRow(
                  'Passagers',
                  '${widget.reservation.nombrePlace}',
                ),
                _buildInfoRow(
                  'Sièges choisis',
                  seatNumbers.isEmpty ? '-' : seatNumbers.join(', '),
                ),
                _buildInfoRow('Prix unitaire', montant),
                _buildInfoRow('Montant à payer', montant, highlight: true),
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
                  'Mode de paiement',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 18),
                _buildPaymentMethodTile('Flooz', Icons.phone_android_rounded),
                const SizedBox(height: 12),
                _buildPaymentMethodTile(
                  'TMoney',
                  Icons.account_balance_wallet_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Le paiement se fait en totalité. Aucun paiement par tranche n’est autorisé.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: isProcessing ? null : effectuerPaiement,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : const Text(
                      'Confirmer le paiement',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}