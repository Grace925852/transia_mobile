import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _numericUserIdKey = 'numeric_user_id';
  static const String _fullNameKey = 'full_name';
  static const String _telephoneKey = 'telephone';
  static const String _rolesKey = 'user_roles';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveUserSession({
    required String userId,
    String? numericUserId,
    required String fullName,
    required String telephone,
  }) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _fullNameKey, value: fullName);
    await _storage.write(key: _telephoneKey, value: telephone);

    if (numericUserId != null && numericUserId.trim().isNotEmpty) {
      await _storage.write(
        key: _numericUserIdKey,
        value: numericUserId.trim(),
      );
    } else {
      await _storage.delete(key: _numericUserIdKey);
    }
  }

  Future<void> saveNumericUserId(String numericUserId) async {
    final cleaned = numericUserId.trim();
    if (cleaned.isEmpty) {
      await _storage.delete(key: _numericUserIdKey);
      return;
    }

    await _storage.write(key: _numericUserIdKey, value: cleaned);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<String?> getNumericUserId() async {
    return await _storage.read(key: _numericUserIdKey);
  }

  Future<String?> getFullName() async {
    return await _storage.read(key: _fullNameKey);
  }

  Future<String?> getTelephone() async {
    return await _storage.read(key: _telephoneKey);
  }

  Future<void> updateProfileCache({String? fullName, String? telephone}) async {
    if (fullName != null) await _storage.write(key: _fullNameKey, value: fullName);
    if (telephone != null) await _storage.write(key: _telephoneKey, value: telephone);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _numericUserIdKey);
    await _storage.delete(key: _fullNameKey);
    await _storage.delete(key: _telephoneKey);
    await _storage.delete(key: _rolesKey);
  }

  Future<void> deleteToken() async {
    await clearSession();
  }

  Future<void> saveRoles(List<String> roles) async {
    await _storage.write(key: _rolesKey, value: roles.join(','));
  }

  Future<List<String>> getRoles() async {
    final value = await _storage.read(key: _rolesKey);
    if (value == null || value.isEmpty) return [];
    return value.split(',').map((r) => r.trim().toUpperCase()).toList();
  }

  Future<bool> hasRole(String role) async {
    final roles = await getRoles();
    final target = role.toUpperCase();
    return roles.any((r) => r == target || r == 'ROLE_$target');
  }
}
