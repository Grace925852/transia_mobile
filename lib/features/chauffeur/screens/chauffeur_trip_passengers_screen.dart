import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/location/location_adress_service.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/chauffeur/models/chauffeur_passenger_model.dart';
import 'package:transia_mobile/features/chauffeur/models/chauffeur_trip_model.dart';
import 'package:transia_mobile/features/chauffeur/models/trip_tracking_model.dart';
import 'package:transia_mobile/features/chauffeur/services/chauffeur_service.dart';
import 'package:transia_mobile/features/chauffeur/services/trip_tracking_service.dart';

class ChauffeurTripPassengersScreen extends StatefulWidget {
  final ChauffeurTripModel trip;

  const ChauffeurTripPassengersScreen({
    super.key,
    required this.trip,
  });

  @override
  State<ChauffeurTripPassengersScreen> createState() =>
      _ChauffeurTripPassengersScreenState();
}

class _ChauffeurTripPassengersScreenState
    extends State<ChauffeurTripPassengersScreen> {
  late final SecureStorageService secureStorageService;
  late final ApiClient apiClient;
  late final ChauffeurService chauffeurService;
  late final TripTrackingService trackingService;

  StreamSubscription<Position>? positionSubscription;

  bool isLoadingPassengers = true;
  bool isLoadingTracking = true;
  bool isTrackingActionLoading = false;
  bool isSendingGps = false;
  bool isAddressLoading = false;

  bool isLoadingColis = false;
  String? colisError;
  List<Map<String, dynamic>> colisList = [];

  bool hasChanged = false;

  String? passengersError;
  String? trackingError;
  String? gpsError;

  String currentReadableAddress = 'Position non encore disponible';

  double? lastGeocodedLatitude;
  double? lastGeocodedLongitude;

  List<ChauffeurPassengerModel> passengers = [];
  TripTrackingModel? tracking;

  int get totalColisCount => colisList.length;
  int get colisChargesCount => colisList
      .where((c) =>
          c['statut'] == 'EN_TRANSIT' ||
          c['statut'] == 'ARRIVE_EN_AGENCE' ||
          c['statut'] == 'LIVRE')
      .length;
  double get totalColisPoidsKg => colisList.fold(
      0.0,
      (sum, c) =>
          sum + ((c['poidsReel'] as num?)?.toDouble() ?? 0.0));

  int get expectedCount => passengers.length;

  int get presentCount {
    return passengers.where((passenger) => passenger.present).length;
  }

  int get remainingCount {
    final remaining = expectedCount - presentCount;
    return remaining < 0 ? 0 : remaining;
  }

  List<ChauffeurPassengerModel> get presentPassengers {
    return passengers.where((passenger) => passenger.present).toList();
  }

  List<ChauffeurPassengerModel> get waitingPassengers {
    return passengers.where((passenger) => !passenger.present).toList();
  }

  @override
  void initState() {
    super.initState();

    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);

    chauffeurService = ChauffeurService(
      apiClient: apiClient,
    );

    trackingService = TripTrackingService(
      apiClient: apiClient,
    );

    _initializeScreen();
  }

  @override
  void dispose() {
    positionSubscription?.cancel();
    positionSubscription = null;
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await Future.wait([
      loadPassengers(),
      loadTracking(),
      loadColis(),
    ]);
  }

  Future<void> refreshScreen() async {
    await Future.wait([
      loadPassengers(),
      loadTracking(),
      loadColis(),
    ]);
  }

  // ============================================================
  // PASSAGERS
  // ============================================================

  Future<void> loadPassengers() async {
    if (mounted) {
      setState(() {
        isLoadingPassengers = true;
        passengersError = null;
      });
    }

    try {
      final result = await chauffeurService.getPaidPassengersForTrip(
        widget.trip.id,
      );

      if (!mounted) return;

      setState(() {
        passengers = result;
        isLoadingPassengers = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingPassengers = false;
        passengersError = _cleanError(e);
      });
    }
  }

  Future<void> markPresent(
    ChauffeurPassengerModel passenger,
  ) async {
    if (passenger.present) return;

    try {
      await chauffeurService.markPassengerPresent(
        tripId: widget.trip.id,
        billetId: passenger.billetId,
      );

      if (!mounted) return;

      setState(() {
        passengers = passengers.map((item) {
          if (item.billetId == passenger.billetId) {
            return item.copyWith(present: true);
          }

          return item;
        }).toList();

        hasChanged = true;
      });

      _showMessage('Client marqué présent.');
    } catch (e) {
      if (!mounted) return;
      _showMessage(_cleanError(e));
    }
  }

  // ============================================================
  // COLIS & FRET EN SOUTE
  // ============================================================

  Future<void> loadColis() async {
    if (!mounted) return;
    setState(() {
      isLoadingColis = true;
      colisError = null;
    });

    try {
      final response =
          await apiClient.dio.get('/api/v1/colis/trajet/${widget.trip.id}');
      if (!mounted) return;

      if (response.data is List) {
        final list = (response.data as List)
            .where((e) => e is Map)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        setState(() {
          colisList = list;
          isLoadingColis = false;
        });
      } else {
        setState(() {
          colisList = [];
          isLoadingColis = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingColis = false;
        colisError = _cleanError(e);
      });
    }
  }

  Future<void> chargerColisItem(String colisId) async {
    try {
      final updated = await chauffeurService.chargerColis(
        colisId: colisId,
        tripId: widget.trip.id,
      );

      if (!mounted) return;

      setState(() {
        colisList = colisList.map((c) {
          if (c['id']?.toString() == colisId) {
            return updated;
          }
          return c;
        }).toList();
        hasChanged = true;
      });

      _showMessage('📦 Colis chargé en soute avec succès !');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Erreur : ${_cleanError(e)}');
    }
  }

  Future<void> openScanScreen() async {
    await context.push(
      AppRoutes.chauffeurScan,
      extra: {
        'trip': widget.trip,
        'passengers': passengers,
      },
    );

    if (!mounted) return;
    await refreshScreen();
  }

  Future<void> openReportProblemScreen() async {
    final result = await context.push(
      AppRoutes.chauffeurReportProblem,
      extra: widget.trip,
    );

    if (!mounted) return;

    if (result == true) {
      _showMessage(
        'Problème signalé avec succès.',
      );
    }
  }

  // ============================================================
  // CHARGEMENT DU SUIVI
  // ============================================================

  Future<void> loadTracking() async {
    if (mounted) {
      setState(() {
        isLoadingTracking = true;
        trackingError = null;
      });
    }

    try {
      final result = await trackingService.getTrackingByTripId(
        widget.trip.id,
      );

      if (!mounted) return;

      setState(() {
        tracking = result;
        isLoadingTracking = false;
      });

      await _updateReadableAddress(
        result?.dernierePosition,
      );

      if (result?.isEnCours == true) {
        await _startGpsStream();
      } else {
        await _stopGpsStream();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingTracking = false;
        trackingError = _cleanError(e);
      });
    }
  }

  // ============================================================
  // DÉMARRAGE DU TRAJET
  // ============================================================

  Future<void> startTripTracking() async {
    if (isTrackingActionLoading) return;

    final permissionGranted = await _ensureLocationPermission();

    if (!permissionGranted) return;

    setState(() {
      isTrackingActionLoading = true;
      trackingError = null;
      gpsError = null;
    });

    try {
      final result = await trackingService.startTracking(
        widget.trip.id,
      );

      if (!mounted) return;

      setState(() {
        tracking = result;
        isTrackingActionLoading = false;
        hasChanged = true;
      });

      await _sendCurrentPositionOnce();
      await _startGpsStream();

      if (!mounted) return;

      _showMessage(
        'Le trajet a démarré. Le partage de position est actif.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isTrackingActionLoading = false;
        trackingError = _cleanError(e);
      });

      _showMessage(trackingError!);
    }
  }

  // ============================================================
  // PAUSE
  // ============================================================

  Future<void> pauseTripTracking() async {
    final currentTracking = tracking;

    if (currentTracking == null || isTrackingActionLoading) {
      return;
    }

    setState(() {
      isTrackingActionLoading = true;
      trackingError = null;
    });

    try {
      final result = await trackingService.pauseTracking(
        currentTracking.id,
      );

      await _stopGpsStream();

      if (!mounted) return;

      setState(() {
        tracking = result;
        isTrackingActionLoading = false;
        hasChanged = true;
      });

      _showMessage(
        'Le trajet est maintenant en pause.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isTrackingActionLoading = false;
        trackingError = _cleanError(e);
      });

      _showMessage(trackingError!);
    }
  }

  // ============================================================
  // REPRISE
  // ============================================================

  Future<void> resumeTripTracking() async {
    final currentTracking = tracking;

    if (currentTracking == null || isTrackingActionLoading) {
      return;
    }

    final permissionGranted = await _ensureLocationPermission();

    if (!permissionGranted) return;

    setState(() {
      isTrackingActionLoading = true;
      trackingError = null;
      gpsError = null;
    });

    try {
      final result = await trackingService.resumeTracking(
        currentTracking.id,
      );

      if (!mounted) return;

      setState(() {
        tracking = result;
        isTrackingActionLoading = false;
        hasChanged = true;
      });

      await _sendCurrentPositionOnce();
      await _startGpsStream();

      if (!mounted) return;

      _showMessage(
        'Le trajet a repris. Le partage de position est actif.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isTrackingActionLoading = false;
        trackingError = _cleanError(e);
      });

      _showMessage(trackingError!);
    }
  }

  // ============================================================
  // FIN DU TRAJET
  // ============================================================

  Future<void> finishTripTracking() async {
    final currentTracking = tracking;

    if (currentTracking == null || isTrackingActionLoading) {
      return;
    }

    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Terminer le trajet'),
          content: const Text(
            'Voulez-vous confirmer la fin de ce trajet ? '
            'Le partage de position GPS sera arrêté.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Non'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Oui, terminer'),
            ),
          ],
        );
      },
    );

    if (confirmation != true) return;

    setState(() {
      isTrackingActionLoading = true;
      trackingError = null;
    });

    try {
      if (currentTracking.isEnCours) {
        await _sendCurrentPositionOnce(
          showError: false,
        );
      }

      final result = await trackingService.finishTracking(
        currentTracking.id,
      );

      await _stopGpsStream();

      if (!mounted) return;

      setState(() {
        tracking = result;
        isTrackingActionLoading = false;
        hasChanged = true;
      });

      _showMessage(
        'Trajet terminé avec succès.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isTrackingActionLoading = false;
        trackingError = _cleanError(e);
      });

      _showMessage(trackingError!);
    }
  }

  // ============================================================
  // PERMISSIONS GPS
  // ============================================================

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return false;

      final openSettings = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Localisation désactivée'),
            content: const Text(
              'Activez la localisation du téléphone pour démarrer '
              'le suivi du trajet.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Ouvrir les paramètres'),
              ),
            ],
          );
        },
      );

      if (openSettings == true) {
        await Geolocator.openLocationSettings();
      }

      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (mounted) {
        _showMessage(
          'La permission de localisation a été refusée.',
        );
      }

      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;

      final openSettings = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Permission requise'),
            content: const Text(
              'La localisation a été refusée définitivement. '
              'Autorisez-la dans les paramètres de l’application.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Fermer'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Paramètres'),
              ),
            ],
          );
        },
      );

      if (openSettings == true) {
        await Geolocator.openAppSettings();
      }

      return false;
    }

    return true;
  }

  // ============================================================
  // ÉCOUTE GPS
  // ============================================================

  Future<void> _startGpsStream() async {
    if (positionSubscription != null) {
      return;
    }

    final currentTracking = tracking;

    if (currentTracking == null || !currentTracking.isEnCours) {
      return;
    }

    final permissionGranted = await _ensureLocationPermission();

    if (!permissionGranted) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    );

    positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) async {
        final activeTracking = tracking;

        if (activeTracking == null || !activeTracking.isEnCours) {
          return;
        }

        await _sendPositionToBackend(
          trackingId: activeTracking.id,
          position: position,
        );
      },
      onError: (Object error) {
        if (!mounted) return;

        setState(() {
          gpsError = 'Erreur GPS : $error';
        });
      },
    );
  }

  Future<void> _stopGpsStream() async {
    await positionSubscription?.cancel();
    positionSubscription = null;
  }

  Future<void> _sendCurrentPositionOnce({
    bool showError = true,
  }) async {
    final currentTracking = tracking;

    if (currentTracking == null || !currentTracking.isEnCours) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await _sendPositionToBackend(
        trackingId: currentTracking.id,
        position: position,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        gpsError = _cleanError(e);
      });

      if (showError) {
        _showMessage(gpsError!);
      }
    }
  }

  Future<void> _sendPositionToBackend({
    required int trackingId,
    required Position position,
  }) async {
    if (isSendingGps) return;

    isSendingGps = true;

    try {
      final speedKmh = position.speed < 0
          ? 0.0
          : position.speed * 3.6;

      final savedPosition = await trackingService.sendPosition(
        trackingId: trackingId,
        latitude: position.latitude,
        longitude: position.longitude,
        vitesse: speedKmh,
        precisionGps: position.accuracy,
        altitude: position.altitude,
      );

      if (!mounted) return;

      final currentTracking = tracking;

      if (currentTracking != null) {
        setState(() {
          gpsError = null;

          tracking = currentTracking.copyWith(
            derniereMiseAJour:
                savedPosition.dateHeure ?? DateTime.now(),
            dernierePosition: savedPosition,
          );
        });
      }

      await _updateReadableAddress(savedPosition);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        gpsError = _cleanError(e);
      });
    } finally {
      isSendingGps = false;
    }
  }

  // ============================================================
  // CONVERSION COORDONNÉES → QUARTIER / VILLE
  // ============================================================

  Future<void> _updateReadableAddress(
    TripGpsPositionModel? position,
  ) async {
    if (position == null) {
      if (!mounted) return;

      setState(() {
        currentReadableAddress = 'Position non encore disponible';
        isAddressLoading = false;
      });

      return;
    }

    final previousLatitude = lastGeocodedLatitude;
    final previousLongitude = lastGeocodedLongitude;

    final isSameArea = previousLatitude != null &&
        previousLongitude != null &&
        (position.latitude - previousLatitude).abs() < 0.001 &&
        (position.longitude - previousLongitude).abs() < 0.001;

    if (isSameArea) {
      return;
    }

    if (mounted) {
      setState(() {
        isAddressLoading = true;
      });
    }

    final address = await LocationAddressService.instance.getReadableAddress(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    if (!mounted) return;

    setState(() {
      currentReadableAddress = address;
      isAddressLoading = false;
      lastGeocodedLatitude = position.latitude;
      lastGeocodedLongitude = position.longitude;
    });
  }

  // ============================================================
  // INTERFACE DU SUIVI
  // ============================================================

  Color _trackingStatusColor(
    TripTrackingModel? value,
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

  Widget _buildTrackingActions() {
    if (isTrackingActionLoading) {
      return const SizedBox(
        height: 52,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentTracking = tracking;

    if (currentTracking == null || currentTracking.isProgramme) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: startTripTracking,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Démarrer le trajet'),
        ),
      );
    }

    if (currentTracking.isEnCours) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: pauseTripTracking,
                    icon: const Icon(Icons.pause_rounded),
                    label: const Text('Mettre en pause'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: finishTripTracking,
                    icon: const Icon(Icons.flag_rounded),
                    label: const Text('Terminer'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 18,
                color: Color(0xFF10B981),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Le partage automatique de la position est actif.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (currentTracking.isPause) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: resumeTripTracking,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Reprendre'),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: finishTripTracking,
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Terminer'),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _trackingStatusColor(currentTracking).withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        currentTracking.isTermine
            ? 'Ce trajet est terminé. Le partage GPS est arrêté.'
            : 'Ce trajet a été annulé.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _trackingStatusColor(currentTracking),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTrackingCard(
    ThemeData theme,
  ) {
    final statusColor = _trackingStatusColor(tracking);
    final position = tracking?.dernierePosition;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Suivi du trajet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              if (!isLoadingTracking)
                _StatusBadge(
                  text: tracking?.statutLabel ?? 'Non démarré',
                  color: statusColor,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoadingTracking)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            _InfoRow(
              label: 'Statut',
              value: tracking?.statutLabel ?? 'Trajet programmé',
            ),
            _InfoRow(
              label: 'Position actuelle',
              value: isAddressLoading
                  ? 'Recherche du lieu...'
                  : currentReadableAddress,
            ),
            _InfoRow(
              label: 'Vitesse',
              value: position?.vitesseFormatee ?? '-',
            ),
            _InfoRow(
              label: 'Dernière mise à jour',
              value: tracking?.derniereMiseAJourFormatee ?? '-',
            ),
            if (tracking?.message.trim().isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  tracking!.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            if (trackingError != null &&
                trackingError!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _ErrorText(message: trackingError!),
            ],
            if (gpsError != null && gpsError!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _ErrorText(message: gpsError!),
            ],
            const SizedBox(height: 16),
            _buildTrackingActions(),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // INTERFACE PASSAGERS
  // ============================================================

  Widget _buildPassengerCard(
    ChauffeurPassengerModel passenger,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: passenger.present
            ? Border.all(
                color: const Color(0xFF10B981).withOpacity(0.25),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  passenger.passagerNom.trim().isEmpty
                      ? 'Passager'
                      : passenger.passagerNom,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              _StatusBadge(
                text: passenger.present ? 'Présent' : 'En attente',
                color: passenger.present
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MiniInfo(
            icon: Icons.event_seat_outlined,
            text: 'Siège : ${passenger.siege}',
          ),
          const SizedBox(height: 7),
          _MiniInfo(
            icon: Icons.badge_outlined,
            text: 'Billet : ${passenger.billetId}',
          ),
          const SizedBox(height: 7),
          _MiniInfo(
            icon: Icons.receipt_long_outlined,
            text: 'Réservation : ${passenger.reservationId}',
          ),
          if (passenger.clientResponsable.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            _MiniInfo(
              icon: Icons.person_outline_rounded,
              text: 'Responsable : ${passenger.clientResponsable}',
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: passenger.present
                  ? null
                  : () => markPresent(passenger),
              icon: Icon(
                passenger.present
                    ? Icons.check_circle_rounded
                    : Icons.person_add_alt_1_rounded,
              ),
              label: Text(
                passenger.present
                    ? 'Déjà présent'
                    : 'Marquer présent',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);


    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
        didPop,
        result,
      ) {
        if (!didPop) {
          context.pop(hasChanged);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FF),
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              context.pop(hasChanged);
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
            ),
          ),
          title: const Text('Détail du trajet'),
          actions: [
            IconButton(
              tooltip: 'Scanner un billet',
              onPressed: openScanScreen,
              icon: const Icon(
                Icons.qr_code_scanner_rounded,
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: refreshScreen,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              32,
            ),
            children: [
              // Informations générales
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.trip.trajetLabel,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      label: 'Date',
                      value: widget.trip.dateDepart,
                    ),
                    _InfoRow(
                      label: 'Heure',
                      value: widget.trip.heureFormatee,
                    ),
                    _InfoRow(
                      label: 'Véhicule',
                      value: widget.trip.vehiculeImmatriculation,
                    ),
                    const Divider(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: _CounterBox(
                            label: 'Attendus',
                            value: expectedCount,
                            icon: Icons.groups_2_outlined,
                            color: const Color(0xFF3158F5),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CounterBox(
                            label: 'Présents',
                            value: presentCount,
                            icon: Icons.check_circle_outline_rounded,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CounterBox(
                            label: 'Restants',
                            value: remainingCount,
                            icon: Icons.hourglass_bottom_rounded,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: openScanScreen,
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                        ),
                        label: const Text(
                          'Scanner et cocher présent',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: openReportProblemScreen,
                        icon: const Icon(
                          Icons.report_problem_outlined,
                        ),
                        label: const Text(
                          'Signaler un problème',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Suivi GPS
              _buildTrackingCard(theme),

              const SizedBox(height: 20),

              // Passagers
              if (isLoadingPassengers)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (passengersError != null)
                _ErrorCard(
                  message: passengersError!,
                  onRetry: loadPassengers,
                )
              else if (passengers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 46,
                        color: Color(0xFF9CA3AF),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Aucun passager payé trouvé pour ce trajet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                const Text(
                  'Clients déjà présents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 10),
                if (presentPassengers.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'Aucun client présent pour le moment.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  )
                else
                  ...presentPassengers.map(
                    (passenger) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PresentPassengerTile(
                        passenger: passenger,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                const Text(
                  'Clients à embarquer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 10),

                if (waitingPassengers.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF10B981),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tous les clients ont été marqués présents.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...waitingPassengers.map(
                    (passenger) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPassengerCard(
                        passenger,
                        theme,
                      ),
                    ),
                  ),
                const SizedBox(height: 28),
                _buildColisSection(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColisSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📦 Fret & Colis en Soute',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _CounterBox(
                  label: 'Colis Total',
                  value: totalColisCount,
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CounterBox(
                  label: 'En Soute',
                  value: colisChargesCount,
                  icon: Icons.archive_outlined,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CounterBox(
                  label: 'Poids (kg)',
                  value: totalColisPoidsKg.toInt(),
                  icon: Icons.scale_outlined,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (isLoadingColis)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (colisError != null)
          _ErrorCard(message: colisError!, onRetry: loadColis)
        else if (colisList.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 40, color: Color(0xFF9CA3AF)),
                SizedBox(height: 8),
                Text(
                  'Aucun colis attribué à ce trajet pour le moment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          )
        else
          ...colisList.map((colis) => _buildColisCard(colis, theme)),
      ],
    );
  }

  Widget _buildColisCard(Map<String, dynamic> colis, ThemeData theme) {
    final statut = colis['statut']?.toString() ?? '';
    final isEnSoute = statut == 'EN_TRANSIT' ||
        statut == 'ARRIVE_EN_AGENCE' ||
        statut == 'LIVRE';
    final isPretACharger = statut == 'DEPOSE_EN_AGENCE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isEnSoute
            ? Border.all(
                color: const Color(0xFF10B981).withOpacity(0.4), width: 1.5)
            : Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  colis['numeroSuivi'] ?? 'TRS-XXXXXX',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D4ED8),
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              if (colis['poidsReel'] != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${colis['poidsReel']} kg',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7E22CE),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            colis['description']?.toString() ?? 'Sans description',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Exp: ${colis['expediteurNom'] ?? '—'}  ➜  Dest: ${colis['destinataireNom'] ?? '—'} (${colis['destinataireTelephone'] ?? ''})',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          if (isPretACharger)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => chargerColisItem(colis['id'].toString()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.archive_outlined, size: 18),
                label: const Text(
                  '📦 Charger en soute',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            )
          else if (isEnSoute)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Color(0xFF059669), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Colis chargé en soute (En transit)',
                    style: TextStyle(
                      color: Color(0xFF047857),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              'Statut : $statut',
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
        ],
      ),
    );
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }

  void _showMessage(String message) {
    if (!mounted || message.trim().isEmpty) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }
}

// ============================================================
// WIDGETS
// ============================================================

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.trim().isEmpty ? '-' : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
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
            flex: 6,
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

class _CounterBox extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _CounterBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 22,
            color: color,
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniInfo({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: const Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _PresentPassengerTile extends StatelessWidget {
  final ChauffeurPassengerModel passenger;

  const _PresentPassengerTile({
    required this.passenger,
  });

  @override
  Widget build(BuildContext context) {
    final passengerName = passenger.passagerNom.trim().isEmpty
        ? 'Passager'
        : passenger.passagerNom;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              passengerName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Text(
            passenger.siege,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String message;

  const _ErrorText({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 18,
          color: Colors.redAccent,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.redAccent,
            ),
          ),
        ),
      ],
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 44,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
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