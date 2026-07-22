import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/settings/app_preferences_controller.dart';
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

  AppPreferencesController get prefs => AppPreferencesController.instance;

  String tr({
    required String fr,
    required String en,
    required String es,
    required String ar,
  }) {
    return prefs.tr(fr: fr, en: en, es: es, ar: ar);
  }

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
      final result = await reservationService.getMyReservations();

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
    final theme = Theme.of(context);
    final titleColor =
        theme.textTheme.titleLarge?.color ?? const Color(0xFF374151);
    final mutedColor =
        theme.textTheme.bodyMedium?.color ?? const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          tr(
            fr: 'Historique',
            en: 'History',
            es: 'Historial',
            ar: 'السجل',
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
                    children: [
                      const SizedBox(height: 80),
                      Icon(
                        Icons.history_rounded,
                        size: 54,
                        color: mutedColor,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        tr(
                          fr: 'Aucun historique',
                          en: 'No history',
                          es: 'Sin historial',
                          ar: 'لا يوجد سجل',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr(
                          fr: 'Seules les réservations payées et déjà passées apparaissent ici.',
                          en: 'Only paid and completed reservations appear here.',
                          es: 'Solo las reservas pagadas y finalizadas aparecen aquí.',
                          ar: 'تظهر هنا فقط الحجوزات المدفوعة والمنتهية.',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: mutedColor,
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
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reservation.trajetLabel,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _HistoryRow(
                              label: tr(fr: 'Date', en: 'Date', es: 'Fecha', ar: 'التاريخ'),
                              value: reservation.dateDepart.isEmpty
                                  ? '-'
                                  : reservation.dateDepart,
                            ),
                            _HistoryRow(
                              label: tr(fr: 'Heure', en: 'Time', es: 'Hora', ar: 'الوقت'),
                              value: reservation.heureFormatee.isEmpty
                                  ? '-'
                                  : reservation.heureFormatee,
                            ),
                            _HistoryRow(
                              label: tr(
                                fr: 'Responsable',
                                en: 'Responsible',
                                es: 'Responsable',
                                ar: 'المسؤول',
                              ),
                              value: reservation.clientNom.isEmpty
                                  ? '-'
                                  : reservation.clientNom,
                            ),
                            _HistoryRow(
                              label: tr(fr: 'Montant', en: 'Amount', es: 'Monto', ar: 'المبلغ'),
                              value: reservation.prixFormate,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        context.push(
                                          AppRoutes.rating,
                                          extra: reservation,
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFFF59E0B),
                                        side: const BorderSide(
                                          color: Color(0xFFF59E0B),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.star_outline_rounded,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            tr(
                                              fr: 'Noter',
                                              en: 'Rate',
                                              es: 'Calificar',
                                              ar: 'قيّم',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        context.push(
                                          AppRoutes.ticketDetails,
                                          extra: reservation,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF3158F5),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        tr(
                                          fr: 'Voir le billet',
                                          en: 'View ticket',
                                          es: 'Ver boleto',
                                          ar: 'عرض التذكرة',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
    final theme = Theme.of(context);
    final mutedColor =
        theme.textTheme.bodyMedium?.color ?? const Color(0xFF6B7280);
    final normalTextColor =
        theme.textTheme.bodyLarge?.color ?? const Color(0xFF374151);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: mutedColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: normalTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}