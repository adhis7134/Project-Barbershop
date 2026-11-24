// Server menyimpan jam dalam WIB (APP_TIMEZONE=Asia/Jakarta) tetapi Laravel mengirim
// datetime sebagai ISO-8601 UTC ("...Z"). Semua DateTime di aplikasi adalah "jam dinding WIB":
// hanya field year/month/day/hour/minute yang dipakai, jangan dibandingkan dengan DateTime.now().

const _hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

DateTime parseServerTime(String raw) {
  final d = DateTime.parse(raw);
  return d.isUtc ? d.add(const Duration(hours: 7)) : d;
}

DateTime wibNow() => DateTime.now().toUtc().add(const Duration(hours: 7));

DateTime wibToday() {
  final n = wibNow();
  return DateTime.utc(n.year, n.month, n.day);
}

String _p2(int v) => v.toString().padLeft(2, '0');

String ymd(DateTime d) => '${d.year}-${_p2(d.month)}-${_p2(d.day)}';

String hhmm(DateTime d) => '${_p2(d.hour)}:${_p2(d.minute)}';

String tanggalIndo(DateTime d) => '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}';

String rupiah(int v) {
  final s = v.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${v < 0 ? '-' : ''}Rp $buf';
}

String tanggalPendek(DateTime d) => '${_hari[d.weekday - 1]} ${d.day} ${_bulan[d.month - 1]}';

String statusLabel(String s) => switch (s) {
      'dipesan' => 'Dipesan',
      'dikerjakan' => 'Sedang dikerjakan',
      'selesai' => 'Selesai',
      'dibatalkan' => 'Dibatalkan',
      'tidak_datang' => 'Tidak datang',
      _ => s,
    };
