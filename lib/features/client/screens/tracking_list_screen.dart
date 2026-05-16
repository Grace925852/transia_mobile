import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/settings/app_preferences_controller.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/client/models/reservation_model.dart';
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

  bool isLoading = true;
  List<ReservationModel> reservations = [];

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
    loadTrackingReservations();
  }

  bool _isPaid(ReservationModel reservation) {
    final s = reservation.statut.toUpperCase();
    return s.contains('PAYE') ||
        s.contains('PAYÉ') ||
        s.contains('CONFIRME') ||
        s.contains('VALIDE');
  }

  bool _isUpcoming(ReservationModel reservation) {
    try {
      final dt = DateTime.parse(
        '${reservation.dateDepart} ${reservation.heureFormatee}:00',
      );
      return dt.isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Future<void> loadTrackingReservations() async {
    setState(() {
      isLoading = true;
    });

    try {
      final allReservations = await reservationService.getReservations();

      final filtered = allReservations.where((r) {
        return _isPaid(r) && _isUpcoming(r);
      }).toList();

      if (!mounted) return;
      setState(() {
        reservations = filtered;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        reservations = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadTrackingReservations,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(
                tr(
                  fr: 'Suivi GPS',
                  en: 'GPS tracking',
                  es: 'Seguimiento GPS',
                  ar: 'تتبع GPS',
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
                  fr: 'Vos trajets payés en cours ou à venir.',
                  en: 'Your paid current or upcoming trips.',
                  es: 'Sus trayectos pagados en curso o próximos.',
                  ar: 'رحلاتك المدفوعة الحالية أو القادمة.',
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: mutedColor,
                ),
              ),
              const SizedBox(height: 18),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (reservations.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_off_outlined,
                        size: 54,
                        color: mutedColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr(
                          fr: 'Aucun trajet à suivre',
                          en: 'No trip to track',
                          es: 'Ningún trayecto para seguir',
                          ar: 'لا توجد رحلة للتتبع',
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...reservations.map(
                  (reservation) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GestureDetector(
                      onTap: () {
                        context.push(
                          AppRoutes.trackingDetail,
                          extra: reservation,
                        );
                      },
                      child: Container(
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
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${reservation.dateDepart} • ${reservation.heureFormatee}',
                              style: TextStyle(
                                fontSize: 14,
                                color: mutedColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${tr(fr: 'Véhicule', en: 'Vehicle', es: 'Vehículo', ar: 'المركبة')} : ${reservation.vehiculeImmatriculation}',
                              style: TextStyle(
                                fontSize: 14,
                                color: mutedColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: Color(0xFF3158F5),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  tr(
                                    fr: 'Voir le suivi GPS',
                                    en: 'View GPS tracking',
                                    es: 'Ver seguimiento GPS',
                                    ar: 'عرض تتبع GPS',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3158F5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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