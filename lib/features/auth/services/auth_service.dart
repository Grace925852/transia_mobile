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

  Future<String?> _findNumericUserId({
    required String username,
    required String fullName,
    String? authId,
  }) async {
    try {
      final response = await apiClient.dio.get('/api/v1/users');

      if (response.data is! List) {
        return _fallbackNumericUserId(
          username: username,
          fullName: fullName,
          authId: authId,
        );
      }

      final wantedUsername = username.trim().toLowerCase();
      final wantedName = fullName.trim().toLowerCase();
      final wantedAuthId = (authId ?? '').trim();

      for (final item in response.data as List) {
        if (item is! Map) continue;

        final userMap = Map<String, dynamic>.from(item as Map);

        final currentUsername =
            (userMap['username'] ?? '').toString().trim().toLowerCase();
        final currentFullName =
            (userMap['fullName'] ?? '').toString().trim().toLowerCase();
        final currentId = userMap['id']?.toString().trim() ?? '';

        final usernameMatch =
            wantedUsername.isNotEmpty && currentUsername == wantedUsername;
        final fullNameMatch =
            wantedName.isNotEmpty && currentFullName == wantedName;
        final authIdMatch =
            wantedAuthId.isNotEmpty && currentId == wantedAuthId;

        if (usernameMatch || fullNameMatch || authIdMatch) {
          if (currentId.isNotEmpty) {
            return currentId;
          }
        }
      }

      return _fallbackNumericUserId(
        username: username,
        fullName: fullName,
        authId: authId,
      );
    } catch (_) {
      return _fallbackNumericUserId(
        username: username,
        fullName: fullName,
        authId: authId,
      );
    }
  }

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
    final rawMessage = _extractReadableError(e.response?.data).toLowerCase();

    if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
      return 'Numéro de téléphone ou mot de passe incorrect.';
    }

    if (rawMessage.contains('paramètres de connexion sont incorrectes') ||
        rawMessage.contains('parametres de connexion sont incorrectes') ||
        rawMessage.contains('connexion sont incorrectes') ||
        rawMessage.contains('mot de passe incorrect') ||
        rawMessage.contains('username or password') ||
        rawMessage.contains('bad credentials') ||
        rawMessage.contains('login incorrect')) {
      return 'Numéro de téléphone ou mot de passe incorrect.';
    }

    return 'Erreur de connexion au serveur.';
  }

  String _normalizeRegisterError(DioException e) {
    final rawMessage = _extractReadableError(e.response?.data).toLowerCase();

    if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
      return "L'inscription client n'est pas autorisée pour le moment.";
    }

    if (rawMessage.contains('already') ||
        rawMessage.contains('existe') ||
        rawMessage.contains('duplicate') ||
        rawMessage.contains('déjà utilisé') ||
        rawMessage.contains('deja utilise')) {
      return 'Ce numéro est déjà utilisé.';
    }

    if (rawMessage.contains('role_id') ||
        rawMessage.contains('null viole la contrainte') ||
        rawMessage.contains('viole la contrainte not null')) {
      return "Erreur de création du compte client.";
    }

    return "Erreur lors de l'inscription.";
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

      final numericUserId = await _findNumericUserId(
        username: authResponse.username,
        fullName: authResponse.fullName,
        authId: authResponse.id,
      );

      await secureStorageService.clearSession();
      await secureStorageService.saveToken(authResponse.token);

      await secureStorageService.saveUserSession(
        userId: authResponse.id,
        numericUserId: numericUserId,
        fullName: authResponse.fullName,
        username: authResponse.username,
      );

      return authResponse;
    } on DioException catch (e) {
      throw Exception(_normalizeLoginError(e));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  String? _fallbackNumericUserId({
    required String username,
    required String fullName,
    String? authId,
  }) {
    final u = username.trim().toLowerCase();
    final n = fullName.trim().toLowerCase();
    final a = (authId ?? '').trim();

    if (RegExp(r'^\d+$').hasMatch(a)) {
      return a;
    }

    if (u == '90000000' || n == 'koffi akakpo') return '5';
    if (u == '91000000' || n == 'afi secretaire') return '3';
    if (u == '92000000' || n == 'kodjo chauffeur') return '4';
    if (u == 'atta' || n == 'atta esso-lotié' || n == 'atta essolotie') {
      return '6';
    }

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
            'fullName': fullName.trim(),
            'username': username.trim(),
            'password': password,
            'roles': {
              'id': 5,
              'name': 'CLIENT',
            },
            'enable': true,
            'publicId': null,
          },
        );
      } on DioException catch (e) {
        final rawMessage = _extractReadableError(e.response?.data).toLowerCase();

        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          throw Exception("L'inscription client n'est pas autorisée pour le moment.");
        }

        if (rawMessage.contains('already') ||
            rawMessage.contains('existe') ||
            rawMessage.contains('duplicate') ||
            rawMessage.contains('déjà utilisé') ||
            rawMessage.contains('deja utilise')) {
          throw Exception('Ce numéro est déjà utilisé.');
        }

        throw Exception("Erreur lors de l'inscription.");
      } catch (e) {
        throw Exception(e.toString().replaceAll('Exception: ', ''));
      }
    }

  Future<void> logout() async {
    await secureStorageService.deleteToken();
  }
}