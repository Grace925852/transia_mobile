import 'package:dio/dio.dart';
import 'package:transia_mobile/core/constants/api_constants.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/features/client/models/agence_model.dart';

class AgenceService {
  final ApiClient apiClient;

  AgenceService({required this.apiClient});

  // Le client ne doit voir que les agences actives : le backend ne filtre pas
  // (l'admin a besoin de voir aussi les agences désactivées), donc filtrage ici.
  Future<List<AgenceModel>> getAgencesActives() async {
    try {
      final response = await apiClient.dio.get(ApiConstants.agences);

      if (response.data is! List) return [];

      return (response.data as List)
          .where((e) => e is Map)
          .map((e) => AgenceModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((a) => a.statut)
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ?? 'Impossible de charger les agences.',
      );
    } catch (e) {
      throw Exception('Erreur inconnue lors du chargement des agences.');
    }
  }
}
