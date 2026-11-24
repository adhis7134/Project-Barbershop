import 'package:excel/excel.dart' as xl;
import 'package:flutter_test/flutter_test.dart';

import 'package:rodjali_app/core/report_export.dart';
import 'package:rodjali_app/models/models.dart';

void main() {
  final report = IncomeReport(
    totalIncome: 80000,
    totalTransactions: 3,
    perDay: [
      DayIncome(date: DateTime.utc(2026, 10, 29), transactions: 1, total: 10000),
      DayIncome(date: DateTime.utc(2026, 10, 30), transactions: 2, total: 70000),
    ],
    perService: [
      ServiceIncome(service: 'Potong Rambut', transactions: 2, total: 70000),
      ServiceIncome(service: 'Cukur Jenggot', transactions: 1, total: 10000),
    ],
  );

  xl.Excel roundTrip() {
    final book = buildReportWorkbook(report, DateTime.utc(2026, 10, 1), DateTime.utc(2026, 10, 30));
    return xl.Excel.decodeBytes(book.save()!);
  }

  String text(xl.Excel b, String sheet, String cell) =>
      b[sheet].cell(xl.CellIndex.indexByString(cell)).value.toString();

  test('workbook punya tiga lembar yang diharapkan', () {
    final b = roundTrip();
    expect(b.tables.keys, containsAll(['Ringkasan', 'Per Layanan', 'Per Hari']));
  });

  test('lembar Ringkasan memuat rentang, total, dan jumlah transaksi', () {
    final b = roundTrip();
    expect(text(b, 'Ringkasan', 'B2'), '2026-10-01 s.d. 2026-10-30');
    expect(text(b, 'Ringkasan', 'B3'), '80000');
    expect(text(b, 'Ringkasan', 'B4'), '3');
  });

  test('lembar Per Layanan: judul, data, dan baris Total', () {
    final b = roundTrip();
    expect(text(b, 'Per Layanan', 'A1'), 'Layanan');
    expect(text(b, 'Per Layanan', 'A2'), 'Potong Rambut');
    expect(text(b, 'Per Layanan', 'C2'), '70000');
    expect(text(b, 'Per Layanan', 'A4'), 'Total');
    expect(text(b, 'Per Layanan', 'B4'), '3');
    expect(text(b, 'Per Layanan', 'C4'), '80000');
  });

  test('lembar Per Hari memakai tanggal yyyy-MM-dd', () {
    final b = roundTrip();
    expect(text(b, 'Per Hari', 'A2'), '2026-10-29');
    expect(text(b, 'Per Hari', 'A3'), '2026-10-30');
    expect(text(b, 'Per Hari', 'C4'), '80000');
  });

  test('laporan kosong tetap menghasilkan workbook valid', () {
    final empty = IncomeReport(totalIncome: 0, totalTransactions: 0, perDay: [], perService: []);
    final b = xl.Excel.decodeBytes(
      buildReportWorkbook(empty, DateTime.utc(2026, 10, 1), DateTime.utc(2026, 10, 30)).save()!,
    );
    expect(text(b, 'Per Hari', 'A2'), 'Total');
    expect(text(b, 'Per Hari', 'C2'), '0');
  });

  test('nama file memuat rentang tanggal', () {
    expect(reportFileName(DateTime.utc(2026, 10, 1), DateTime.utc(2026, 10, 30)),
        'laporan_rodjali_2026-10-01_2026-10-30.xlsx');
  });
}
