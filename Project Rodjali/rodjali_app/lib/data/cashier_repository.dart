import '../core/api_client.dart';
import '../core/format.dart';
import '../models/models.dart';

class CashierRepository {
  CashierRepository(this._api);

  final ApiClient _api;

  Future<List<Booking>> queue(DateTime date) async {
    final r = await _api.get('/cashier/queue', query: {'date': ymd(date)});
    return (r['data'] as List).map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Service>> services() async {
    final r = await _api.get('/services');
    return (r['data'] as List).map((e) => Service.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Availability> availability(DateTime date) async {
    final r = await _api.get('/availability', query: {'date': ymd(date)});
    return Availability.fromJson(r);
  }

  Future<void> walkIn({
    required String name,
    String? phone,
    required int serviceId,
    DateTime? startAt, // null = server tentukan otomatis (slot kosong pertama)
  }) async {
    await _api.post('/cashier/walk-in', body: {
      'customer_name': name,
      if (phone != null && phone.isNotEmpty) 'customer_phone': phone,
      'service_id': serviceId,
      if (startAt != null) 'start_at': '${ymd(startAt)} ${hhmm(startAt)}',
    });
  }

  Future<void> start(int bookingId) => _api.post('/cashier/bookings/$bookingId/start');

  Future<PaymentTransaction> complete(int bookingId) async {
    final r = await _api.post('/cashier/bookings/$bookingId/complete');
    return PaymentTransaction.fromJson(r['transaction'] as Map<String, dynamic>);
  }

  Future<void> noShow(int bookingId) => _api.post('/cashier/bookings/$bookingId/no-show');

  Future<QrisInfo> qris(int transactionId) async {
    final r = await _api.get('/cashier/transactions/$transactionId/qris');
    return QrisInfo.fromJson(r);
  }

  Future<void> confirmPaid(int transactionId) =>
      _api.post('/cashier/transactions/$transactionId/confirm-paid');
}
