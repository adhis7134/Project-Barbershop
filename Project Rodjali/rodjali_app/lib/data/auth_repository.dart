import '../core/api_client.dart';
import '../models/models.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  /// Mengembalikan pengguna jika ada token tersimpan yang masih berlaku, selain itu null.
  Future<AppUser?> restore() async {
    await _api.loadToken();
    if (_api.token == null) return null;
    final r = await _api.get('/me');
    return AppUser.fromJson(r['user'] as Map<String, dynamic>);
  }

  Future<AppUser> login(String email, String password) async {
    final r = await _api.post('/login', body: {'email': email, 'password': password});
    await _api.saveToken(r['token'] as String);
    return AppUser.fromJson(r['user'] as Map<String, dynamic>);
  }

  Future<AppUser> register({
    required String name,
    required String email,
    String? phone,
    required String password,
  }) async {
    final r = await _api.post('/register', body: {
      'name': name,
      'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'password': password,
    });
    await _api.saveToken(r['token'] as String);
    return AppUser.fromJson(r['user'] as Map<String, dynamic>);
  }

  /// Minta kode reset ke email. Server menjawab sama baik email terdaftar maupun tidak.
  Future<String> forgotPassword(String email) async {
    final r = await _api.post('/forgot-password', body: {'email': email});
    return (r['message'] as String?) ?? 'Kode reset sudah dikirim.';
  }

  Future<String> resetPassword({required String email, required String code, required String password}) async {
    final r = await _api.post('/reset-password', body: {'email': email, 'code': code, 'password': password});
    return (r['message'] as String?) ?? 'Password berhasil diubah.';
  }

  Future<void> logout() async {
    try {
      await _api.post('/logout');
    } catch (_) {
      // Tetap keluar di sisi aplikasi walau server tidak terjangkau.
    }
    await _api.clearToken();
  }

  Future<void> forgetSession() => _api.clearToken();
}
