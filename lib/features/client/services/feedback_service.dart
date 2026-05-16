import 'package:dio/dio.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/features/client/models/feedback_request.dart';

class FeedbackService {
  final ApiClient apiClient;

  FeedbackService({required this.apiClient});

  Future<void> submitFeedback(FeedbackRequest request) async {
    try {
      await apiClient.dio.post(
        '/api/v1/feedback/submit',
        data: request.toJson(),
      );
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map<String, dynamic>) {
        final message = data['message']?.toString();
        if (message != null && message.trim().isNotEmpty) {
          throw Exception(message);
        }
      }

      throw Exception("Erreur lors de l'enregistrement de l'avis.");
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}