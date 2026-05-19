import 'package:shared_preferences/shared_preferences.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';

class PaymentStatusService {
  final SecureStorageService _secureStorageService = SecureStorageService();

  Future<String> _buildUserScopedKey(String baseKey) async {
    final numericUserId = await _secureStorageService.getNumericUserId();
    final username = await _secureStorageService.getUsername();

    if (numericUserId != null && numericUserId.trim().isNotEmpty) {
      return '${baseKey}_user_$numericUserId';
    }

    if (username != null && username.trim().isNotEmpty) {
      return '${baseKey}_username_${username.trim()}';
    }

    return '${baseKey}_anonymous';
  }

  Future<List<String>> getPaidReservationIds() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _buildUserScopedKey('paid_reservation_ids');
    return prefs.getStringList(key) ?? [];
  }

  Future<void> savePaidReservationId(String reservationId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _buildUserScopedKey('paid_reservation_ids');

    final ids = prefs.getStringList(key) ?? [];

    if (!ids.contains(reservationId)) {
      ids.add(reservationId);
      await prefs.setStringList(key, ids);
    }
  }

  Future<void> markReservationAsPaid(String reservationId) async {
    await savePaidReservationId(reservationId);
  }

  Future<bool> isReservationPaid(String reservationId) async {
    final ids = await getPaidReservationIds();
    return ids.contains(reservationId);
  }

  Future<void> removePaidReservationId(String reservationId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _buildUserScopedKey('paid_reservation_ids');

    final ids = prefs.getStringList(key) ?? [];
    ids.removeWhere((id) => id == reservationId);
    await prefs.setStringList(key, ids);
  }

  Future<void> clearCurrentUserPaidReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _buildUserScopedKey('paid_reservation_ids');
    await prefs.remove(key);
  }
}