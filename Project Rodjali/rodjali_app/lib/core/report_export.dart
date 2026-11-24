import 'package:excel/excel.dart' as xl;

import '../models/models.dart';
import 'format.dart';

xl.CellValue _t(String s) => xl.TextCellValue(s);
xl.CellValue _n(int v) => xl.IntCellValue(v);

void _bold(xl.Sheet sheet, int row, int columns) {
  for (var c = 0; c < columns; c++) {
    sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row)).cellStyle = xl.CellStyle(bold: true);
  }
}

/// Satu lembar tabel: judul kolom (tebal), baris data, lalu baris Total (tebal).
void _tableSheet(
  xl.Excel book,
  String name,
  List<String> headers,
  List<List<xl.CellValue>> rows, {
  required int totalTransactions,
  required int totalAmount,
}) {
  final sheet = book[name];
  sheet.appendRow(headers.map(_t).toList());
  _bold(sheet, 0, headers.length);
  for (final row in rows) {
    sheet.appendRow(row);
  }
  sheet.appendRow([_t('Total'), _n(totalTransactions), _n(totalAmount)]);
  _bold(sheet, rows.length + 1, headers.length);
  sheet.setColumnWidth(0, 28);
  sheet.setColumnWidth(1, 20);
  sheet.setColumnWidth(2, 20);
}

/// Membuat workbook Excel dari laporan: lembar Ringkasan, Per Layanan, dan Per Hari.
xl.Excel buildReportWorkbook(IncomeReport r, DateTime from, DateTime to) {
  final book = xl.Excel.createExcel();
  book.rename('Sheet1', 'Ringkasan');

  final summary = book['Ringkasan'];
  summary.appendRow([_t('Laporan Pendapatan - Rodjali Barbershop')]);
  _bold(summary, 0, 1);
  summary.appendRow([_t('Rentang tanggal'), _t('${ymd(from)} s.d. ${ymd(to)}')]);
  summary.appendRow([_t('Total pendapatan (Rp)'), _n(r.totalIncome)]);
  summary.appendRow([_t('Jumlah transaksi'), _n(r.totalTransactions)]);
  summary.appendRow([_t('Catatan'), _t('Hanya transaksi yang sudah dikonfirmasi lunas.')]);
  summary.setColumnWidth(0, 28);
  summary.setColumnWidth(1, 44);

  _tableSheet(
    book,
    'Per Layanan',
    ['Layanan', 'Jumlah Transaksi', 'Pendapatan (Rp)'],
    [for (final s in r.perService) [_t(s.service), _n(s.transactions), _n(s.total)]],
    totalTransactions: r.perService.fold(0, (a, s) => a + s.transactions),
    totalAmount: r.perService.fold(0, (a, s) => a + s.total),
  );

  _tableSheet(
    book,
    'Per Hari',
    ['Tanggal', 'Jumlah Transaksi', 'Pendapatan (Rp)'],
    [for (final d in r.perDay) [_t(ymd(d.date)), _n(d.transactions), _n(d.total)]],
    totalTransactions: r.perDay.fold(0, (a, d) => a + d.transactions),
    totalAmount: r.perDay.fold(0, (a, d) => a + d.total),
  );

  return book;
}

String reportFileName(DateTime from, DateTime to) => 'laporan_rodjali_${ymd(from)}_${ymd(to)}.xlsx';
