import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/features/client/models/client_trip_tracking_model.dart';

class ClientTripTrackingService {
  final ApiClient apiClient;

  ClientTripTrackingService({
    required this.apiClient,
  });

  Future<ClientTripTrackingModel?> getTrackingByTripId(
    String trajetId,
  ) async {
    try {
      final response = await apiClient.dio.get(
        '/api/v1/suivis/trajet/$trajetId',
      );

      if (response.statusCode == 204 ||
          response.data == null) {
        return null;
      }

      if (response.data is! Map) {
        throw Exception(
          'La réponse du suivi est invalide.',
        );
      }

      return ClientTripTrackingModel.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on DioException catch (error) {
      debugPrint(
        'CLIENT TRACKING STATUS = '
        '${error.response?.statusCode}',
      );

      debugPrint(
        'CLIENT TRACKING DATA = '
        '${error.response?.data}',
      );

      if (error.response?.statusCode == 404 ||
          error.response?.statusCode == 204) {
        return null;
      }

      final message = _extractMessage(
        error.response?.data,
      );

      final normalized = message.toLowerCase();

      if (normalized.contains('aucun suivi') ||
          normalized.contains(
            'suivi de trajet introuvable',
          )) {
        return null;
      }

      throw Exception(message);
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception(
        'Impossible de récupérer le suivi du trajet.',
      );
    }
  }

  String _extractMessage(dynamic data) {
    if (data is Map) {
      final message =
          data['message'] ??
          data['error'] ??
          data['details'] ??
          data['detail'];

      if (message != null &&
          message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    return 'Impossible de récupérer le suivi du trajet.';
  }
}