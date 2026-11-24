import '../models/models.dart';

class SlotOption {
  const SlotOption(this.start, this.end, this.available);

  final DateTime start; // jam dinding WIB
  final DateTime end;
  final bool available;
}

DateTime _at(DateTime date, String hhmm) {
  final p = hhmm.split(':');
  return DateTime.utc(date.year, date.month, date.day, int.parse(p[0]), int.parse(p[1]));
}

/// Daftar jam mulai pada satu tanggal. Slot tidak tersedia jika bentrok dengan booking aktif
/// atau sudah lewat. [ignore] dipakai saat ganti jadwal agar booking sendiri tidak dianggap bentrok.
/// Semua DateTime adalah jam dinding WIB (UTC-flag), jadi aman dibandingkan satu sama lain.
List<SlotOption> buildSlots({
  required DateTime date,
  required String open,
  required String close,
  required int durationMinutes,
  required List<TakenSlot> taken,
  required DateTime now,
  int stepMinutes = 30,
  TakenSlot? ignore,
}) {
  final openAt = _at(date, open);
  final closeAt = _at(date, close);
  final duration = Duration(minutes: durationMinutes);
  final step = Duration(minutes: stepMinutes);
  final result = <SlotOption>[];

  for (var s = openAt; !s.add(duration).isAfter(closeAt); s = s.add(step)) {
    final e = s.add(duration);
    final clash = taken.any((t) {
      if (ignore != null && t.start == ignore.start && t.end == ignore.end) return false;
      return t.start.isBefore(e) && t.end.isAfter(s);
    });
    result.add(SlotOption(s, e, !clash && s.isAfter(now)));
  }
  return result;
}
