import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:transia_mobile/core/constants/api_constants.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/auth/models/auth_response.dart';

class AuthService {
  final ApiClient apiClient;
  final SecureStorageService secureStorageService;

  AuthService({
    required this.apiClient,
    required this.secureStorageService,
  });

  String _extractReadableError(dynamic data) {
    if (data == null) {
      return '';
    }

    if (data is String) {
      return data.trim();
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      final possibleKeys = [
        'message',
        'detail',
        'details',
        'error_description',
        'error',
      ];

      for (final key in possibleKeys) {
        final value = map[key]?.toString().trim() ?? '';

        if (value.isNotEmpty &&
            value.toLowerCase() != 'bad request' &&
            value.toLowerCase() != 'unauthorized' &&
            value.toLowerCase() != 'forbidden') {
          return value;
        }
      }
    }

    return '';
  }

  String _normalizeLoginError(DioException error) {
    final statusCode = error.response?.statusCode;
    final serverMessage = _extractReadableError(
      error.response?.data,
    );

    if (kDebugMode) {
      debugPrint(
        'LOGIN ERROR => '
        'status=$statusCode, '
        'type=${error.type}, '
        'message=$serverMessage, '
        'url=${error.requestOptions.uri}',
      );
    }

    if (statusCode == 400) {
      if (serverMessage.isNotEmpty) {
        return serverMessage;
      }

      return 'Les informations de connexion sont invalides.';
    }

    if (statusCode == 401 || statusCode == 403) {
      if (serverMessage.isNotEmpty) {
        return serverMessage;
      }

      return 'Numéro de téléphone ou mot de passe incorrect.';
    }

    if (statusCode == 404) {
      return 'Le service de connexion est introuvable. Vérifiez l’adresse du serveur.';
    }

    if (statusCode == 409) {
      if (serverMessage.isNotEmpty) {
        return serverMessage;
      }

      return 'Ce compte ne peut pas être utilisé actuellement.';
    }

    if (statusCode != null && statusCode >= 500) {
      if (serverMessage.isNotEmpty) {
        return 'Erreur du serveur : $serverMessage';
      }

      return 'Le serveur aMessage rencontré une erreur interne ($statusCode).';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Le délai de connexion au serveur est dépassé.';

      case DioExceptionType.sendTimeout:
        return 'Le serveur met trop de temps à recevoir la demande.';

      case DioExceptionType.receiveTimeout:
        return 'Le serveur met trop de temps à répondre.';

      case DioExceptionType.connectionError:
        return 'Impossible de joindre le serveur. Vérifiez le réseau et l’adresse IP.';

      case DioExceptionType.badCertificate:
        return 'Le certificat du serveur n’est pas valide.';

      case DioExceptionType.cancel:
        return 'La connexion a été annulée.';

      case DioExceptionType.badResponse:
        if (serverMessage.isNotEmpty) {
          return serverMessage;
        }

        return 'Le serveur a retourné une réponse invalide.';

      case DioExceptionType.unknown:
        final technicalError =
            error.error?.toString().trim() ?? '';

        if (technicalError.isNotEmpty) {
          return 'Erreur réseau : $technicalError';
        }

        return 'Erreur de connexion au serveur.';
      case DioExceptionType.transformTimeout:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  String _normalizeRegisterError(DioException error) {
    final rawMessage = _extractReadableError(
      error.response?.data,
    );

    final normalizedMessage = rawMessage.toLowerCase();

    if (normalizedMessage.contains('already') ||
        normalizedMessage.contains('existe') ||
        normalizedMessage.contains('duplicate') ||
        normalizedMessage.contains('déjà utilisé') ||
        normalizedMessage.contains('deja utilise')) {
      return 'Ce numéro est déjà utilisé.';
    }

    if (rawMessage.isNotEmpty) {
      return rawMessage;
    }

    return "Erreur lors de l'inscription.";
  }

  Future<AuthResponse> login({
    required String telephone,
    required String password,
  }) async {
    final cleanTelephone = telephone.trim();

    if (cleanTelephone.isEmpty || password.isEmpty) {
      throw Exception(
        'Veuillez renseigner le numéro de téléphone et le mot de passe.',
      );
    }

    /*
     * Suppression de l’ancienne session avant la connexion.
     * Cela évite d’envoyer un token client pendant la
     * connexion chauffeur ou livreur.
     */
    await secureStorageService.clearSession();

    try {
      final response = await apiClient.dio.post(
        ApiConstants.login,
        data: {
          'telephone': cleanTelephone,
          'password': password,
        },
      );

      final responseData = response.data;

      if (responseData is! Map) {
        throw Exception(
          'La réponse de connexion du serveur est invalide.',
        );
      }

      final authResponse = AuthResponse.fromJson(
        Map<String, dynamic>.from(responseData),
      );

      if (authResponse.token.trim().isEmpty) {
        throw Exception(
          'Token introuvable dans la réponse du serveur.',
        );
      }

      if (authResponse.id.trim().isEmpty) {
        throw Exception(
          'Identifiant utilisateur introuvable dans la réponse du serveur.',
        );
      }

      if (authResponse.roles.isEmpty) {
        throw Exception(
          'Aucun rôle utilisateur n’a été retourné par le serveur.',
        );
      }

      await secureStorageService.saveToken(
        authResponse.token.trim(),
      );

      await secureStorageService.saveUserSession(
        userId: authResponse.id.trim(),
        fullName: authResponse.fullName.trim(),
        telephone: authResponse.telephone.trim(),
      );

      await secureStorageService.saveRoles(
        authResponse.roles,
      );

      if (kDebugMode) {
        debugPrint(
          'LOGIN SUCCESS => '
          'id=${authResponse.id}, '
          'telephone=${authResponse.telephone}, '
          'roles=${authResponse.roles}',
        );
      }

      return authResponse;
    } on DioException catch (error) {
      await secureStorageService.clearSession();

      throw Exception(
        _normalizeLoginError(error),
      );
    } catch (error) {
      await secureStorageService.clearSession();

      throw Exception(
        error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> register({
    required String fullName,
    required String telephone,
    required String password,
    String? email,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.register,
        data: {
          'nom': fullName.trim(),
          'telephone': telephone.trim(),
          if (email != null && email.trim().isNotEmpty)
            'email': email.trim(),
          'password': password,
        },
      );

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw Exception(
          "L'inscription n'a pas pu être validée.",
        );
      }
    } on DioException catch (error) {
      throw Exception(
        _normalizeRegisterError(error),
      );
    } catch (error) {
      throw Exception(
        error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> forgotPassword({
    required String telephone,
  }) async {
    try {
      await apiClient.dio.post(
        ApiConstants.forgotPassword,
        data: {
          'telephone': telephone.trim(),
        },
      );
    } on DioException catch (error) {
      final readableError = _extractReadableError(
        error.response?.data,
      );

      throw Exception(
        readableError.isNotEmpty
            ? readableError
            : 'Erreur lors de la demande de réinitialisation.',
      );
    } catch (error) {
      throw Exception(
        error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    await secureStorageService.clearSession();
  }
}
