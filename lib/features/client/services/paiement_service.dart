import 'package:dio/dio.dart';
import 'package:transia_mobile/core/constants/api_constants.dart';
import 'package:transia_mobile/core/network/api_client.dart';

class PaiementService {
  final ApiClient apiClient;

  PaiementService({required this.apiClient});

  /// Paiement effectué par le client depuis l'app (mobile money simulé, cf. POST /paiements/en-ligne
  /// côté backend). Aucune vraie intégration TMONEY/FLOOZ n'existe pour l'instant : le serveur
  /// enregistre et confirme le paiement immédiatement, comme le ferait un webhook de confirmation.
  Future<void> payerEnLigne({
    required String reservationId,
    required double montantVerse,
    required String modePaiement,
    String? reference,
  }) async {
    try {
      await apiClient.dio.post(
        '${ApiConstants.paiements}/en-ligne',
        data: {
          'reservationId': reservationId,
          'montantVerse': montantVerse,
          'modePaiement': modePaiement,
          if (reference != null && reference.isNotEmpty) 'reference': reference,
        },
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;

      if (responseData is Map<String, dynamic>) {
        final message = responseData['message']?.toString();
        if (message != null && message.isNotEmpty) {
          throw Exception(message);
        }
      }

      throw Exception(
        responseData?.toString() ?? 'Impossible d\'effectuer le paiement.',
      );
    } catch (_) {
      throw Exception('Erreur inconnue lors du paiement.');
    }
  }
}
