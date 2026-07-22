import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/chauffeur/models/chauffeur_passenger_model.dart';
import 'package:transia_mobile/features/chauffeur/models/chauffeur_trip_model.dart';

class ChauffeurService {
  final ApiClient apiClient;
  final SecureStorageService secureStorageService = SecureStorageService();

  ChauffeurService({required this.apiClient});

  Future<String?> _getChauffeurId() async {
    final numericId = await secureStorageService.getNumericUserId();
    if (numericId != null && numericId.trim().isNotEmpty) {
      return numericId.trim();
    }

    final userId = await secureStorageService.getUserId();
    if (userId != null && userId.trim().isNotEmpty) {
      return userId.trim();
    }

    return null;
  }

  Future<SharedPreferences> _prefs() async {
    return SharedPreferences.getInstance();
  }

  String _presenceKey(String tripId) => 'chauffeur_present_$tripId';

  Future<Set<String>> getPresentBilletIds(String tripId) async {
    final prefs = await _prefs();
    final list = prefs.getStringList(_presenceKey(tripId)) ?? [];
    return list.toSet();
  }

  Future<void> markPassengerPresent({
    required String tripId,
    required String billetId,
  }) async {
    final prefs = await _prefs();
    final current = prefs.getStringList(_presenceKey(tripId)) ?? [];
    final updated = current.toSet()..add(billetId);
    await prefs.setStringList(_presenceKey(tripId), updated.toList());
  }

  Future<void> unmarkPassengerPresent({
    required String tripId,
    required String billetId,
  }) async {
    final prefs = await _prefs();
    final current = prefs.getStringList(_presenceKey(tripId)) ?? [];
    final updated = current.toSet()..remove(billetId);
    await prefs.setStringList(_presenceKey(tripId), updated.toList());
  }

  ChauffeurTripModel _mapTrip(Map<String, dynamic> json) {
    return ChauffeurTripModel.fromJson(json);
  }

  // Scopé par trajet côté serveur (le chauffeur n'a accès qu'aux réservations des trajets qui lui
  // sont affectés) plutôt que de charger toutes les réservations de la plateforme et filtrer ici.
  Future<List<Map<String, dynamic>>> _getReservationsForTrip(String tripId) async {
    final response = await apiClient.dio.get('/api/v1/reservations/trajet/$tripId/liste');

    if (response.data is! List) {
      return [];
    }

    return (response.data as List)
        .where((e) => e is Map)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  int _extractPassengerCountFromReservation(Map<String, dynamic> reservation) {
    final billets = reservation['billets'];
    if (billets is List && billets.isNotEmpty) {
      return billets.length;
    }

    final passagers = reservation['passagers'];
    if (passagers is List && passagers.isNotEmpty) {
      return passagers.length;
    }

    final nombrePlace =
        int.tryParse(reservation['nombrePlace']?.toString() ?? '');
    if (nombrePlace != null && nombrePlace > 0) {
      return nombrePlace;
    }

    final nombreSieges =
        int.tryParse(reservation['nombreSieges']?.toString() ?? '');
    if (nombreSieges != null && nombreSieges > 0) {
      return nombreSieges;
    }

    return 1;
  }

  String _extractResponsableName(Map<String, dynamic> reservation) {
    return reservation['nomResponsable']?.toString() ??
        reservation['clientNom']?.toString() ??
        reservation['responsable']?.toString() ??
        reservation['client']?['fullName']?.toString() ??
        reservation['client']?['nom']?.toString() ??
        reservation['user']?['fullName']?.toString() ??
        reservation['utilisateur']?['nom']?.toString() ??
        'Responsable';
  }

  List<ChauffeurPassengerModel> _extractPassengersFromReservation(
    Map<String, dynamic> reservation,
    String tripId,
    Set<String> presentBilletIds,
  ) {
    final reservationId =
        reservation['id']?.toString() ??
        reservation['reservationId']?.toString() ??
        '';
    final responsable = _extractResponsableName(reservation);

    final billetsRaw = reservation['billets'];
    final List<Map<String, dynamic>> billets = billetsRaw is List
        ? billetsRaw
            .where((e) => e is Map)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList()
        : [];

    if (billets.isNotEmpty) {
      return billets.asMap().entries.map((entry) {
        final index = entry.key;
        final billet = entry.value;

        final billetId = billet['id']?.toString() ??
            billet['billetId']?.toString() ??
            '$reservationId-$index';

        final rawName = billet['nomPassager']?.toString() ??
            billet['passagerNom']?.toString() ??
            billet['nom']?.toString() ??
            '';

        final passengerName = rawName.trim().isNotEmpty
            ? rawName.trim()
            : (index == 0 ? responsable : 'Invité N$index de $responsable');

        final backendPresent = billet['present'] == true ||
            billet['presence'] == true ||
            billet['statutPresence']?.toString().toUpperCase() == 'PRESENT';

        final localPresent = presentBilletIds.contains(billetId);

        return ChauffeurPassengerModel(
          reservationId: reservationId,
          billetId: billetId,
          trajetId: tripId,
          passagerNom: passengerName,
          siege: billet['numeroSiege']?.toString() ??
              billet['siege']?.toString() ??
              billet['seatNumber']?.toString() ??
              '-',
          paid: true,
          present: backendPresent || localPresent,
          clientResponsable: responsable,
          qrCode: billet['qrCode']?.toString() ??
              billet['qr']?.toString() ??
              '',
        );
      }).toList();
    }

    final count = _extractPassengerCountFromReservation(reservation);

    return List.generate(count, (index) {
      final billetId = '$reservationId-${index + 1}';
      return ChauffeurPassengerModel(
        reservationId: reservationId,
        billetId: billetId,
        trajetId: tripId,
        passagerNom:
            index == 0 ? responsable : 'Invité N$index de $responsable',
        siege: '-',
        paid: true,
        present: presentBilletIds.contains(billetId),
        clientResponsable: responsable,
        qrCode: '',
      );
    });
  }

  Future<List<ChauffeurTripModel>> getTrips() async {
    final chauffeurId = await _getChauffeurId();

    if (chauffeurId == null || chauffeurId.isEmpty) {
      throw Exception('Identifiant chauffeur introuvable.');
    }

    try {
      final response = await apiClient.dio.get('/api/v1/trajet');

      if (response.data is! List) {
        return [];
      }

      final allTrips = (response.data as List)
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final filteredTrips = allTrips.where((trip) {
        final tripChauffeurId = trip['chauffeurId']?.toString() ?? '';
        return tripChauffeurId == chauffeurId;
      }).toList();

      return filteredTrips.map(_mapTrip).toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ??
            'Impossible de charger les trajets du chauffeur.',
      );
    } catch (_) {
      throw Exception('Impossible de charger les trajets du chauffeur.');
    }
  }

  Future<int> getPassengerCountForTrip(String tripId) async {
    try {
      final reservations = await _getReservationsForTrip(tripId);

      int total = 0;
      for (final reservation in reservations) {
        total += _extractPassengerCountFromReservation(reservation);
      }

      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getPresentCountForTrip(String tripId) async {
    try {
      final passengers = await getPaidPassengersForTrip(tripId);
      return passengers.where((e) => e.present).length;
    } catch (_) {
      return 0;
    }
  }

  Future<List<ChauffeurPassengerModel>> getPaidPassengersForTrip(
    String tripId,
  ) async {
    try {
      final reservations = await _getReservationsForTrip(tripId);
      final presentBilletIds = await getPresentBilletIds(tripId);

      final List<ChauffeurPassengerModel> passengers = [];

      for (final reservation in reservations) {
        passengers.addAll(
          _extractPassengersFromReservation(
            reservation,
            tripId,
            presentBilletIds,
          ),
        );
      }

      return passengers;
    } catch (_) {
      return [];
    }
  }

  Future<ChauffeurPassengerModel> verifyTicketQr({
    required String tripId,
    required String qrData,
  }) async {
    final passengers = await getPaidPassengersForTrip(tripId);

    for (final passenger in passengers) {
      if (passenger.qrCode.trim().isNotEmpty &&
          passenger.qrCode.trim() == qrData.trim()) {
        return passenger;
      }
    }

    for (final passenger in passengers) {
      if (passenger.billetId.trim() == qrData.trim()) {
        return passenger;
      }
    }

    throw Exception('QR invalide ou billet introuvable.');
  }
}