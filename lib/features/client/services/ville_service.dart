import 'package:dio/dio.dart';
import 'package:transia_mobile/core/constants/api_constants.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/features/client/models/ville_model.dart';

class VilleService {
  final ApiClient apiClient;

  VilleService({required this.apiClient});

  Future<List<VilleModel>> getVilles() async {
    try {
      final response = await apiClient.dio.get(ApiConstants.villes);

      if (response.data is List) {
        return (response.data as List)
            .map((item) => VilleModel.fromJson(item))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ?? 'Impossible de charger les villes.',
      );
    } catch (e) {
      throw Exception('Erreur inconnue lors du chargement des villes.');
    }
  }
}