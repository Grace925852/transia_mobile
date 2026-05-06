import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/client/models/reservation_model.dart';
import 'package:transia_mobile/features/client/services/payment_status_service.dart';
import 'package:transia_mobile/features/client/services/reservation_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final SecureStorageService secureStorageService;
  late final ApiClient apiClient;
  late final ReservationService reservationService;
  final PaymentStatusService paymentStatusService = PaymentStatusService();

  bool isLoading = true;
  List<ReservationModel> historyReservations = [];
  List<String> locallyPaidIds = [];
  int? numericUserId;
  String fullName = '';
  String username = '';

  @override
  void initState() {
    super.initState();
    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);
    reservationService = ReservationService(apiClient: apiClient);
    chargerHistorique();
  }

  Future<void> chargerHistorique() async {
    setState(() {
      isLoading = true;
    });

    try {
      final storedNumericUserIdString =
          await secureStorageService.getNumericUserId();
      final storedFullName = await secureStorageService.getFullName();
      final storedUsername = await secureStorageService.getUsername();

      final storedNumericUserId =
          int.tryParse(storedNumericUserIdString ?? '');

      final allReservations = await reservationService.getMyReservations(
        userId: storedNumericUserId ?? -1,
        fullName: storedFullName ?? '',
        username: storedUsername ?? '',
      );

      final paidIds = await paymentStatusService.getPaidReservationIds();

      final filteredHistory = allReservations.where((reservation) {
        final paid = reservation.isPaidOrValidated ||
            paidIds.contains(reservation.id);
        final past = reservation.isPast;
        return paid && past;
      }).toList();

      filteredHistory.sort((a, b) {
        final da = a.departureDateTime ?? DateTime(1900);
        final db = b.departureDateTime ?? DateTime(1900);
        return db.compareTo(da);
      });

      if (!mounted) return;

      setState(() {
        numericUserId = storedNumericUserId;
        fullName = storedFullName ?? '';
        username = storedUsername ?? '';
        locallyPaidIds = paidIds;
        historyReservations = filteredHistory;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
        ),
      );
    }
  }

  bool _isPaid(ReservationModel reservation) {
    return reservation.isPaidOrValidated ||
        locallyPaidIds.contains(reservation.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          IconButton(
            onPressed: chargerHistorique,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: chargerHistorique,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : historyReservations.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 80),
                      const Icon(
                        Icons.history_rounded,
                        size: 54,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Aucun historique',
                        textAlign: TextAlign.center,
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
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(18),
                    itemCount: historyReservations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final reservation = historyReservations[index];

                      return Container(
                        padding: const EdgeInsets.all(16),
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
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _HistoryRow(
                              label: 'Date',
                              value: reservation.dateDepart,
                            ),
                            _HistoryRow(
                              label: 'Heure',
                              value: reservation.heureFormatee,
                            ),
                            _HistoryRow(
                              label: 'Responsable',
                              value: reservation.clientNom,
                            ),
                            _HistoryRow(
                              label: 'Montant',
                              value: reservation.prixFormate,
                            ),
                            _HistoryRow(
                              label: 'Statut',
                              value: _isPaid(reservation)
                                  ? 'PAYÉE'
                                  : reservation.statut,
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () {
                                  context.push(
                                    AppRoutes.ticketDetails,
                                    extra: reservation,
                                  );
                                },
                                child: const Text('Voir le billet'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String label;
  final String value;

  const _HistoryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}