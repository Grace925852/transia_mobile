import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/features/chauffeur/models/trip_tracking_model.dart';

class TripTrackingService {
  final ApiClient apiClient;

  TripTrackingService({
    required this.apiClient,
  });

  Future<TripTrackingModel?> getTrackingByTripId(
    String tripId,
  ) async {
    try {
      final response = await apiClient.dio.get(
        '/api/v1/suivis/trajet/$tripId',
      );

      if (response.data is Map) {
        return TripTrackingModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }

      return null;
    } on DioException catch (e) {
      debugPrint(
        'GET TRACKING STATUS = ${e.response?.statusCode}',
      );
      debugPrint(
        'GET TRACKING DATA = ${e.response?.data}',
      );

      if (e.response?.statusCode == 404 ||
          e.response?.statusCode == 204) {
        return null;
      }

      final message = _extractErrorMessage(
        e.response?.data,
        fallback:
            'Impossible de récupérer le suivi du trajet.',
      );

      if (message.toLowerCase().contains(
            'aucun suivi',
          ) ||
          message.toLowerCase().contains(
            'suivi de trajet introuvable',
          )) {
        return null;
      }

      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;

      throw Exception(
        'Impossible de récupérer le suivi du trajet.',
      );
    }
  }

  Future<TripTrackingModel> startTracking(
    String tripId,
  ) async {
    try {
      final response = await apiClient.dio.post(
        '/api/v1/suivis/demarrer/$tripId',
      );

      return _parseTrackingResponse(response.data);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(
          e.response?.data,
          fallback:
              'Impossible de démarrer le trajet.',
        ),
      );
    }
  }

  Future<TripTrackingModel> pauseTracking(
    int trackingId,
  ) async {
    try {
      final response = await apiClient.dio.patch(
        '/api/v1/suivis/$trackingId/pause',
      );

      return _parseTrackingResponse(response.data);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(
          e.response?.data,
          fallback:
              'Impossible de mettre le trajet en pause.',
        ),
      );
    }
  }

  Future<TripTrackingModel> resumeTracking(
    int trackingId,
  ) async {
    try {
      final response = await apiClient.dio.patch(
        '/api/v1/suivis/$trackingId/reprendre',
      );

      return _parseTrackingResponse(response.data);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(
          e.response?.data,
          fallback:
              'Impossible de reprendre le trajet.',
        ),
      );
    }
  }

  Future<TripTrackingModel> finishTracking(
    int trackingId,
  ) async {
    try {
      final response = await apiClient.dio.patch(
        '/api/v1/suivis/$trackingId/terminer',
      );

      return _parseTrackingResponse(response.data);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(
          e.response?.data,
          fallback:
              'Impossible de terminer le trajet.',
        ),
      );
    }
  }

  Future<TripTrackingModel> cancelTracking(
    int trackingId,
  ) async {
    try {
      final response = await apiClient.dio.patch(
        '/api/v1/suivis/$trackingId/annuler',
      );

      return _parseTrackingResponse(response.data);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(
          e.response?.data,
          fallback:
              'Impossible d’annuler le suivi du trajet.',
        ),
      );
    }
  }

  Future<TripTrackingModel> updateTrackingMessage({
    required int trackingId,
    required String status,
    required String message,
  }) async {
    try {
      final response = await apiClient.dio.patch(
        '/api/v1/suivis/$trackingId/statut',
        data: {
          'statut': status,
          'message': message,
        },
      );

      return _parseTrackingResponse(response.data);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(
          e.response?.data,
          fallback:
              'Impossible de mettre à jour le suivi.',
        ),
      );
    }
  }

  Future<TripGpsPositionModel> sendPosition({
    required int trackingId,
    required double latitude,
    required double longitude,
    required double vitesse,
    required double precisionGps,
    required double altitude,
  }) async {
    try {
      final payload = {
        'suiviTrajetId': trackingId,
        'latitude': latitude,
        'longitude': longitude,
        'vitesse': vitesse < 0 ? 0 : vitesse,
        'precisionGps':
            precisionGps < 0 ? 0 : precisionGps,
        'altitude': altitude,
      };

      debugPrint('SEND GPS PAYLOAD = $payload');

      final response = await apiClient.dio.post(
        '/api/v1/positions-gps/envoyer',
        data: payload,
      );

      if (response.data is! Map) {
        throw Exception(
          'Réponse GPS invalide reçue du serveur.',
        );
      }

      return TripGpsPositionModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      debugPrint(
        'SEND GPS STATUS = ${e.response?.statusCode}',
      );
      debugPrint(
        'SEND GPS DATA = ${e.response?.data}',
      );

      throw Exception(
        _extractErrorMessage(
          e.response?.data,
          fallback:
              'Impossible d’envoyer la position GPS.',
        ),
      );
    }
  }

  TripTrackingModel _parseTrackingResponse(
    dynamic data,
  ) {
    if (data is! Map) {
      throw Exception(
        'Réponse de suivi invalide reçue du serveur.',
      );
    }

    return TripTrackingModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  String _extractErrorMessage(
    dynamic data, {
    required String fallback,
  }) {
    if (data is Map) {
      final message =
          data['message'] ??
          data['error'] ??
          data['detail'];

      if (message != null &&
          message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    return fallback;
  }
}