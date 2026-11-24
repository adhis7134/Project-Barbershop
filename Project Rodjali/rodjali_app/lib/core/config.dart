/// Satu-satunya tempat alamat server. Ganti lewat --dart-define, tanpa mengubah kode:
///   Web (Chrome)          : (default) http://localhost:8000/api
///   HP asli + adb reverse : (default) http://localhost:8000/api
///   Emulator Android      : --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
///   HP asli lewat Wi-Fi   : --dart-define=API_BASE_URL=http://192.168.x.x:8000/api
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  /// Cermin aturan server (CANCEL_MIN_HOURS). Hanya untuk menyembunyikan tombol; server tetap yang memutuskan.
  static const int cancelMinHours = 2;

  /// Selang antar jam mulai yang ditawarkan saat booking.
  static const int slotStepMinutes = 30;
}
