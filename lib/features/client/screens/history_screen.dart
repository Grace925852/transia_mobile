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

      final result = await reservationService.getMyReservations(
        userId: storedNumericUserId ?? -1,
        fullName: storedFullName ?? '',
        username: storedUsername ?? '',
      );

      final paidIds = await paymentStatusService.getPaidReservationIds();

      final history = result.where((reservation) {
        final isPaid = reservation.isPaidOrValidated ||
            paidIds.contains(reservation.id);

        final dt = reservation.departureDateTime;
        final isPast = dt == null ? false : !dt.isAfter(DateTime.now());

        return isPaid && isPast;
      }).toList();

      history.sort((a, b) {
        final da = a.departureDateTime ?? DateTime(1900);
        final db = b.departureDateTime ?? DateTime(1900);
        return db.compareTo(da);
      });

      if (!mounted) return;

      setState(() {
        historyReservations = history;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF374151)),
        title: const Text(
          'Historique',
          style: TextStyle(
            color: Color(0xFF374151),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
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
                    children: const [
                      SizedBox(height: 80),
                      Icon(
                        Icons.history_rounded,
                        size: 54,
                        color: Color(0xFF9CA3AF),
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Aucun historique',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Seules les réservations payées et déjà passées apparaissent ici.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
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
                              value: reservation.dateDepart.isEmpty
                                  ? '-'
                                  : reservation.dateDepart,
                            ),
                            _HistoryRow(
                              label: 'Heure',
                              value: reservation.heureFormatee.isEmpty
                                  ? '-'
                                  : reservation.heureFormatee,
                            ),
                            _HistoryRow(
                              label: 'Responsable',
                              value: reservation.clientNom,
                            ),
                            _HistoryRow(
                              label: 'Montant',
                              value: reservation.prixFormate,
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                height: 38,
                                child: ElevatedButton(
                                  onPressed: () {
                                    context.push(
                                      AppRoutes.ticketDetails,
                                      extra: reservation,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3158F5),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Voir le billet'),
                                ),
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