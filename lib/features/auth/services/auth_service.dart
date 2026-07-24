import 'package:dio/dio.dart';
import 'package:transia_mobile/core/constants/api_constants.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/auth/models/auth_response.dart';

class AuthService {
  final ApiClient apiClient;
  final SecureStorageService secureStorageService;

  AuthService({required this.apiClient, required this.secureStorageService});

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
    // 400 = message métier déjà rédigé côté backend (identifiants incorrects,
    // tentatives restantes, verrouillage temporaire...) : on l'affiche tel quel.
    if (e.response?.statusCode == 400) {
      final message = _extractReadableError(e.response?.data);
      if (message.trim().isNotEmpty) return message;
    }

    if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
      return 'Numéro de téléphone ou mot de passe incorrect.';
    }

    return 'Erreur de connexion au serveur.';
  }

  String _normalizeRegisterError(DioException e) {
    final rawMessage = _extractReadableError(e.response?.data).toLowerCase();

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
        data: {'telephone': telephone, 'password': password},
      );

      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.token.isEmpty) {
        throw Exception('Token introuvable dans la réponse du serveur.');
      }

      await secureStorageService.clearSession();
      await secureStorageService.saveToken(authResponse.token);

      await secureStorageService.saveUserSession(
        userId: authResponse.id,
        fullName: authResponse.fullName,
        telephone: authResponse.telephone,
      );

      if (authResponse.roles.isNotEmpty) {
        await secureStorageService.saveRoles(authResponse.roles);
      }

      return authResponse;
    } on DioException catch (e) {
      throw Exception(_normalizeLoginError(e));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
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
          if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
          'password': password,
        },
      );
    } on DioException catch (e) {
      throw Exception(_normalizeRegisterError(e));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> forgotPassword({required String telephone}) async {
    try {
      await apiClient.dio.post(
        ApiConstants.forgotPassword,
        data: {'telephone': telephone.trim()},
      );
    } on DioException catch (e) {
      throw Exception(
        _extractReadableError(e.response?.data).isNotEmpty
            ? _extractReadableError(e.response?.data)
            : 'Erreur lors de la demande de réinitialisation.',
      );
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    await secureStorageService.clearSession();
  }
}
