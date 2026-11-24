import '../core/api_client.dart';
import '../core/format.dart';
import '../models/models.dart';

class CustomerRepository {
  CustomerRepository(this._api);

  final ApiClient _api;

  String _fmt(DateTime d) => '${ymd(d)} ${hhmm(d)}';

  Future<List<Service>> services() async {
    final r = await _api.get('/services');
    return (r['data'] as List).map((e) => Service.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Availability> availability(DateTime date) async {
    final r = await _api.get('/availability', query: {'date': ymd(date)});
    return Availability.fromJson(r);
  }

  Future<List<Booking>> myBookings() async {
    final r = await _api.get('/bookings');
    return (r['data'] as List).map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> book({required int serviceId, required DateTime startAt}) async {
    await _api.post('/bookings', body: {'service_id': serviceId, 'start_at': _fmt(startAt)});
  }

  Future<void> reschedule(int bookingId, DateTime startAt) async {
    await _api.put('/bookings/$bookingId', body: {'start_at': _fmt(startAt)});
  }

  Future<void> cancel(int bookingId) async {
    await _api.post('/bookings/$bookingId/cancel');
  }
}
