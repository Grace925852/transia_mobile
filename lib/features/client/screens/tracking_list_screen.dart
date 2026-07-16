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
  State<TrackingListScreen> createState() =>
      _TrackingListScreenState();
}

class _TrackingListScreenState extends State<TrackingListScreen> {
  late final SecureStorageService secureStorageService;
  late final ApiClient apiClient;
  late final ReservationService reservationService;
  late final PaymentStatusService paymentStatusService;

  bool isLoading = true;
  String? errorMessage;

  List<ReservationModel> reservations = [];

  AppPreferencesController get prefs =>
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
    return prefs.tr(
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
      final numericUserIdText =
          await secureStorageService.getNumericUserId();

      final username =
          await secureStorageService.getUsername() ?? '';

      /*
       * Si ton SecureStorageService possède getFullName(),
       * cette valeur sera utilisée. Sinon, le username sert
       * aussi de valeur de secours.
       */
      String fullName = username;

      try {
        final dynamic storage = secureStorageService;
        final dynamic storedFullName =
            await storage.getFullName();

        if (storedFullName != null &&
            storedFullName.toString().trim().isNotEmpty) {
          fullName = storedFullName.toString().trim();
        }
      } catch (_) {
        // getFullName n'existe peut-être pas dans le service.
        // Le username reste utilisé comme solution de secours.
      }

      final userId =
          int.tryParse(numericUserIdText ?? '') ?? 0;

      final results =
          await reservationService.getMyReservations(
        userId: userId,
        fullName: fullName,
        username: username,
      );

      final localPaidIds =
          await paymentStatusService.getPaidReservationIds();

      final filtered = results.where((reservation) {
        final paidFromBackend =
            reservation.isPaidOrValidated;

        final paidLocally =
            localPaidIds.contains(reservation.id);

        final isPaid =
            paidFromBackend || paidLocally;

        final isUnavailable =
            reservation.isCancelled ||
            reservation.isRefunded ||
            reservation.isRefundRequested;

        final departure =
            reservation.departureDateTime;

        if (!isPaid || isUnavailable) {
          return false;
        }

        if (reservation.trajetId.trim().isEmpty) {
          return false;
        }

        if (departure == null) {
          /*
           * On conserve quand même la réservation si elle
           * est payée, même si la date n'a pas été correctement
           * reconstruite depuis le backend.
           */
          return true;
        }

        /*
         * Le trajet reste visible pendant 24 heures après
         * l'heure prévue de départ.
         *
         * Cela permet au client de suivre un trajet en cours,
         * même lorsque l'heure prévue est déjà dépassée.
         */
        final trackingVisibilityLimit = departure.add(
          const Duration(hours: 24),
        );

        return DateTime.now().isBefore(
          trackingVisibilityLimit,
        );
      }).toList();

      filtered.sort((a, b) {
        final first =
            a.departureDateTime ?? DateTime(2100);

        final second =
            b.departureDateTime ?? DateTime(2100);

        return first.compareTo(second);
      });

      debugPrint(
        'TRACKING CLIENT => '
        'userId=$userId, '
        'username=$username, '
        'fullName=$fullName, '
        'all=${results.length}, '
        'localPaid=${localPaidIds.length}, '
        'visible=${filtered.length}',
      );

      for (final reservation in results) {
        debugPrint(
          'TRACKING CHECK => '
          'id=${reservation.id}, '
          'trajetId=${reservation.trajetId}, '
          'statut=${reservation.statut}, '
          'backendPaid=${reservation.isPaidOrValidated}, '
          'localPaid=${localPaidIds.contains(reservation.id)}, '
          'date=${reservation.dateDepart}, '
          'heure=${reservation.heureDepart}',
        );
      }

      if (!mounted) return;

      setState(() {
        reservations = filtered;
        isLoading = false;
      });
    } catch (error) {
      debugPrint(
        'TRACKING LIST ERROR = $error',
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

    return !DateTime.now().isBefore(departure);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleColor =
        theme.textTheme.titleLarge?.color ??
        const Color(0xFF374151);

    final mutedColor =
        theme.textTheme.bodyMedium?.color ??
        const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadTrackingReservations,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              18,
              22,
              18,
              28,
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
                  color: mutedColor,
                ),
              ),
              const SizedBox(height: 22),

              if (isLoading)
                const SizedBox(
                  height: 350,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (errorMessage != null)
                _TrackingListError(
                  message: errorMessage!,
                  onRetry: loadTrackingReservations,
                )
              else if (reservations.isEmpty)
                _EmptyTrackingList(
                  theme: theme,
                  titleColor: titleColor,
                  mutedColor: mutedColor,
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
                          _openTracking(reservation);
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

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceAll('Exception: ', '')
        .trim();
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
                      reservation.trajetLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
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
                      color:
                          statusColor.withOpacity(0.10),
                      borderRadius:
                          BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SmallTrackingRow(
                icon:
                    Icons.calendar_today_outlined,
                value: reservation.dateDepart,
              ),
              const SizedBox(height: 9),
              _SmallTrackingRow(
                icon: Icons.access_time_rounded,
                value: reservation.heureFormatee,
              ),
              const SizedBox(height: 9),
              _SmallTrackingRow(
                icon:
                    Icons.directions_bus_outlined,
                value: reservation
                        .vehiculeImmatriculation
                        .trim()
                        .isEmpty
                    ? 'Véhicule non renseigné'
                    : reservation
                        .vehiculeImmatriculation,
              ),
              const Divider(height: 28),
              const Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 20,
                    color: Color(0xFF3158F5),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Consulter le suivi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3158F5),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Color(0xFF3158F5),
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

class _SmallTrackingRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _SmallTrackingRow({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: const Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value.trim().isEmpty ? '-' : value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyTrackingList extends StatelessWidget {
  final ThemeData theme;
  final Color titleColor;
  final Color mutedColor;
  final String message;

  const _EmptyTrackingList({
    required this.theme,
    required this.titleColor,
    required this.mutedColor,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: const Color(
                0xFF3158F5,
              ).withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off_outlined,
              size: 38,
              color: Color(0xFF3158F5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun trajet à suivre',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingListError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _TrackingListError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
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
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}