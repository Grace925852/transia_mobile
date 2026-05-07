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
  String errorMessage = '';

  List<ReservationModel> reservations = [];
  List<String> locallyPaidIds = [];

  int selectedTab = 0; // 0 = non payées à venir, 1 = payées à venir

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

      final result = await reservationService.getMyReservations(
        userId: storedNumericUserId ?? -1,
        fullName: storedFullName ?? '',
        username: storedUsername ?? '',
      );

      final paidIds = await paymentStatusService.getPaidReservationIds();

      result.sort((a, b) {
        final da = a.departureDateTime ?? DateTime(2100);
        final db = b.departureDateTime ?? DateTime(2100);
        return da.compareTo(db);
      });

      if (!mounted) return;

      setState(() {
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

  bool _isUpcomingReservation(ReservationModel reservation) {
    final dt = reservation.departureDateTime;
    if (dt == null) return true;
    return dt.isAfter(DateTime.now());
  }

  List<ReservationModel> get unpaidReservations => reservations
      .where((r) => !_isPaid(r) && _isUpcomingReservation(r))
      .toList();

  List<ReservationModel> get paidReservations => reservations
      .where((r) => _isPaid(r) && _isUpcomingReservation(r))
      .toList();

  List<ReservationModel> get displayedReservations =>
      selectedTab == 0 ? unpaidReservations : paidReservations;

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
              const SizedBox(height: 16),
              _ReservationTabs(
                unpaidCount: unpaidReservations.length,
                paidCount: paidReservations.length,
                selectedTab: selectedTab,
                onChanged: (index) {
                  setState(() {
                    selectedTab = index;
                  });
                },
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
              else if (displayedReservations.isEmpty)
                _EmptyReservationCard(
                  isPaidTab: selectedTab == 1,
                )
              else
                ...displayedReservations.map(
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

class _ReservationTabs extends StatelessWidget {
  final int unpaidCount;
  final int paidCount;
  final int selectedTab;
  final ValueChanged<int> onChanged;

  const _ReservationTabs({
    required this.unpaidCount,
    required this.paidCount,
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SmallTab(
            title: 'En attente',
            count: unpaidCount,
            selected: selectedTab == 0,
            color: const Color(0xFFF59E0B),
            onTap: () => onChanged(0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SmallTab(
            title: 'Payées',
            count: paidCount,
            selected: selectedTab == 1,
            color: const Color(0xFF16A34A),
            onTap: () => onChanged(1),
          ),
        ),
      ],
    );
  }
}

class _SmallTab extends StatelessWidget {
  final String title;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _SmallTab({
    required this.title,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.white.withOpacity(0.75),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color.withOpacity(0.35) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: const Color(0xFF374151),
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
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reservation.trajetLabel,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 14),
          _ReservationRow(label: 'Date', value: reservation.dateDepart),
          _ReservationRow(label: 'Heure', value: reservation.heureFormatee),
          _ReservationRow(label: 'Véhicule', value: reservation.vehiculeImmatriculation),
          _ReservationRow(label: 'Responsable', value: reservation.clientNom),
          _ReservationRow(
            label: 'Passagers',
            value: '${reservation.nombrePlace}',
          ),
          _ReservationRow(
            label: 'Statut',
            value: isPaid ? 'PAYÉE' : 'EN ATTENTE',
            valueColor:
                isPaid ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
          ),
          const Divider(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  reservation.prixFormate,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3158F5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: isPaid ? onViewTicket : onPay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3158F5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 42),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isPaid ? 'Voir billet' : 'Payer',
                      overflow: TextOverflow.ellipsis,
                    ),
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
    final safeValue = value.trim().isEmpty ? '-' : value;

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
              safeValue,
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

class _EmptyReservationCard extends StatelessWidget {
  final bool isPaidTab;

  const _EmptyReservationCard({
    required this.isPaidTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(
            isPaidTab
                ? Icons.check_circle_outline_rounded
                : Icons.calendar_month_outlined,
            size: 52,
            color: const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 12),
          Text(
            isPaidTab
                ? 'Aucune réservation payée à venir'
                : 'Aucune réservation en attente à venir',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
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