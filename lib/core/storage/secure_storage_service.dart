import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _numericUserIdKey = 'numeric_user_id';
  static const String _fullNameKey = 'full_name';
  static const String _usernameKey = 'username';

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
    required String username,
  }) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _fullNameKey, value: fullName);
    await _storage.write(key: _usernameKey, value: username);

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

  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _numericUserIdKey);
    await _storage.delete(key: _fullNameKey);
    await _storage.delete(key: _usernameKey);
  }

  Future<void> deleteToken() async {
    await clearSession();
  }
}