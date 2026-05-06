import 'package:dio/dio.dart';
import 'package:transia_mobile/core/constants/api_constants.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/features/client/models/trajet_model.dart';

class TrajetService {
  final ApiClient apiClient;

  TrajetService({required this.apiClient});

  Future<List<TrajetModel>> getTrajets() async {
    try {
      final response = await apiClient.dio.get(ApiConstants.trajets);

      if (response.data is List) {
        return (response.data as List)
            .map((item) => TrajetModel.fromJson(item))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ?? 'Impossible de charger les trajets.',
      );
    } catch (e) {
      throw Exception('Erreur inconnue lors du chargement des trajets.');
    }
  }

  Future<List<TrajetModel>> rechercherTrajets({
    required String villeDepart,
    required String villeArrivee,
    required DateTime dateDepart,
  }) async {
    final trajets = await getTrajets();

    final dateRecherche =
        '${dateDepart.year.toString().padLeft(4, '0')}-'
        '${dateDepart.month.toString().padLeft(2, '0')}-'
        '${dateDepart.day.toString().padLeft(2, '0')}';

    return trajets.where((trajet) {
      final departOk = trajet.villeDepart.toLowerCase().trim() ==
          villeDepart.toLowerCase().trim();

      final arriveeOk = trajet.villeArrivee.toLowerCase().trim() ==
          villeArrivee.toLowerCase().trim();

      final dateOk = trajet.dateDepart == dateRecherche;

      final statutOk = trajet.statut.toUpperCase() == 'PROGRAMME';

      return departOk && arriveeOk && dateOk && statutOk;
    }).toList();
  }
}