import 'package:transia_mobile/core/constants/api_constants.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/features/client/models/colis_model.dart';

class ColisService {
  final ApiClient apiClient;

  ColisService({required this.apiClient});

  Future<List<ColisModel>> getMesColis() async {
    final response = await apiClient.dio.get('${ApiConstants.colis}/mes-colis');

    if (response.data is! List) return [];

    return (response.data as List)
        .whereType<Map<String, dynamic>>()
        .map(ColisModel.fromJson)
        .toList();
  }

  Future<ColisModel> getByNumeroSuivi(String numeroSuivi) async {
    final response = await apiClient.dio.get('${ApiConstants.colis}/suivi/$numeroSuivi');
    return ColisModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ColisModel> enregistrerColis(ColisRequest request) async {
    final response = await apiClient.dio.post(
      ApiConstants.colis,
      data: request.toJson(),
    );
    return ColisModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EstimationPrixModel> estimerPrix({
    required String villeDepartId,
    required String villeArriveeId,
    required TranchePoids tranche,
    required ModeRemise modeRemise,
    bool collecteDomicile = false,
  }) async {
    final response = await apiClient.dio.get(
      '${ApiConstants.tarifsColis}/estimer',
      queryParameters: {
        'departId': villeDepartId,
        'arriveeId': villeArriveeId,
        'tranche': trancheToJson(tranche),
        'modeRemise': modeRemiseToJson(modeRemise),
        'collecteDomicile': collecteDomicile,
      },
    );
    return EstimationPrixModel.fromJson(response.data as Map<String, dynamic>);
  }
}
