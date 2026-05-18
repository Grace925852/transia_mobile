import 'package:dio/dio.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';

class ChauffeurProblemService {
  final ApiClient apiClient;
  final SecureStorageService secureStorageService = SecureStorageService();

  ChauffeurProblemService({required this.apiClient});

  Future<String> _getChauffeurId() async {
    final id = await secureStorageService.getNumericUserId() ??
        await secureStorageService.getUserId() ??
        '';

    if (id.trim().isEmpty) {
      throw Exception('Identifiant chauffeur introuvable.');
    }

    return id.trim();
  }

  Future<void> submitProblem({
    required String trajetId,
    required String typeProbleme,
    required String description,
  }) async {
    try {
      final chauffeurId = await _getChauffeurId();

      await apiClient.dio.post(
        '/api/v1/chauffeur-problemes',
        data: {
          'trajetId': trajetId,
          'chauffeurId': chauffeurId,
          'typeProbleme': typeProbleme,
          'description': description,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ??
            'Impossible d’envoyer le signalement.',
      );
    } catch (_) {
      throw Exception('Impossible d’envoyer le signalement.');
    }
  }
}