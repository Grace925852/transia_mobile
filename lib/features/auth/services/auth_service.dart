import 'package:dio/dio.dart';
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
    if (data == null) return '';

    if (data is String) return data;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final message = map['message']?.toString() ?? '';

      if (message.trim().isNotEmpty) {
        return message.trim();
      }

      return map.toString();
    }

    return data.toString();
  }

  String _normalizeLoginError(DioException e) {
    final rawMessage =
        _extractReadableError(e.response?.data).toLowerCase();

    if (e.response?.statusCode == 401 ||
        e.response?.statusCode == 403) {
      return 'Numéro de téléphone ou mot de passe incorrect.';
    }

    if (rawMessage.contains(
          'paramètres de connexion sont incorrectes',
        ) ||
        rawMessage.contains(
          'parametres de connexion sont incorrectes',
        ) ||
        rawMessage.contains(
          'connexion sont incorrectes',
        ) ||
        rawMessage.contains(
          'mot de passe incorrect',
        ) ||
        rawMessage.contains(
          'compte est bloqué',
        ) ||
        rawMessage.contains(
          'compte est inactif',
        ) ||
        rawMessage.contains(
          'bad credentials',
        ) ||
        rawMessage.contains(
          'login incorrect',
        )) {
      return rawMessage.contains('bloqué') ||
              rawMessage.contains('inactif')
          ? _extractReadableError(
              e.response?.data,
            )
          : 'Numéro de téléphone ou mot de passe incorrect.';
    }

    return 'Erreur de connexion au serveur.';
  }

  String _normalizeRegisterError(DioException e) {
    final rawMessage =
        _extractReadableError(e.response?.data).toLowerCase();

    if (rawMessage.contains('already') ||
        rawMessage.contains('existe') ||
        rawMessage.contains('duplicate') ||
        rawMessage.contains('déjà utilisé') ||
        rawMessage.contains('deja utilise')) {
      return 'Ce numéro est déjà utilisé.';
    }

    return "Erreur lors de l'inscription.";
  }

  Future<AuthResponse> login({
    required String telephone,
    required String password,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.login,
        data: {
          'username': telephone.trim(),
          'password': password,
        },
      );

      if (response.data is! Map) {
        throw Exception(
          'Réponse de connexion invalide.',
        );
      }

      final authResponse = AuthResponse.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );

      if (authResponse.token.isEmpty) {
        throw Exception(
          'Token introuvable dans la réponse du serveur.',
        );
      }

      if (authResponse.id.isEmpty) {
        throw Exception(
          'Identifiant public introuvable dans la réponse du serveur.',
        );
      }

      if (authResponse.numericId <= 0) {
        throw Exception(
          'Identifiant numérique introuvable dans la réponse du serveur.',
        );
      }

      await secureStorageService.clearSession();

      await secureStorageService.saveToken(
        authResponse.token,
      );

      await secureStorageService.saveUserSession(
        userId: authResponse.id,
        numericUserId: authResponse.numericId.toString(),
        fullName: authResponse.fullName,
        telephone: authResponse.telephone.isNotEmpty
            ? authResponse.telephone
            : telephone.trim(),
      );

      if (authResponse.roles.isNotEmpty) {
        await secureStorageService.saveRoles(
          authResponse.roles,
        );
      }

      return authResponse;
    } on DioException catch (e) {
      print(
        'LOGIN STATUS = ${e.response?.statusCode}',
      );
      print(
        'LOGIN DATA = ${e.response?.data}',
      );
      print(
        'LOGIN ERROR = ${e.message}',
      );

      throw Exception(
        _normalizeLoginError(e),
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceAll(
              'Exception: ',
              '',
            ),
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
      await apiClient.dio.post(
        ApiConstants.register,
        data: {
          'nom': fullName.trim(),
          'telephone': telephone.trim(),
          if (email != null &&
              email.trim().isNotEmpty)
            'email': email.trim(),
          'password': password,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        _normalizeRegisterError(e),
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceAll(
              'Exception: ',
              '',
            ),
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
    } on DioException catch (e) {
      final readableError =
          _extractReadableError(e.response?.data);

      throw Exception(
        readableError.isNotEmpty
            ? readableError
            : 'Erreur lors de la demande de réinitialisation.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceAll(
              'Exception: ',
              '',
            ),
      );
    }
  }

  Future<void> logout() async {
    await secureStorageService.clearSession();
  }
}
