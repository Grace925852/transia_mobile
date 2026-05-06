import 'package:shared_preferences/shared_preferences.dart';

class PaymentStatusService {
  static const String _paidReservationsKey = 'paid_reservations_ids';

  Future<List<String>> getPaidReservationIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_paidReservationsKey) ?? [];
  }

  Future<bool> isReservationPaid(String reservationId) async {
    final paidIds = await getPaidReservationIds();
    return paidIds.contains(reservationId);
  }

  Future<void> markReservationAsPaid(String reservationId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_paidReservationsKey) ?? [];

    if (!current.contains(reservationId)) {
      current.add(reservationId);
      await prefs.setStringList(_paidReservationsKey, current);
    }
  }

  Future<void> unmarkReservationAsPaid(String reservationId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_paidReservationsKey) ?? [];
    current.remove(reservationId);
    await prefs.setStringList(_paidReservationsKey, current);
  }
}