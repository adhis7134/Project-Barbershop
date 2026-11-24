import '../core/api_client.dart';
import '../core/format.dart';
import '../models/models.dart';

class OwnerRepository {
  OwnerRepository(this._api);

  final ApiClient _api;

  Future<IncomeReport> income(DateTime from, DateTime to) async {
    final r = await _api.get('/reports/income', query: {'from': ymd(from), 'to': ymd(to)});
    return IncomeReport.fromJson(r);
  }

  /// Untuk pemilik, server mengirim semua layanan (aktif maupun nonaktif).
  Future<List<Service>> services() async {
    final r = await _api.get('/services');
    return (r['data'] as List).map((e) => Service.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create({required String name, required int price, required int duration}) async {
    await _api.post('/services', body: {'name': name, 'price': price, 'duration_minutes': duration});
  }

  Future<void> update(int id, {String? name, int? price, int? duration, bool? isActive}) async {
    await _api.put('/services/$id', body: {
            'name': ?name,
      'price': ?price,
      'duration_minutes': ?duration,
      'is_active': ?isActive,
    });
  }

  /// Server menghapus, atau menonaktifkan jika layanan sudah punya riwayat. Mengembalikan pesannya.
  Future<String> remove(int id) async {
    final r = await _api.delete('/services/$id');
    return (r['message'] as String?) ?? 'Layanan dihapus.';
  }
}
