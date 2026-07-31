import 'package:dio/dio.dart';
import 'package:transia_mobile/core/constants/api_constants.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/features/assistant/models/assistant_message.dart';

class AssistantService {
  final ApiClient apiClient;

  final Map<String, dynamic> _conversationContext = {};

  AssistantService({
    required this.apiClient,
  });

  Future<AssistantMessage> getResponse(
    String question,
  ) async {
    final message = question.trim();

    if (message.isEmpty) {
      return AssistantMessage.assistant(
        content: 'Écrivez une question pour commencer.',
        suggestions: const [
          'Quel est mon prochain trajet ?',
          'Voir mes réservations',
        ],
      );
    }

    try {
      final response = await apiClient.dio.post(
        ApiConstants.assistantChat,
        data: {
          'message': message,
          'context': _conversationContext,
        },
      );

      if (response.data is! Map) {
        throw Exception(
          'Réponse invalide du service TransIA.',
        );
      }

      final data = Map<String, dynamic>.from(
        response.data as Map,
      );

      final content =
          data['message']?.toString().trim() ?? '';

      if (content.isEmpty) {
        throw Exception(
          'Le service TransIA n’a retourné aucun message.',
        );
      }

      final suggestions = _parseSuggestions(
        data['suggestions'],
      );

      final intent =
          data['intent']?.toString().trim() ?? '';

      final actionId =
          data['actionId']?.toString().trim() ?? '';

      final responseData = data['data'];

      if (responseData is Map) {
        _conversationContext.addAll(
          Map<String, dynamic>.from(responseData),
        );
      }

      if (intent.isNotEmpty) {
        _conversationContext['lastIntent'] = intent;
      }

      if (actionId.isNotEmpty) {
        _conversationContext['lastActionId'] = actionId;
      }

      return AssistantMessage.assistant(
        content: content,
        suggestions: suggestions,
      );
    } on DioException catch (error) {
      throw Exception(
        _dioErrorMessage(error),
      );
    } catch (error) {
      throw Exception(
        error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  List<String> _parseSuggestions(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _dioErrorMessage(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map) {
      final map = Map<String, dynamic>.from(
        responseData,
      );

      final message =
          map['message']?.toString().trim() ?? '';

      if (message.isNotEmpty) {
        return message;
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Le service TransIA met trop de temps à répondre.';

      case DioExceptionType.connectionError:
        return 'Impossible de joindre le service TransIA.';

      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;

        if (status == 401 || status == 403) {
          return 'Votre session a expiré. Reconnectez-vous.';
        }

        return 'Le serveur TransIA a retourné une erreur${status == null ? '' : ' ($status)'}.';

      case DioExceptionType.badCertificate:
        return 'Le certificat du serveur TransIA est invalide.';

      case DioExceptionType.cancel:
        return 'La demande a été annulée.';

      case DioExceptionType.unknown:
        return 'Une erreur inattendue est survenue avec TransIA.';
      case DioExceptionType.transformTimeout:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}
