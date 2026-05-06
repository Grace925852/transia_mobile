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
      const SnackBar(
        content: Text('Paiement total effectué avec succès.'),
      ),
    );

    context.go(AppRoutes.reservations);
  }

  @override
  Widget build(BuildContext context) {
    final reservation = widget.reservation;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Résumé du paiement',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 16),
                _PaymentRow(label: 'Réservation', value: '#${reservation.id}'),
                _PaymentRow(label: 'Trajet', value: reservation.trajetLabel),
                _PaymentRow(label: 'Date', value: reservation.dateDepart),
                _PaymentRow(label: 'Heure', value: reservation.heureFormatee),
                _PaymentRow(label: 'Responsable', value: reservation.clientNom),
                _PaymentRow(
                  label: 'Passagers',
                  value: '${reservation.nombrePlace}',
                ),
                _PaymentRow(
                  label: 'Prix unitaire',
                  value: reservation.prixUnitaireFormate,
                ),
                _PaymentRow(
                  label: 'Montant à payer',
                  value: reservation.prixFormate,
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
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mode de paiement',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 14),
                RadioListTile<String>(
                  value: 'Flooz',
                  groupValue: paymentMethod,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        paymentMethod = value;
                      });
                    }
                  },
                  title: const Text('Flooz'),
                  subtitle: const Text('Paiement mobile'),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  value: 'TMoney',
                  groupValue: paymentMethod,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        paymentMethod = value;
                      });
                    }
                  },
                  title: const Text('TMoney'),
                  subtitle: const Text('Paiement mobile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Text(
              'Le paiement se fait en totalité. Aucun paiement par tranche n’est autorisé.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: isProcessing ? null : effectuerPaiement,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isProcessing
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : Text(
                      'Payer ${reservation.prixFormate}',
                      style: const TextStyle(
                        fontSize: 16,
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

class _PaymentRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;

  const _PaymentRow({
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
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
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