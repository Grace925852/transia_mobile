import 'package:transia_mobile/core/constants/api_constants.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/features/client/models/demande_collecte_model.dart';

class DemandeCollecteService {
  final ApiClient apiClient;

  DemandeCollecteService({required this.apiClient});

  Future<List<DemandeCollecteModel>> getMesDemandes() async {
    final response = await apiClient.dio.get('${ApiConstants.demandesCollecte}/mes-demandes');

    if (response.data is! List) return [];

    return (response.data as List)
        .whereType<Map<String, dynamic>>()
        .map(DemandeCollecteModel.fromJson)
        .toList();
  }

  Future<DemandeCollecteModel> creerDemande(DemandeCollecteRequest request) async {
    final response = await apiClient.dio.post(
      ApiConstants.demandesCollecte,
      data: request.toJson(),
    );
    return DemandeCollecteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DemandeCollecteModel> annulerDemande(String id) async {
    final response = await apiClient.dio.put('${ApiConstants.demandesCollecte}/$id/annuler');
    return DemandeCollecteModel.fromJson(response.data as Map<String, dynamic>);
  }
}
