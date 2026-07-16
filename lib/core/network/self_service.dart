import 'package:dio/dio.dart';
import 'package:transia_mobile/core/constants/api_constants.dart';
import 'package:transia_mobile/core/network/api_client.dart';

class MeResponse {
  final String fullName;
  final String telephone;
  final String? email;
  final List<String> roles;

  MeResponse({
    required this.fullName,
    required this.telephone,
    this.email,
    required this.roles,
  });

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse(
      fullName: json['fullName']?.toString() ?? '',
      telephone: json['telephone']?.toString() ?? '',
      email: json['email']?.toString(),
      roles: json['roles'] is List
          ? (json['roles'] as List)
              .map((r) => r is Map ? (r['name']?.toString() ?? '') : r.toString())
              .toList()
          : [],
    );
  }
}

class MonProfilResponse {
  final String? photoProfil;
  final String? adresse;

  MonProfilResponse({this.photoProfil, this.adresse});

  factory MonProfilResponse.fromJson(Map<String, dynamic> json) {
    return MonProfilResponse(
      photoProfil: json['photoProfil']?.toString(),
      adresse: json['adresse']?.toString(),
    );
  }
}

/// Actions self-service sur son propre compte (informations, profil, mot de passe).
class SelfService {
  final ApiClient apiClient;

  SelfService({required this.apiClient});

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return 'Une erreur est survenue.';
  }

  Future<MeResponse> getMe() async {
    try {
      final response = await apiClient.dio.get(ApiConstants.me);
      return MeResponse.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> updateMe({
    required String fullName,
    required String telephone,
    String? email,
  }) async {
    try {
      await apiClient.dio.put(ApiConstants.me, data: {
        'fullName': fullName,
        'telephone': telephone,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      });
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<MonProfilResponse?> getMyProfil() async {
    try {
      final response = await apiClient.dio.get(ApiConstants.myProfil);
      return MonProfilResponse.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException {
      return null;
    }
  }

  /// [photoProfil] : null = ne pas modifier la photo existante (mise à jour partielle côté backend).
  Future<void> saveMyProfil({
    String? photoProfil,
    String? adresse,
    required bool existant,
  }) async {
    try {
      final data = <String, dynamic>{
        'adresse': adresse ?? '',
        if (photoProfil != null) 'photoProfil': photoProfil,
      };
      if (existant) {
        await apiClient.dio.put(ApiConstants.myProfil, data: data);
      } else {
        await apiClient.dio.post(ApiConstants.myProfil, data: data);
      }
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await apiClient.dio.put(ApiConstants.myPassword, data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }
}
