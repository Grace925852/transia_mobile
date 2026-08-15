import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:transia_mobile/core/constants/api_constants.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/features/client/models/reservation_model.dart';
import 'package:transia_mobile/features/client/models/reservation_request.dart';

class ReservationService {
  final ApiClient apiClient;

  ReservationService({required this.apiClient});

  Future<Map<String, dynamic>> createReservation(
    ReservationRequestModel request,
  ) async {
    try {
      final payload = request.toJson();
      debugPrint('CREATE RESERVATION PAYLOAD = $payload');

      final response = await apiClient.dio.post(
        ApiConstants.reservations,
        data: payload,
      );

      debugPrint('CREATE RESERVATION RESPONSE = ${response.data}');

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'data': response.data};
    } on DioException catch (e) {
      debugPrint('CREATE RESERVATION DIO STATUS = ${e.response?.statusCode}');
      debugPrint('CREATE RESERVATION DIO DATA = ${e.response?.data}');
      debugPrint('CREATE RESERVATION DIO MESSAGE = ${e.message}');

      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        throw Exception('Session expirée ou utilisateur non reconnu. Veuillez vous re-connecter.');
      }

      final responseData = e.response?.data;

      if (responseData is Map<String, dynamic>) {
        final message = responseData['message']?.toString();
        if (message != null && message.isNotEmpty) {
          throw Exception(message);
        }
      }

      throw Exception(
        responseData?.toString() ?? 'Impossible de créer la réservation.',
      );
    } catch (e) {
      debugPrint('CREATE RESERVATION UNKNOWN ERROR = $e');
      throw Exception('Erreur inconnue lors de la réservation.');
    }
  }

  Future<void> cancelReservation(String reservationId) async {
    try {
      await apiClient.dio.patch(
        '${ApiConstants.reservations}/$reservationId/annuler',
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;

      if (responseData is Map<String, dynamic>) {
        final message = responseData['message']?.toString();
        if (message != null && message.isNotEmpty) {
          throw Exception(message);
        }
      }

      throw Exception(
        responseData?.toString() ?? 'Impossible d’annuler la réservation.',
      );
    } catch (_) {
      throw Exception('Impossible d’annuler la réservation.');
    }
  }

  /// Réservations du client connecté, résolues côté serveur via le JWT (GET /reservations/me).
  /// Le backend enrichit chaque réservation avec le trajet complet (villes, véhicule, tarif) :
  /// plus besoin de charger les trajets séparément ni de filtrer par nom/identifiant en local.
  Future<List<ReservationModel>> getMyReservations() async {
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.reservations}/me',
      );

      if (response.data is! List) return [];

      final parsed = (response.data as List)
          .where((item) => item is Map)
          .map((item) => ReservationModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();

      parsed.sort((a, b) {
        final da = a.departureDateTime ?? DateTime(2100);
        final db = b.departureDateTime ?? DateTime(2100);
        return da.compareTo(db);
      });

      return parsed;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ??
            'Impossible de charger les réservations.',
      );
    } catch (e) {
      throw Exception('Erreur inconnue lors du chargement des réservations.');
    }
  }

  Future<List<ReservationModel>> getMyActiveReservations() async {
    final all = await getMyReservations();
    return all.where((item) => item.shouldShowInActiveReservations).toList();
  }

  Future<List<ReservationModel>> getMyHistoryReservations() async {
    final all = await getMyReservations();
    return all.where((item) => item.shouldShowInHistory).toList();
  }

  /// Sièges déjà occupés pour un trajet — utilisé pour construire le plan de sièges à la réservation.
  Future<List<String>> getOccupiedSeats(String trajetId) async {
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.reservations}/trajet/$trajetId/sieges-occupes',
      );

      if (response.data is! List) return [];
      return (response.data as List).map((e) => e.toString()).toList();
    } on DioException {
      return [];
    }
  }
}
