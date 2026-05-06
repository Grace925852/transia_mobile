import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:transia_mobile/core/constants/api_constants.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/features/chauffeur/models/chauffeur_passenger_model.dart';
import 'package:transia_mobile/features/chauffeur/models/chauffeur_trip_model.dart';

class ChauffeurService {
  final ApiClient apiClient;

  ChauffeurService({required this.apiClient});

  Future<List<ChauffeurTripModel>> getTrips() async {
    try {
      final response = await apiClient.dio.get(ApiConstants.trajets);

      if (response.data is! List) return [];

      return (response.data as List)
          .where((item) => item is Map)
          .map((item) => ChauffeurTripModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ?? 'Impossible de charger les trajets.',
      );
    } catch (_) {
      throw Exception('Erreur inconnue lors du chargement des trajets.');
    }
  }

  Future<int> getPassengerCountForTrip(String trajetId) async {
    try {
      final response = await apiClient.dio.get(
        '/api/v1/reservations/trajet/$trajetId',
      );

      debugPrint('TRIP PASSENGER COUNT RESPONSE => ${response.data}');

      return int.tryParse(response.data.toString()) ?? 0;
    } on DioException catch (e) {
      debugPrint('TRIP PASSENGER COUNT ERROR => ${e.response?.data}');
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<List<ChauffeurPassengerModel>> getPassengersForTrip(String trajetId) async {
    try {
      final response = await apiClient.dio.get(ApiConstants.reservations);

      if (response.data is! List) return [];

      final List<ChauffeurPassengerModel> passengers = [];

      for (final item in response.data as List) {
        if (item is! Map) continue;

        final reservation = Map<String, dynamic>.from(item as Map);

        if ((reservation['trajetId'] ?? '').toString() != trajetId) {
          continue;
        }

        final billets = reservation['billets'];
        if (billets is List) {
          for (final billet in billets) {
            if (billet is Map) {
              passengers.add(
                ChauffeurPassengerModel.fromReservationAndTicket(
                  reservation: reservation,
                  ticket: Map<String, dynamic>.from(billet as Map),
                ),
              );
            }
          }
        }
      }

      return passengers;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ?? 'Impossible de charger les passagers.',
      );
    } catch (_) {
      throw Exception('Erreur inconnue lors du chargement des passagers.');
    }
  }
}