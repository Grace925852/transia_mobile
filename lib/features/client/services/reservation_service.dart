import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transia_mobile/core/constants/api_constants.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/client/models/reservation_model.dart';
import 'package:transia_mobile/features/client/models/reservation_request.dart';

class ReservationService {
  final ApiClient apiClient;

  ReservationService({required this.apiClient});

  final SecureStorageService _secureStorageService = SecureStorageService();

  Future<String> _buildUserScopedKey(String baseKey) async {
    final numericUserId = await _secureStorageService.getNumericUserId();
    final username = await _secureStorageService.getTelephone();

    if (numericUserId != null && numericUserId.trim().isNotEmpty) {
      return '${baseKey}_user_$numericUserId';
    }

    if (username != null && username.trim().isNotEmpty) {
      return '${baseKey}_username_${username.trim()}';
    }

    return '${baseKey}_anonymous';
  }

  Future<List<String>> getLocalCreatedReservationIds() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _buildUserScopedKey('local_created_reservation_ids');
    return prefs.getStringList(key) ?? [];
  }

  Future<void> saveLocalCreatedReservationId(String reservationId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _buildUserScopedKey('local_created_reservation_ids');
    final current = prefs.getStringList(key) ?? [];

    if (!current.contains(reservationId)) {
      current.add(reservationId);
      await prefs.setStringList(key, current);
    }
  }

  Future<void> clearCurrentUserLocalCreatedReservationIds() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _buildUserScopedKey('local_created_reservation_ids');
    await prefs.remove(key);
  }

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

      Map<String, dynamic> result;

      if (response.data is Map<String, dynamic>) {
        result = response.data as Map<String, dynamic>;
      } else {
        result = {'data': response.data};
      }

      final createdId = result['id']?.toString();
      if (createdId != null && createdId.isNotEmpty) {
        await saveLocalCreatedReservationId(createdId);
      }

      return result;
    } on DioException catch (e) {
      debugPrint('CREATE RESERVATION DIO STATUS = ${e.response?.statusCode}');
      debugPrint('CREATE RESERVATION DIO DATA = ${e.response?.data}');
      debugPrint('CREATE RESERVATION DIO MESSAGE = ${e.message}');

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

  Future<List<Map<String, dynamic>>> _getTrajetsRaw() async {
    final response = await apiClient.dio.get(ApiConstants.trajets);

    if (response.data is List) {
      return (response.data as List)
          .where((item) => item is Map)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    return [];
  }

  Future<List<ReservationModel>> getReservations() async {
    try {
      final reservationResponse = await apiClient.dio.get(
        ApiConstants.reservations,
      );

      final trajets = await _getTrajetsRaw();

      final Map<String, Map<String, dynamic>> trajetById = {
        for (final trajet in trajets) (trajet['id'] ?? '').toString(): trajet,
      };

      if (reservationResponse.data is List) {
        final list = reservationResponse.data as List;

        final parsed = list
            .where((item) => item is Map)
            .map((item) {
              final map = Map<String, dynamic>.from(item as Map);
              final trajetId = (map['trajetId'] ?? '').toString();
              final trajetData = trajetById[trajetId];

              final model = ReservationModel.fromJson(
                map,
                trajetData: trajetData,
              );

              debugPrint(
                'RESERVATION => id=${model.id}, userId=${model.userId}, client=${model.clientNom}, trajetId=${model.trajetId}, date=${model.dateDepart}, total=${model.montantTotal}, statut=${model.statut}',
              );

              return model;
            })
            .toList();

        parsed.sort((a, b) {
          final da = a.departureDateTime ?? DateTime(2100);
          final db = b.departureDateTime ?? DateTime(2100);
          return da.compareTo(db);
        });

        return parsed;
      }

      return [];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ??
            'Impossible de charger les réservations.',
      );
    } catch (e) {
      throw Exception('Erreur inconnue lors du chargement des réservations.');
    }
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  bool _containsNormalized(String base, String query) {
    if (query.isEmpty) return false;
    return _normalize(base).contains(_normalize(query));
  }

  Future<List<ReservationModel>> getMyReservations({
    required int userId,
    required String fullName,
    required String username,
  }) async {
    final reservations = await getReservations();
    final localCreatedIds = await getLocalCreatedReservationIds();

    final normalizedFullName = _normalize(fullName);
    final normalizedUsername = _normalize(username);

    final filtered = reservations.where((item) {
      final sameUserId = item.userId == userId;

      final sameNameExact =
          normalizedFullName.isNotEmpty &&
          _normalize(item.clientNom) == normalizedFullName;

      final sameNameContains =
          normalizedFullName.isNotEmpty &&
          _containsNormalized(item.clientNom, normalizedFullName);

      final sameUsernameExact =
          normalizedUsername.isNotEmpty &&
          _normalize(item.clientNom) == normalizedUsername;

      final sameUsernameContains =
          normalizedUsername.isNotEmpty &&
          _containsNormalized(item.clientNom, normalizedUsername);

      final locallyCreated = localCreatedIds.contains(item.id);

      return sameUserId ||
          sameNameExact ||
          sameNameContains ||
          sameUsernameExact ||
          sameUsernameContains ||
          locallyCreated;
    }).toList();

    debugPrint(
      'FILTERED RESERVATIONS => userId=$userId, fullName=$fullName, username=$username, localIds=${localCreatedIds.length}, count=${filtered.length}',
    );

    return filtered;
  }

  Future<List<ReservationModel>> getMyActiveReservations({
    required int userId,
    required String fullName,
    required String username,
  }) async {
    final all = await getMyReservations(
      userId: userId,
      fullName: fullName,
      username: username,
    );

    final active =
        all.where((item) => item.shouldShowInActiveReservations).toList();

    debugPrint('ACTIVE RESERVATIONS COUNT = ${active.length}');
    return active;
  }

  Future<List<ReservationModel>> getMyHistoryReservations({
    required int userId,
    required String fullName,
    required String username,
  }) async {
    final all = await getMyReservations(
      userId: userId,
      fullName: fullName,
      username: username,
    );

    final history = all.where((item) => item.shouldShowInHistory).toList();

    debugPrint('HISTORY RESERVATIONS COUNT = ${history.length}');
    return history;
  }
}