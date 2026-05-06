import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/client/models/reservation_model.dart';
import 'package:transia_mobile/features/client/services/payment_status_service.dart';
import 'package:transia_mobile/features/client/services/reservation_service.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  late final SecureStorageService secureStorageService;
  late final ApiClient apiClient;
  late final ReservationService reservationService;
  final PaymentStatusService paymentStatusService = PaymentStatusService();

  bool isLoading = true;
  List<ReservationModel> reservations = [];
  List<String> locallyPaidIds = [];

  int? numericUserId;
  String fullName = '';
  String username = '';
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);
    reservationService = ReservationService(apiClient: apiClient);
    chargerReservations();
  }

  Future<void> chargerReservations() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final storedNumericUserIdString =
          await secureStorageService.getNumericUserId();
      final storedFullName = await secureStorageService.getFullName();
      final storedUsername = await secureStorageService.getUsername();

      final storedNumericUserId =
          int.tryParse(storedNumericUserIdString ?? '');

      final result = await reservationService.getMyActiveReservations(
        userId: storedNumericUserId ?? -1,
        fullName: storedFullName ?? '',
        username: storedUsername ?? '',
      );

      final paidIds = await paymentStatusService.getPaidReservationIds();

      if (!mounted) return;

      setState(() {
        numericUserId = storedNumericUserId;
        fullName = storedFullName ?? '';
        username = storedUsername ?? '';
        reservations = result;
        locallyPaidIds = paidIds;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  bool _isPaid(ReservationModel reservation) {
    return reservation.isPaidOrValidated ||
        locallyPaidIds.contains(reservation.id);
  }

  int get confirmedCount => reservations.where(_isPaid).length;

  int get pendingCount => reservations.where((r) => !_isPaid(r)).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: chargerReservations,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
            children: [
              const Text(
                'Mes Réservations',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _CounterCard(
                      value: '$confirmedCount',
                      label: 'Confirmées',
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CounterCard(
                      value: '$pendingCount',
                      label: 'En attente',
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (errorMessage.isNotEmpty)
                _ErrorCard(
                  message: errorMessage,
                  onRetry: chargerReservations,
                )
              else if (reservations.isEmpty)
                _EmptyCard(
                  fullName: fullName,
                  username: username,
                  numericUserId: numericUserId,
                )
              else
                ...reservations.map(
                  (reservation) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ReservationCard(
                      reservation: reservation,
                      isPaid: _isPaid(reservation),
                      onPay: () async {
                        await context.push(
                          AppRoutes.payment,
                          extra: reservation,
                        );
                        if (!mounted) return;
                        await chargerReservations();
                      },
                      onViewTicket: () {
                        context.push(
                          AppRoutes.ticketDetails,
                          extra: reservation,
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _CounterCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 122,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final bool isPaid;
  final VoidCallback onPay;
  final VoidCallback onViewTicket;

  const _ReservationCard({
    required this.reservation,
    required this.isPaid,
    required this.onPay,
    required this.onViewTicket,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reservation.trajetLabel,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 14),
          _ReservationRow(
            label: 'Date',
            value: reservation.dateDepart,
          ),
          _ReservationRow(
            label: 'Heure',
            value: reservation.heureFormatee,
          ),
          _ReservationRow(
            label: 'Véhicule',
            value: reservation.vehiculeImmatriculation,
          ),
          _ReservationRow(
            label: 'Responsable',
            value: reservation.clientNom,
          ),
          _ReservationRow(
            label: 'Passagers',
            value: '${reservation.nombrePlace}',
          ),
          _ReservationRow(
            label: 'Type',
            value: reservation.nombrePlace > 1
                ? 'Réservation groupe'
                : 'Réservation simple',
          ),
          _ReservationRow(
            label: 'Statut',
            value: isPaid ? 'PAYÉE' : reservation.statut,
            valueColor:
                isPaid ? const Color(0xFF16A34A) : const Color(0xFF3158F5),
          ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(
                child: Text(
                  reservation.prixFormate,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3158F5),
                  ),
                ),
              ),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: isPaid ? onViewTicket : onPay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3158F5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isPaid ? 'Voir billet' : 'Payer maintenant',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReservationRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ReservationRow({
    required this.label,
    required this.value,
    this.valueColor,
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
                color: valueColor ?? const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String fullName;
  final String username;
  final int? numericUserId;

  const _EmptyCard({
    required this.fullName,
    required this.username,
    required this.numericUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            size: 52,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 12),
          const Text(
            'Aucune réservation active',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Client: $fullName | $username | id=${numericUserId ?? "-"}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 46,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 12),
          const Text(
            'Impossible de charger les réservations',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}