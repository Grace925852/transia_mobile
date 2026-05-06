import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:transia_mobile/core/constants/api_constants.dart';
import 'package:transia_mobile/core/network/api_client.dart';

class UserService {
  final ApiClient apiClient;

  UserService({required this.apiClient});

  Future<int> resolveNumericUserId({
    required String username,
    required String fullName,
  }) async {
    try {
      debugPrint('USER RESOLVE => username=$username, fullName=$fullName');

      final response = await apiClient.dio.get(ApiConstants.users);

      debugPrint('GET USERS RESPONSE => ${response.data}');

      if (response.data is! List) {
        throw Exception('La réponse de /users n’est pas une liste.');
      }

      final users = response.data as List;

      for (final item in users) {
        if (item is! Map) continue;

        final map = Map<String, dynamic>.from(item as Map);

        final itemId = int.tryParse((map['id'] ?? '').toString());
        final itemUsername = (map['username'] ?? '').toString().trim();
        final itemFullName = (map['fullName'] ?? '').toString().trim();

        final usernameMatch =
            username.trim().isNotEmpty &&
            itemUsername.toLowerCase() == username.trim().toLowerCase();

        final fullNameMatch =
            fullName.trim().isNotEmpty &&
            itemFullName.toLowerCase() == fullName.trim().toLowerCase();

        if ((usernameMatch || fullNameMatch) && itemId != null) {
          debugPrint('NUMERIC USER ID FOUND => $itemId');
          return itemId;
        }
      }

      throw Exception(
        'Impossible de retrouver l’utilisateur numérique dans GET /api/v1/users.',
      );
    } on DioException catch (e) {
      debugPrint('GET USERS ERROR STATUS => ${e.response?.statusCode}');
      debugPrint('GET USERS ERROR DATA => ${e.response?.data}');
      throw Exception(
        e.response?.data?.toString() ??
            'Impossible de récupérer les utilisateurs.',
      );
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}