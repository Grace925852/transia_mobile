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

  Future<String?> _findNumericUserIdByUsername(String username) async {
    try {
      final response = await apiClient.dio.get('/api/v1/users');

      if (response.data is! List) return null;

      for (final item in response.data as List) {
        if (item is! Map) continue;

        final userMap = Map<String, dynamic>.from(item as Map);
        final currentUsername = (userMap['username'] ?? '').toString().trim();

        if (currentUsername == username.trim()) {
          final numericId = userMap['id'];
          if (numericId != null) {
            return numericId.toString();
          }
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.login,
        data: {
          'username': username,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.token.isEmpty) {
        throw Exception('Token introuvable dans la réponse du serveur.');
      }

      await secureStorageService.saveToken(authResponse.token);

      String? numericUserId =
          await _findNumericUserIdByUsername(authResponse.username);

      numericUserId ??= _fallbackNumericUserId(
        username: authResponse.username,
        fullName: authResponse.fullName,
      );

      await secureStorageService.saveUserSession(
        userId: authResponse.id,
        numericUserId: numericUserId,
        fullName: authResponse.fullName,
        username: authResponse.username,
      );

      return authResponse;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Numéro ou mot de passe incorrect.');
      }

      throw Exception(
        e.response?.data?.toString() ?? 'Erreur de connexion au serveur.',
      );
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  String? _fallbackNumericUserId({
    required String username,
    required String fullName,
  }) {
    final u = username.trim().toLowerCase();
    final n = fullName.trim().toLowerCase();

    if (u == '90000000' || n == 'koffi akakpo') return '5';
    if (u == '91000000' || n == 'afi secretaire') return '3';
    if (u == '92000000' || n == 'kodjo chauffeur') return '4';
    if (u == 'atta' || n == 'atta esso-lotié') return '6';

    return null;
  }

  Future<void> register({
    required String fullName,
    required String username,
    required String password,
  }) async {
    try {
      await apiClient.dio.post(
        ApiConstants.register,
        data: {
          'fullName': fullName,
          'username': username,
          'password': password,
          'enable': true,
          'roles': {
            'id': 5,
          },
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception(
          "L'inscription client n'est pas autorisée. Vérifie si /api/v1/users est public ou s'il faut un token admin.",
        );
      }

      throw Exception(
        e.response?.data?.toString() ?? "Erreur lors de l'inscription.",
      );
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    await secureStorageService.deleteToken();
  }
}