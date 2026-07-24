import 'package:transia_mobile/core/constants/api_constants.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/client/models/demande_collecte_model.dart';
import 'package:transia_mobile/features/livreur/models/livreur_colis_model.dart';

class LivreurService {
  final ApiClient apiClient;

  LivreurService({required this.apiClient});

  // Lecture seule : le rattachement d'un colis à une demande (statut COLLECTE) se fait
  // aujourd'hui côté agence, une fois le colis physiquement ramené et pesé par un agent.
  Future<List<DemandeCollecteModel>> getMesDemandesCollecte() async {
    final storage = SecureStorageService();
    final livreurId = await storage.getUserId() ?? '';
    if (livreurId.isEmpty) return [];

    final response = await apiClient.dio.get(
      '${ApiConstants.demandesCollecte}/livreur/$livreurId',
    );

    if (response.data is! List) return [];

    return (response.data as List)
        .whereType<Map<String, dynamic>>()
        .map(DemandeCollecteModel.fromJson)
        .toList();
  }

  Future<List<LivreurColisModel>> getMesLivraisons() async {
    final response = await apiClient.dio.get('${ApiConstants.colis}/mes-livraisons');

    if (response.data is! List) return [];

    return (response.data as List)
        .whereType<Map<String, dynamic>>()
        .map(LivreurColisModel.fromJson)
        .toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(a.dateCreation ?? '') ?? DateTime(1970);
        final db = DateTime.tryParse(b.dateCreation ?? '') ?? DateTime(1970);
        return db.compareTo(da);
      });
  }

  Future<LivreurColisModel> confirmerLivraison(String colisId) async {
    final response = await apiClient.dio.put(
      '${ApiConstants.colis}/$colisId/confirmer-livraison',
    );
    return LivreurColisModel.fromJson(response.data as Map<String, dynamic>);
  }
}
