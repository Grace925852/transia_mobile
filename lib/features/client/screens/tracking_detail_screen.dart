import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:transia_mobile/core/location/location_adress_service.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/settings/app_preferences_controller.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/client/models/client_trip_tracking_model.dart';
import 'package:transia_mobile/features/client/models/reservation_model.dart';
import 'package:transia_mobile/features/client/services/client_trip_tracking_service.dart';

class TrackingDetailScreen extends StatefulWidget {
  final ReservationModel reservation;

  const TrackingDetailScreen({
    super.key,
    required this.reservation,
  });

  @override
  State<TrackingDetailScreen> createState() =>
      _TrackingDetailScreenState();
}

class _TrackingDetailScreenState
    extends State<TrackingDetailScreen> {
  late final SecureStorageService secureStorageService;
  late final ApiClient apiClient;
  late final ClientTripTrackingService trackingService;

  Timer? refreshTimer;

  bool isLoading = true;
  bool isRefreshing = false;
  bool isAddressLoading = false;

  String? errorMessage;

  String readableAddress =
      'Position non encore disponible';

  double? lastGeocodedLatitude;
  double? lastGeocodedLongitude;

  ClientTripTrackingModel? tracking;

  final MapController mapController = MapController();
  bool isMapReady = false;

  AppPreferencesController get prefs =>
      AppPreferencesController.instance;

  @override
  void initState() {
    super.initState();

    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);

    trackingService = ClientTripTrackingService(
      apiClient: apiClient,
    );

    loadTracking();

    refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        loadTracking(
          silent: true,
        );
      },
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    refreshTimer = null;
    super.dispose();
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

  Future<void> loadTracking({
    bool silent = false,
  }) async {
    if (!mounted) {
      return;
    }

    setState(() {
      if (silent) {
        isRefreshing = true;
      } else {
        isLoading = true;
      }

      errorMessage = null;
    });

    try {
      final result =
          await trackingService.getTrackingByTripId(
        widget.reservation.trajetId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        tracking = result;
        isLoading = false;
        isRefreshing = false;
      });

      _moveMapToPosition(result?.dernierePosition);

      await _updateReadableAddress(
        result?.dernierePosition,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        isRefreshing = false;
        errorMessage = _cleanError(error);
      });
    }
  }

  void _moveMapToPosition(
    ClientGpsPositionModel? position,
  ) {
    if (position == null || !isMapReady) {
      return;
    }

    mapController.move(
      LatLng(position.latitude, position.longitude),
      mapController.camera.zoom,
    );
  }

  Future<void> _updateReadableAddress(
    ClientGpsPositionModel? position,
  ) async {
    if (position == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        readableAddress =
            'Position non encore disponible';
        isAddressLoading = false;
      });

      return;
    }

    final sameArea =
        lastGeocodedLatitude != null &&
        lastGeocodedLongitude != null &&
        (position.latitude -
                    lastGeocodedLatitude!)
                .abs() <
            0.001 &&
        (position.longitude -
                    lastGeocodedLongitude!)
                .abs() <
            0.001;

    if (sameArea) {
      return;
    }

    if (mounted) {
      setState(() {
        isAddressLoading = true;
      });
    }

    final address =
        await LocationAddressService.instance
            .getReadableAddress(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      readableAddress = address;
      isAddressLoading = false;

      lastGeocodedLatitude =
          position.latitude;

      lastGeocodedLongitude =
          position.longitude;
    });
  }

  Color _statusColor(
    ClientTripTrackingModel? value,
  ) {
    if (value?.isEnCours == true) {
      return const Color(0xFF10B981);
    }

    if (value?.isPause == true) {
      return const Color(0xFFF59E0B);
    }

    if (value?.isTermine == true) {
      return const Color(0xFF3158F5);
    }

    if (value?.isAnnule == true) {
      return const Color(0xFFEF4444);
    }

    return const Color(0xFF6B7280);
  }

  IconData _statusIcon(
    ClientTripTrackingModel? value,
  ) {
    if (value?.isEnCours == true) {
      return Icons.directions_bus_filled_rounded;
    }

    if (value?.isPause == true) {
      return Icons.pause_circle_outline_rounded;
    }

    if (value?.isTermine == true) {
      return Icons.check_circle_outline_rounded;
    }

    if (value?.isAnnule == true) {
      return Icons.cancel_outlined;
    }

    return Icons.schedule_rounded;
  }

  String get departureCity {
    final backendValue =
        tracking?.villeDepart.trim() ?? '';

    if (backendValue.isNotEmpty) {
      return backendValue;
    }

    return widget.reservation.villeDepart;
  }

  String get arrivalCity {
    final backendValue =
        tracking?.villeArrivee.trim() ?? '';

    if (backendValue.isNotEmpty) {
      return backendValue;
    }

    return widget.reservation.villeArrivee;
  }

  String get vehicleLabel {
    final vehicle =
        tracking?.vehicule.trim() ?? '';

    final registration =
        tracking?.immatriculation.trim() ?? '';

    if (vehicle.isNotEmpty &&
        registration.isNotEmpty) {
      return '$vehicle • $registration';
    }

    if (registration.isNotEmpty) {
      return registration;
    }

    if (widget.reservation
        .vehiculeImmatriculation
        .trim()
        .isNotEmpty) {
      return widget
          .reservation
          .vehiculeImmatriculation;
    }

    return 'Non renseigné';
  }

  String get driverLabel {
    final driver =
        tracking?.chauffeurNom.trim() ?? '';

    if (driver.isEmpty) {
      return 'Non renseigné';
    }

    return driver;
  }

  String get statusLabel {
    return tracking?.statutLabel ??
        'Départ non encore effectué';
  }

  Widget _buildRouteCard(
    ThemeData theme,
  ) {
    final color = _statusColor(tracking);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _CityPoint(
                title: departureCity,
                subtitle: tr(
                  fr: 'Départ',
                  en: 'Departure',
                  es: 'Salida',
                  ar: 'المغادرة',
                ),
                color: const Color(0xFF3158F5),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.directions_bus_rounded,
                        color: color,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.20),
                          borderRadius:
                              BorderRadius.circular(999),
                        ),
                        child: FractionallySizedBox(
                          alignment:
                              Alignment.centerLeft,
                          widthFactor:
                              tracking?.isTermine == true
                                  ? 1
                                  : tracking?.isEnCours ==
                                          true
                                      ? 0.55
                                      : tracking?.isPause ==
                                              true
                                          ? 0.55
                                          : 0.08,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius:
                                  BorderRadius.circular(
                                999,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _CityPoint(
                title: arrivalCity,
                subtitle: tr(
                  fr: 'Destination',
                  en: 'Destination',
                  es: 'Destino',
                  ar: 'الوجهة',
                ),
                color: const Color(0xFF10B981),
                alignEnd: true,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  _statusIcon(tracking),
                  color: color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                if (isRefreshing)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(
    ThemeData theme,
  ) {
    final position = tracking?.dernierePosition;

    if (position == null) {
      return const SizedBox.shrink();
    }

    final busPoint = LatLng(
      position.latitude,
      position.longitude,
    );

    final color = _statusColor(tracking);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: busPoint,
                initialZoom: 15,
                onMapReady: () {
                  isMapReady = true;
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.transia.transia_mobile',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: busPoint,
                      width: 46,
                      height: 46,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.cardColor.withValues(
                    alpha: 0.9,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '© OpenStreetMap',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionCard(
    ThemeData theme,
  ) {
    final position = tracking?.dernierePosition;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF3158F5,
                  ).withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF3158F5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(
                        fr: 'Position actuelle',
                        en: 'Current position',
                        es: 'Posición actual',
                        ar: 'الموقع الحالي',
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAddressLoading
                          ? tr(
                              fr:
                                  'Recherche du lieu...',
                              en:
                                  'Searching location...',
                              es:
                                  'Buscando ubicación...',
                              ar:
                                  'جارٍ البحث عن الموقع...',
                            )
                          : readableAddress,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          _TrackingInfoRow(
            icon: Icons.speed_rounded,
            label: tr(
              fr: 'Vitesse',
              en: 'Speed',
              es: 'Velocidad',
              ar: 'السرعة',
            ),
            value:
                position?.vitesseFormatee ?? '-',
          ),
          _TrackingInfoRow(
            icon: Icons.update_rounded,
            label: tr(
              fr: 'Dernière actualisation',
              en: 'Last update',
              es: 'Última actualización',
              ar: 'آخر تحديث',
            ),
            value:
                tracking
                    ?.derniereMiseAJourFormatee ??
                '-',
          ),
        ],
      ),
    );
  }

  Widget _buildTripInformationCard(
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            tr(
              fr: 'Informations du trajet',
              en: 'Trip information',
              es: 'Información del viaje',
              ar: 'معلومات الرحلة',
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 16),
          _TrackingInfoRow(
            icon: Icons.calendar_today_outlined,
            label: tr(
              fr: 'Date',
              en: 'Date',
              es: 'Fecha',
              ar: 'التاريخ',
            ),
            value: widget.reservation.dateDepart,
          ),
          _TrackingInfoRow(
            icon: Icons.access_time_rounded,
            label: tr(
              fr: 'Heure prévue',
              en: 'Scheduled time',
              es: 'Hora prevista',
              ar: 'الوقت المتوقع',
            ),
            value:
                widget.reservation.heureFormatee,
          ),
          _TrackingInfoRow(
            icon: Icons.person_outline_rounded,
            label: tr(
              fr: 'Chauffeur',
              en: 'Driver',
              es: 'Conductor',
              ar: 'السائق',
            ),
            value: driverLabel,
          ),
          _TrackingInfoRow(
            icon:
                Icons.directions_bus_outlined,
            label: tr(
              fr: 'Véhicule',
              en: 'Vehicle',
              es: 'Vehículo',
              ar: 'المركبة',
            ),
            value: vehicleLabel,
          ),
          if (tracking?.dateDemarrage != null)
            _TrackingInfoRow(
              icon: Icons.play_circle_outline,
              label: tr(
                fr: 'Départ réel',
                en: 'Actual departure',
                es: 'Salida real',
                ar: 'المغادرة الفعلية',
              ),
              value:
                  tracking!.dateDemarrageFormatee,
            ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(
    ThemeData theme,
  ) {
    final message = tracking?.message.trim() ?? '';

    if (message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF59E0B,
        ).withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(
            0xFFF59E0B,
          ).withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTrackingCard(
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(
                0xFF3158F5,
              ).withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              size: 34,
              color: Color(0xFF3158F5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr(
              fr:
                  'Le suivi n’a pas encore commencé',
              en:
                  'Tracking has not started yet',
              es:
                  'El seguimiento aún no ha comenzado',
              ar:
                  'لم يبدأ التتبع بعد',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              fr:
                  'La position du véhicule apparaîtra dès que le chauffeur démarrera le trajet.',
              en:
                  'The vehicle position will appear when the driver starts the trip.',
              es:
                  'La posición del vehículo aparecerá cuando el conductor inicie el viaje.',
              ar:
                  'سيظهر موقع المركبة عندما يبدأ السائق الرحلة.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: loadTracking,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              tr(
                fr: 'Actualiser',
                en: 'Refresh',
                es: 'Actualizar',
                ar: 'تحديث',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          tr(
            fr: 'Suivi du trajet',
            en: 'Trip tracking',
            es: 'Seguimiento del viaje',
            ar: 'تتبع الرحلة',
          ),
        ),
        actions: [
          IconButton(
            tooltip: tr(
              fr: 'Actualiser',
              en: 'Refresh',
              es: 'Actualizar',
              ar: 'تحديث',
            ),
            onPressed: () {
              loadTracking();
            },
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadTracking,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            30,
          ),
          children: [
            if (isLoading)
              const SizedBox(
                height: 450,
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else if (errorMessage != null)
              _TrackingErrorCard(
                message: errorMessage!,
                onRetry: loadTracking,
              )
            else ...[
              _buildRouteCard(theme),
              const SizedBox(height: 16),
              if (tracking == null)
                _buildNoTrackingCard(theme)
              else ...[
                if (tracking!.dernierePosition != null) ...[
                  _buildMapCard(theme),
                  const SizedBox(height: 16),
                ],
                _buildPositionCard(theme),
                const SizedBox(height: 16),
                _buildTripInformationCard(
                  theme,
                ),
                if (tracking!.message
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildMessageCard(theme),
                ],
              ],
            ],
          ],
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

class _CityPoint extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final bool alignEnd;

  const _CityPoint({
    required this.title,
    required this.subtitle,
    required this.color,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.25),
                width: 5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title.trim().isEmpty ? '-' : title,
            textAlign:
                alignEnd ? TextAlign.right : TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign:
                alignEnd ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TrackingInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue =
        value.trim().isEmpty ? '-' : value;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              safeValue,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
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

class _TrackingErrorCard
    extends StatelessWidget {
  final String message;
  final Future<void> Function({
    bool silent,
  }) onRetry;

  const _TrackingErrorCard({
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
            onPressed: () {
              onRetry();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}