import 'package:transia_mobile/core/constants/api_constants.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/features/client/models/colis_model.dart';

class ColisService {
  final ApiClient apiClient;

  ColisService({required this.apiClient});

  Future<List<ColisModel>> getMesColis(String expediteurId) async {
    final response = await apiClient.dio.get(
      ApiConstants.colis,
      queryParameters: expediteurId.isNotEmpty ? {'expediteurId': expediteurId} : null,
    );

    if (response.data is! List) return [];

    return (response.data as List)
        .whereType<Map<String, dynamic>>()
        .map(ColisModel.fromJson)
        .toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(a.dateCreation ?? '') ?? DateTime(1970);
        final db = DateTime.tryParse(b.dateCreation ?? '') ?? DateTime(1970);
        return db.compareTo(da);
      });
  }

  Future<ColisModel> creerColis(ColisRequest request) async {
    final response = await apiClient.dio.post(
      ApiConstants.colis,
      data: request.toJson(),
    );
    return ColisModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> annulerColis(String colisId) async {
    await apiClient.dio.patch(
      '${ApiConstants.colis}/$colisId/statut',
      data: {'statut': 'ANNULE'},
    );
  }
}
