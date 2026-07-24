import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/settings/app_preferences_controller.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/client/models/reservation_model.dart';
import 'package:transia_mobile/features/client/services/payment_status_service.dart';
import 'package:transia_mobile/features/client/services/reservation_service.dart';

class TrackingListScreen extends StatefulWidget {
  const TrackingListScreen({super.key});

  @override
  State<TrackingListScreen> createState() => _TrackingListScreenState();
}

class _TrackingListScreenState extends State<TrackingListScreen> {
  late final SecureStorageService secureStorageService;
  late final ApiClient apiClient;
  late final ReservationService reservationService;
  late final PaymentStatusService paymentStatusService;

  bool isLoading = true;
  String? errorMessage;

  List<ReservationModel> reservations = [];

  AppPreferencesController get preferences =>
      AppPreferencesController.instance;

  @override
  void initState() {
    super.initState();

    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);

    reservationService = ReservationService(
      apiClient: apiClient,
    );

    paymentStatusService = PaymentStatusService();

    loadTrackingReservations();
  }

  String tr({
    required String fr,
    required String en,
    required String es,
    required String ar,
  }) {
    return preferences.tr(
      fr: fr,
      en: en,
      es: es,
      ar: ar,
    );
  }

  Future<void> loadTrackingReservations() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final myReservations = await reservationService.getMyReservations();

      final localPaidReservationIds =
          await paymentStatusService.getPaidReservationIds();

      final visibleReservations = myReservations.where(
        (reservation) {
          final paidFromBackend =
              reservation.isPaidOrValidated;

          final paidLocally =
              localPaidReservationIds.contains(
            reservation.id,
          );

          final isPaid =
              paidFromBackend || paidLocally;

          final isUnavailable =
              reservation.isCancelled ||
              reservation.isRefunded ||
              reservation.isRefundRequested;

          final hasTrip =
              reservation.trajetId.trim().isNotEmpty;

          final departure =
              reservation.departureDateTime;

          debugPrint(
            'TRACKING CHECK => '
            'reservationId=${reservation.id}, '
            'trajetId=${reservation.trajetId}, '
            'statut=${reservation.statut}, '
            'backendPaid=$paidFromBackend, '
            'localPaid=$paidLocally, '
            'unavailable=$isUnavailable, '
            'departure=$departure',
          );

          if (!isPaid) {
            return false;
          }

          if (isUnavailable) {
            return false;
          }

          if (!hasTrip) {
            return false;
          }

          /*
           * Si la date du trajet n’a pas pu être reconstruite,
           * la réservation reste visible puisqu’elle est payée.
           */
          if (departure == null) {
            return true;
          }

          /*
           * Le trajet reste visible :
           * - avant son départ ;
           * - pendant son déroulement ;
           * - jusqu’à 24 heures après l’heure prévue.
           *
           * Cela permet au client de consulter un trajet en cours
           * même après l’heure initialement programmée.
           */
          final trackingVisibilityLimit = departure.add(
            const Duration(hours: 24),
          );

          return DateTime.now().isBefore(
            trackingVisibilityLimit,
          );
        },
      ).toList();

      visibleReservations.sort(
        (firstReservation, secondReservation) {
          final firstDate =
              firstReservation.departureDateTime ??
              DateTime(2100);

          final secondDate =
              secondReservation.departureDateTime ??
              DateTime(2100);

          return firstDate.compareTo(secondDate);
        },
      );

      debugPrint(
        'TRACKING RESULT => '
        'myReservations=${myReservations.length}, '
        'localPaid=${localPaidReservationIds.length}, '
        'visible=${visibleReservations.length}',
      );

      if (!mounted) return;

      setState(() {
        reservations = visibleReservations;
        isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'TRACKING LIST ERROR = $error',
      );

      debugPrint(
        'TRACKING LIST STACKTRACE = $stackTrace',
      );

      if (!mounted) return;

      setState(() {
        reservations = [];
        isLoading = false;
        errorMessage = _cleanError(error);
      });
    }
  }

  bool _hasStarted(
    ReservationModel reservation,
  ) {
    final departure =
        reservation.departureDateTime;

    if (departure == null) {
      return false;
    }

    return !DateTime.now().isBefore(
      departure,
    );
  }

  Future<void> _openTracking(
    ReservationModel reservation,
  ) async {
    await context.push(
      AppRoutes.trackingDetail,
      extra: reservation,
    );

    if (!mounted) return;

    await loadTrackingReservations();
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceAll('Exception: ', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleColor =
        theme.textTheme.titleLarge?.color ??
        const Color(0xFF374151);

    final secondaryTextColor =
        theme.textTheme.bodyMedium?.color ??
        const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadTrackingReservations,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              18,
              26,
              18,
              32,
            ),
            children: [
              Text(
                tr(
                  fr: 'Suivi des trajets',
                  en: 'Trip tracking',
                  es: 'Seguimiento de viajes',
                  ar: 'تتبع الرحلات',
                ),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr(
                  fr:
                      'Consultez la position et le statut de vos voyages payés.',
                  en:
                      'View the position and status of your paid trips.',
                  es:
                      'Consulta la posición y el estado de tus viajes pagados.',
                  ar:
                      'تحقق من موقع وحالة رحلاتك المدفوعة.',
                ),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 24),

              if (isLoading)
                const SizedBox(
                  height: 350,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (errorMessage != null)
                _TrackingErrorCard(
                  message: errorMessage!,
                  onRetry: loadTrackingReservations,
                )
              else if (reservations.isEmpty)
                _EmptyTrackingCard(
                  title: tr(
                    fr: 'Aucun trajet à suivre',
                    en: 'No trip to track',
                    es: 'No hay viajes para seguir',
                    ar: 'لا توجد رحلة لتتبعها',
                  ),
                  message: tr(
                    fr:
                        'Aucun trajet payé à suivre pour le moment.',
                    en:
                        'No paid trip to track at the moment.',
                    es:
                        'No hay viajes pagados para seguir por el momento.',
                    ar:
                        'لا توجد رحلة مدفوعة لتتبعها حاليًا.',
                  ),
                )
              else
                ...reservations.map(
                  (reservation) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 14,
                      ),
                      child: _TrackingReservationCard(
                        reservation: reservation,
                        hasStarted:
                            _hasStarted(reservation),
                        onTap: () {
                          _openTracking(
                            reservation,
                          );
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackingReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final bool hasStarted;
  final VoidCallback onTap;

  const _TrackingReservationCard({
    required this.reservation,
    required this.hasStarted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final statusColor = hasStarted
        ? const Color(0xFF10B981)
        : const Color(0xFF3158F5);

    final statusLabel = hasStarted
        ? 'Départ effectué ou imminent'
        : 'À venir';

    final routeLabel =
        reservation.trajetLabel.trim().isEmpty
        ? 'Trajet non renseigné'
        : reservation.trajetLabel;

    final vehicleLabel =
        reservation.vehiculeImmatriculation
                .trim()
                .isEmpty
            ? 'Véhicule non renseigné'
            : reservation
                  .vehiculeImmatriculation;

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      routeLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w700,
                        color: Color(
                          0xFF374151,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor
                          .withOpacity(0.10),
                      borderRadius:
                          BorderRadius.circular(
                        999,
                      ),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _TrackingInformationRow(
                icon:
                    Icons.calendar_today_outlined,
                value:
                    reservation.dateDepart.trim().isEmpty
                    ? '-'
                    : reservation.dateDepart,
              ),
              const SizedBox(height: 10),
              _TrackingInformationRow(
                icon:
                    Icons.access_time_rounded,
                value:
                    reservation.heureFormatee
                            .trim()
                            .isEmpty
                    ? '-'
                    : reservation
                          .heureFormatee,
              ),
              const SizedBox(height: 10),
              _TrackingInformationRow(
                icon:
                    Icons.directions_bus_outlined,
                value: vehicleLabel,
              ),
              const SizedBox(height: 10),
              _TrackingInformationRow(
                icon:
                    Icons.airline_seat_recline_normal_rounded,
                value:
                    '${reservation.nombrePlace} place${reservation.nombrePlace > 1 ? 's' : ''}',
              ),
              const Divider(height: 30),
              const Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 20,
                    color: Color(
                      0xFF3158F5,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Consulter le suivi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w700,
                        color: Color(
                          0xFF3158F5,
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    size: 16,
                    color: Color(
                      0xFF3158F5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackingInformationRow
    extends StatelessWidget {
  final IconData icon;
  final String value;

  const _TrackingInformationRow({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: const Color(
            0xFF9CA3AF,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(
                0xFF6B7280,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyTrackingCard extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyTrackingCard({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 34,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(
                0xFF3158F5,
              ).withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off_outlined,
              size: 38,
              color: Color(
                0xFF3158F5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(
                0xFF374151,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(
                0xFF6B7280,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _TrackingErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 50,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(
                0xFF6B7280,
              ),
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () {
              onRetry();
            },
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text(
              'Réessayer',
            ),
          ),
        ],
      ),
    );
  }
}