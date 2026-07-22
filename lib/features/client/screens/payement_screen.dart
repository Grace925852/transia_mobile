import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/settings/app_preferences_controller.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/client/models/reservation_model.dart';
import 'package:transia_mobile/features/client/services/paiement_service.dart';
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
  late final PaiementService paiementService;

  String paymentMethod = 'Flooz';
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    paiementService = PaiementService(
      apiClient: ApiClient(SecureStorageService()),
    );
  }

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

  String get _modePaiementBackend {
    switch (paymentMethod) {
      case 'Flooz':
        return 'FLOOZ';
      case 'TMoney':
        return 'TMONEY';
      default:
        return 'CARTE_BANCAIRE';
    }
  }

  Future<void> effectuerPaiement() async {
    setState(() {
      isProcessing = true;
    });

    try {
      await paiementService.payerEnLigne(
        reservationId: widget.reservation.id,
        montantVerse: widget.reservation.montantTotal,
        modePaiement: _modePaiementBackend,
      );

      await paymentStatusService.markReservationAsPaid(widget.reservation.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              fr: 'Paiement effectué avec succès par $paymentMethod.',
              en: 'Payment completed successfully with $paymentMethod.',
              es: 'Pago realizado correctamente con $paymentMethod.',
              ar: 'تم الدفع بنجاح عبر $paymentMethod.',
            ),
          ),
        ),
      );

      // Revenir (pop) plutôt que go() : l'écran appelant (ReservationsScreen.onPay) attend déjà ce
      // retour pour recharger la liste — go() recréait tout l'écran et court-circuitait ce rechargement,
      // donnant l'impression que la réservation ne basculait jamais dans l'onglet "Payées".
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.reservations);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final normalTextColor =
        theme.textTheme.bodyLarge?.color ?? const Color(0xFF374151);
    final mutedColor =
        theme.textTheme.bodyMedium?.color ?? const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: mutedColor,
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
                color: highlight ? primaryBlue : normalTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(BuildContext context, String method, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = paymentMethod == method;
    final normalTextColor =
        theme.textTheme.bodyLarge?.color ?? const Color(0xFF374151);
    final mutedColor =
        theme.textTheme.bodyMedium?.color ?? const Color(0xFF6B7280);

    return GestureDetector(
      onTap: () {
        setState(() {
          paymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF172554) : const Color(0xFFEFF3FF))
              : theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? primaryBlue
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryBlue : mutedColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? primaryBlue : normalTextColor,
                ),
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected ? primaryBlue : mutedColor,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final montant = widget.reservation.prixFormate;
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
            fr: 'Paiement',
            en: 'Payment',
            es: 'Pago',
            ar: 'الدفع',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
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
                  tr(
                    fr: 'Résumé du paiement',
                    en: 'Payment summary',
                    es: 'Resumen del pago',
                    ar: 'ملخص الدفع',
                  ),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 18),
                _buildInfoRow(
                  context,
                  tr(fr: 'Trajet', en: 'Trip', es: 'Trayecto', ar: 'الرحلة'),
                  widget.reservation.trajetLabel,
                ),
                _buildInfoRow(
                  context,
                  tr(fr: 'Date', en: 'Date', es: 'Fecha', ar: 'التاريخ'),
                  widget.reservation.dateDepart,
                ),
                _buildInfoRow(
                  context,
                  tr(fr: 'Heure', en: 'Time', es: 'Hora', ar: 'الوقت'),
                  widget.reservation.heureFormatee,
                ),
                _buildInfoRow(
                  context,
                  tr(
                    fr: 'Responsable',
                    en: 'Responsible',
                    es: 'Responsable',
                    ar: 'المسؤول',
                  ),
                  _safe(widget.reservation.clientNom),
                ),
                _buildInfoRow(
                  context,
                  tr(
                    fr: 'Passagers',
                    en: 'Passengers',
                    es: 'Pasajeros',
                    ar: 'المسافرون',
                  ),
                  '${widget.reservation.nombrePlace}',
                ),
                _buildInfoRow(
                  context,
                  tr(
                    fr: 'Sièges choisis',
                    en: 'Selected seats',
                    es: 'Asientos elegidos',
                    ar: 'المقاعد المختارة',
                  ),
                  seatNumbers.isEmpty ? '-' : seatNumbers.join(', '),
                ),
                _buildInfoRow(
                  context,
                  tr(
                    fr: 'Prix unitaire',
                    en: 'Unit price',
                    es: 'Precio unitario',
                    ar: 'سعر الوحدة',
                  ),
                  montant,
                ),
                _buildInfoRow(
                  context,
                  tr(
                    fr: 'Montant à payer',
                    en: 'Amount to pay',
                    es: 'Monto a pagar',
                    ar: 'المبلغ المستحق',
                  ),
                  montant,
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
                    fr: 'Mode de paiement',
                    en: 'Payment method',
                    es: 'Método de pago',
                    ar: 'طريقة الدفع',
                  ),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 18),
                _buildPaymentMethodTile(context, 'Flooz', Icons.phone_android_rounded),
                const SizedBox(height: 12),
                _buildPaymentMethodTile(
                  context,
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
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tr(
                fr: 'Le paiement se fait en totalité. Aucun paiement par tranche n’est autorisé.',
                en: 'Payment must be made in full. Partial payment is not allowed.',
                es: 'El pago debe hacerse en su totalidad. No se permite el pago parcial.',
                ar: 'يجب أن يتم الدفع بالكامل. لا يُسمح بالدفع الجزئي.',
              ),
              style: TextStyle(
                fontSize: 14,
                color: mutedColor,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: isProcessing ? null : effectuerPaiement,
              child: isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : Text(
                      tr(
                        fr: 'Confirmer le paiement',
                        en: 'Confirm payment',
                        es: 'Confirmar pago',
                        ar: 'تأكيد الدفع',
                      ),
                      style: const TextStyle(
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