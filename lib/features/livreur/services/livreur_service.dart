import 'package:transia_mobile/core/constants/api_constants.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/features/livreur/models/livreur_colis_model.dart';

class LivreurService {
  final ApiClient apiClient;

  LivreurService({required this.apiClient});

  Future<List<LivreurColisModel>> getMesColis(String livreurId) async {
    final response = await apiClient.dio.get(
      ApiConstants.colis,
      queryParameters: livreurId.isNotEmpty ? {'livreurId': livreurId} : null,
    );

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

  Future<void> mettreAJourStatut(String colisId, StatutColis statut) async {
    await apiClient.dio.patch(
      '${ApiConstants.colis}/$colisId/statut',
      data: {'statut': statutColisToJson(statut)},
    );
  }

  Future<List<LivreurColisModel>> getColisALivrer(String livreurId) async {
    final all = await getMesColis(livreurId);
    return all.where((c) =>
        c.statut == StatutColis.prisEnCharge ||
        c.statut == StatutColis.collecteEffectuee ||
        c.statut == StatutColis.enCours).toList();
  }
}
