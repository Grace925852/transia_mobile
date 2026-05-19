import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/settings/app_preferences_controller.dart';
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

  int selectedTab = 0;

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

  bool _canCancelReservation(ReservationModel reservation) {
    final status = reservation.statut.trim().toUpperCase();
    return status == 'EN_ATTENTE' && !reservation.isCancelled;
  }

  List<ReservationModel> get unpaidReservations => reservations
      .where(
        (r) =>
            !_isPaid(r) &&
            _isUpcomingReservation(r) &&
            !r.isClosedForReservations,
      )
      .toList();

  List<ReservationModel> get paidReservations => reservations
      .where(
        (r) =>
            _isPaid(r) &&
            _isUpcomingReservation(r) &&
            !r.isClosedForReservations,
      )
      .toList();

  List<ReservationModel> get displayedReservations =>
      selectedTab == 0 ? unpaidReservations : paidReservations;

  Future<void> _cancelReservation(ReservationModel reservation) async {
    final status = reservation.statut.trim().toUpperCase();

    if (status != 'EN_ATTENTE') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              fr: 'Seules les réservations en attente peuvent être annulées.',
              en: 'Only pending bookings can be cancelled.',
              es: 'Solo las reservas pendientes pueden cancelarse.',
              ar: 'يمكن إلغاء الحجوزات المعلقة فقط.',
            ),
          ),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          tr(
            fr: 'Annuler la réservation',
            en: 'Cancel booking',
            es: 'Cancelar reserva',
            ar: 'إلغاء الحجز',
          ),
        ),
        content: Text(
          tr(
            fr: 'Voulez-vous vraiment annuler cette réservation ? Les places seront libérées.',
            en: 'Do you really want to cancel this booking? The seats will be released.',
            es: '¿Desea realmente cancelar esta reserva? Los asientos serán liberados.',
            ar: 'هل تريد فعلاً إلغاء هذا الحجز؟ سيتم تحرير المقاعد.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(fr: 'Non', en: 'No', es: 'No', ar: 'لا')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              tr(
                fr: 'Oui, annuler',
                en: 'Yes, cancel',
                es: 'Sí, cancelar',
                ar: 'نعم، إلغاء',
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await reservationService.cancelReservation(reservation.id);
      await paymentStatusService.removePaidReservationId(reservation.id);
      await chargerReservations();

      final cancelledReservation = reservations.cast<ReservationModel?>().firstWhere(
            (r) => r?.id == reservation.id,
            orElse: () => null,
          );

      final reallyCancelled =
          cancelledReservation == null || cancelledReservation.isCancelled;

      if (!mounted) return;

      if (reallyCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                fr: 'Réservation annulée avec succès.',
                en: 'Booking cancelled successfully.',
                es: 'Reserva cancelada con éxito.',
                ar: 'تم إلغاء الحجز بنجاح.',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      await paymentStatusService.removePaidReservationId(reservation.id);
      await chargerReservations();

      final cancelledReservation = reservations.cast<ReservationModel?>().firstWhere(
            (r) => r?.id == reservation.id,
            orElse: () => null,
          );

      final reallyCancelled =
          cancelledReservation == null || cancelledReservation.isCancelled;

      if (!mounted) return;

      if (reallyCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                fr: 'Réservation annulée avec succès.',
                en: 'Booking cancelled successfully.',
                es: 'Reserva cancelada con éxito.',
                ar: 'تم إلغاء الحجز بنجاح.',
              ),
            ),
          ),
        );
      }
    }
  }

  void _openRefundRequest(ReservationModel reservation) {
    if (!reservation.isRefundEligible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reservation.refundEligibilityMessage),
        ),
      );
      return;
    }

    context.push(
      AppRoutes.refundRequest,
      extra: reservation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor =
        theme.textTheme.titleLarge?.color ?? const Color(0xFF374151);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: chargerReservations,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
            children: [
              Text(
                tr(
                  fr: 'Mes Réservations',
                  en: 'My bookings',
                  es: 'Mis reservas',
                  ar: 'حجوزاتي',
                ),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 16),
              _ReservationTabs(
                unpaidCount: unpaidReservations.length,
                paidCount: paidReservations.length,
                selectedTab: selectedTab,
                unpaidLabel: tr(
                  fr: 'En attente',
                  en: 'Pending',
                  es: 'Pendientes',
                  ar: 'قيد الانتظار',
                ),
                paidLabel: tr(
                  fr: 'Payées',
                  en: 'Paid',
                  es: 'Pagadas',
                  ar: 'مدفوعة',
                ),
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
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (errorMessage.isNotEmpty)
                _ErrorCard(
                  title: tr(
                    fr: 'Impossible de charger les réservations',
                    en: 'Unable to load bookings',
                    es: 'No se pueden cargar las reservas',
                    ar: 'تعذر تحميل الحجوزات',
                  ),
                  retryLabel: tr(
                    fr: 'Réessayer',
                    en: 'Retry',
                    es: 'Reintentar',
                    ar: 'إعادة المحاولة',
                  ),
                  message: errorMessage,
                  onRetry: chargerReservations,
                )
              else if (displayedReservations.isEmpty)
                _EmptyReservationCard(
                  isPaidTab: selectedTab == 1,
                  emptyPendingLabel: tr(
                    fr: 'Aucune réservation en attente à venir',
                    en: 'No upcoming pending booking',
                    es: 'No hay reservas pendientes próximas',
                    ar: 'لا توجد حجوزات معلقة قادمة',
                  ),
                  emptyPaidLabel: tr(
                    fr: 'Aucune réservation payée à venir',
                    en: 'No upcoming paid booking',
                    es: 'No hay reservas pagadas próximas',
                    ar: 'لا توجد حجوزات مدفوعة قادمة',
                  ),
                )
              else
                ...displayedReservations.map(
                  (reservation) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ReservationCard(
                      reservation: reservation,
                      isPaid: _isPaid(reservation),
                      canCancel: _canCancelReservation(reservation),
                      canRefund: _isPaid(reservation) &&
                          reservation.isRefundEligible &&
                          !reservation.isRefunded,
                      payLabel: tr(
                        fr: 'Payer',
                        en: 'Pay',
                        es: 'Pagar',
                        ar: 'ادفع',
                      ),
                      cancelLabel: tr(
                        fr: 'Annuler',
                        en: 'Cancel',
                        es: 'Cancelar',
                        ar: 'إلغاء',
                      ),
                      refundLabel: tr(
                        fr: 'Remboursement',
                        en: 'Refund',
                        es: 'Reembolso',
                        ar: 'استرداد',
                      ),
                      ticketLabel: tr(
                        fr: 'Voir billet',
                        en: 'View ticket',
                        es: 'Ver boleto',
                        ar: 'عرض التذكرة',
                      ),
                      dateLabel: tr(
                        fr: 'Date',
                        en: 'Date',
                        es: 'Fecha',
                        ar: 'التاريخ',
                      ),
                      timeLabel: tr(
                        fr: 'Heure',
                        en: 'Time',
                        es: 'Hora',
                        ar: 'الوقت',
                      ),
                      vehicleLabel: tr(
                        fr: 'Véhicule',
                        en: 'Vehicle',
                        es: 'Vehículo',
                        ar: 'المركبة',
                      ),
                      responsibleLabel: tr(
                        fr: 'Responsable',
                        en: 'Responsible',
                        es: 'Responsable',
                        ar: 'المسؤول',
                      ),
                      passengersLabel: tr(
                        fr: 'Passagers',
                        en: 'Passengers',
                        es: 'Pasajeros',
                        ar: 'المسافرون',
                      ),
                      statusLabel: tr(
                        fr: 'Statut',
                        en: 'Status',
                        es: 'Estado',
                        ar: 'الحالة',
                      ),
                      waitingText: tr(
                        fr: 'EN ATTENTE',
                        en: 'PENDING',
                        es: 'PENDIENTE',
                        ar: 'قيد الانتظار',
                      ),
                      paidText: tr(
                        fr: 'PAYÉE',
                        en: 'PAID',
                        es: 'PAGADA',
                        ar: 'مدفوعة',
                      ),
                      onPay: () async {
                        await context.push(
                          AppRoutes.payment,
                          extra: reservation,
                        );
                        if (!mounted) return;
                        await chargerReservations();
                      },
                      onCancel: () => _cancelReservation(reservation),
                      onViewTicket: () {
                        context.push(
                          AppRoutes.ticketDetails,
                          extra: reservation,
                        );
                      },
                      onRefund: () => _openRefundRequest(reservation),
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
  final String unpaidLabel;
  final String paidLabel;
  final ValueChanged<int> onChanged;

  const _ReservationTabs({
    required this.unpaidCount,
    required this.paidCount,
    required this.selectedTab,
    required this.unpaidLabel,
    required this.paidLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SmallTab(
            title: unpaidLabel,
            count: unpaidCount,
            selected: selectedTab == 0,
            color: const Color(0xFFF59E0B),
            onTap: () => onChanged(0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SmallTab(
            title: paidLabel,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        theme.textTheme.bodyLarge?.color ?? const Color(0xFF374151);

    return Material(
      color: selected
          ? theme.cardColor
          : (isDark ? const Color(0xFF111827) : Colors.white.withOpacity(0.75)),
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
                    color: textColor,
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
  final bool canCancel;
  final bool canRefund;
  final String payLabel;
  final String cancelLabel;
  final String refundLabel;
  final String ticketLabel;
  final String dateLabel;
  final String timeLabel;
  final String vehicleLabel;
  final String responsibleLabel;
  final String passengersLabel;
  final String statusLabel;
  final String waitingText;
  final String paidText;
  final VoidCallback onPay;
  final VoidCallback onCancel;
  final VoidCallback onViewTicket;
  final VoidCallback onRefund;

  const _ReservationCard({
    required this.reservation,
    required this.isPaid,
    required this.canCancel,
    required this.canRefund,
    required this.payLabel,
    required this.cancelLabel,
    required this.refundLabel,
    required this.ticketLabel,
    required this.dateLabel,
    required this.timeLabel,
    required this.vehicleLabel,
    required this.responsibleLabel,
    required this.passengersLabel,
    required this.statusLabel,
    required this.waitingText,
    required this.paidText,
    required this.onPay,
    required this.onCancel,
    required this.onViewTicket,
    required this.onRefund,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor =
        theme.textTheme.titleLarge?.color ?? const Color(0xFF374151);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 14),
          _ReservationRow(label: dateLabel, value: reservation.dateDepart),
          _ReservationRow(label: timeLabel, value: reservation.heureFormatee),
          _ReservationRow(
            label: vehicleLabel,
            value: reservation.vehiculeImmatriculation,
          ),
          _ReservationRow(
            label: responsibleLabel,
            value: reservation.clientNom,
          ),
          _ReservationRow(
            label: passengersLabel,
            value: '${reservation.nombrePlace}',
          ),
          _ReservationRow(
            label: statusLabel,
            value: isPaid ? paidText : waitingText,
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
              if (isPaid)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canRefund)
                      SizedBox(
                        height: 42,
                        child: OutlinedButton(
                          onPressed: onRefund,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 42),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            refundLabel,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    if (canRefund) const SizedBox(width: 10),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        onPressed: onViewTicket,
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
                          ticketLabel,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canCancel)
                      SizedBox(
                        height: 42,
                        child: OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 42),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            cancelLabel,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    if (canCancel) const SizedBox(width: 10),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        onPressed: onPay,
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
                          payLabel,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
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
    final theme = Theme.of(context);
    final safeValue = value.trim().isEmpty ? '-' : value;
    final mutedColor =
        theme.textTheme.bodyMedium?.color ?? const Color(0xFF6B7280);
    final normalTextColor =
        theme.textTheme.bodyLarge?.color ?? const Color(0xFF374151);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: mutedColor,
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
                color: valueColor ?? normalTextColor,
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
  final String emptyPendingLabel;
  final String emptyPaidLabel;

  const _EmptyReservationCard({
    required this.isPaidTab,
    required this.emptyPendingLabel,
    required this.emptyPaidLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor =
        theme.textTheme.titleLarge?.color ?? const Color(0xFF374151);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(
            isPaidTab
                ? Icons.check_circle_outline_rounded
                : Icons.calendar_month_outlined,
            size: 52,
            color: theme.textTheme.bodyMedium?.color,
          ),
          const SizedBox(height: 12),
          Text(
            isPaidTab ? emptyPaidLabel : emptyPendingLabel,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final String retryLabel;
  final Future<void> Function() onRetry;

  const _ErrorCard({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor =
        theme.textTheme.titleLarge?.color ?? const Color(0xFF374151);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}