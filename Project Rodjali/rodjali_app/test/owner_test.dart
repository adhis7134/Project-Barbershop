import 'package:flutter_test/flutter_test.dart';

import 'package:rodjali_app/models/models.dart';

void main() {
  test('IncomeReport membaca total berupa string dari MySQL SUM()', () {
    final r = IncomeReport.fromJson({
      'from': '2026-10-01',
      'to': '2026-10-30',
      'total_income': 80000,
      'total_transactions': 2,
      'per_day': [
        {'date': '2026-10-30', 'transactions': 2, 'total': '80000'},
      ],
      'per_service': [
        {'service': 'Potong Rambut', 'transactions': '2', 'total': '70000'},
        {'service': 'Cukur Jenggot', 'transactions': 1, 'total': 10000.0},
      ],
    });
    expect(r.totalIncome, 80000);
    expect(r.perDay.single.total, 80000);
    expect(r.perDay.single.date, DateTime.utc(2026, 10, 30));
    expect(r.perService.first.transactions, 2);
    expect(r.perService.last.total, 10000);
  });

  test('laporan kosong tetap terbaca', () {
    final r = IncomeReport.fromJson({
      'total_income': 0,
      'total_transactions': 0,
      'per_day': [],
      'per_service': [],
    });
    expect(r.totalIncome, 0);
    expect(r.perDay, isEmpty);
  });

  test('AppUser.isPemilik', () {
    final u = AppUser.fromJson({'id': 1, 'name': 'P', 'email': 'p@x.test', 'phone': null, 'role': 'pemilik'});
    expect(u.isPemilik, true);
    expect(u.isPelanggan, false);
  });
}
