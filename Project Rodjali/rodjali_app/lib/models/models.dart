import '../core/config.dart';
import '../core/format.dart';

class AppUser {
  AppUser({required this.id, required this.name, required this.email, this.phone, required this.role});

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role; // pelanggan | kasir | pemilik

  bool get isPelanggan => role == 'pelanggan';
  bool get isPemilik => role == 'pemilik';

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        name: j['name'] as String,
        email: j['email'] as String,
        phone: j['phone'] as String?,
        role: j['role'] as String,
      );
}

class Service {
  Service({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
    required this.isActive,
  });

  final int id;
  final String name;
  final int price;
  final int durationMinutes;
  final bool isActive;

  factory Service.fromJson(Map<String, dynamic> j) => Service(
        id: j['id'] as int,
        name: j['name'] as String,
        price: (j['price'] as num).toInt(),
        durationMinutes: (j['duration_minutes'] as num).toInt(),
        isActive: j['is_active'] == true || j['is_active'] == 1,
      );
}

class PaymentTransaction {
  PaymentTransaction({required this.id, required this.bookingId, required this.amount, required this.status});

  final int id;
  final int bookingId;
  final int amount;
  final String status; // belum_lunas | lunas

  bool get isPaid => status == 'lunas';

  factory PaymentTransaction.fromJson(Map<String, dynamic> j) => PaymentTransaction(
        id: j['id'] as int,
        bookingId: j['booking_id'] as int,
        amount: (j['amount'] as num).toInt(),
        status: j['status'] as String,
      );
}

class Booking {
  Booking({
    required this.id,
    required this.customerName,
    this.customerPhone,
    this.service,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.source,
    this.transaction,
  });

  final int id;
  final String customerName;
  final String? customerPhone;
  final Service? service;
  final DateTime startAt; // jam dinding WIB
  final DateTime endAt;
  final String status; // dipesan | dikerjakan | selesai | dibatalkan | tidak_datang
  final String source; // online | walk_in
  final PaymentTransaction? transaction;

  bool get isWalkIn => source == 'walk_in';

  /// Pelanggan masih boleh ganti jadwal/batal (cermin aturan server; server tetap menolak jika lewat batas).
  bool get canChange =>
      status == 'dipesan' && startAt.isAfter(wibNow().add(const Duration(hours: AppConfig.cancelMinHours)));

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'] as int,
        customerName: j['customer_name'] as String,
        customerPhone: j['customer_phone'] as String?,
        service: j['service'] == null ? null : Service.fromJson(j['service'] as Map<String, dynamic>),
        startAt: parseServerTime(j['start_at'] as String),
        endAt: parseServerTime(j['end_at'] as String),
        status: j['status'] as String,
        source: j['source'] as String,
        transaction: j['transaction'] == null
            ? null
            : PaymentTransaction.fromJson(j['transaction'] as Map<String, dynamic>),
      );
}

class QrisInfo {
  QrisInfo({
    required this.transactionId,
    required this.reference,
    required this.amount,
    required this.merchant,
    required this.imageUrl,
    required this.status,
  });

  final int transactionId;
  final String reference;
  final int amount;
  final String merchant;
  final String imageUrl; // bisa kosong jika QRIS_IMAGE_URL belum diisi
  final String status;

  bool get isPaid => status == 'lunas';

  factory QrisInfo.fromJson(Map<String, dynamic> j) => QrisInfo(
        transactionId: j['transaction_id'] as int,
        reference: j['reference'] as String,
        amount: (j['amount'] as num).toInt(),
        merchant: j['merchant'] as String,
        imageUrl: (j['qris_image_url'] as String?) ?? '',
        status: j['status'] as String,
      );
}

class TakenSlot {
  TakenSlot({required this.start, required this.end});

  final DateTime start; // jam dinding WIB
  final DateTime end;

  factory TakenSlot.fromJson(Map<String, dynamic> j) => TakenSlot(
        start: parseServerTime(j['start_at'] as String),
        end: parseServerTime(j['end_at'] as String),
      );
}

class Availability {
  Availability({required this.open, required this.close, required this.taken});

  final String open; // "10:00"
  final String close; // "21:00"
  final List<TakenSlot> taken;

  factory Availability.fromJson(Map<String, dynamic> j) => Availability(
        open: j['open'] as String,
        close: j['close'] as String,
        taken: (j['taken'] as List).map((e) => TakenSlot.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

// MySQL SUM() sering dikirim sebagai string ("35000"), jadi dibaca dengan aman.
int _asInt(dynamic v) => num.parse(v.toString()).toInt();

class DayIncome {
  DayIncome({required this.date, required this.transactions, required this.total});

  final DateTime date;
  final int transactions;
  final int total;

  factory DayIncome.fromJson(Map<String, dynamic> j) {
    final d = DateTime.parse(j['date'] as String);
    return DayIncome(
      date: DateTime.utc(d.year, d.month, d.day),
      transactions: _asInt(j['transactions']),
      total: _asInt(j['total']),
    );
  }
}

class ServiceIncome {
  ServiceIncome({required this.service, required this.transactions, required this.total});

  final String service;
  final int transactions;
  final int total;

  factory ServiceIncome.fromJson(Map<String, dynamic> j) => ServiceIncome(
        service: j['service'] as String,
        transactions: _asInt(j['transactions']),
        total: _asInt(j['total']),
      );
}

class IncomeReport {
  IncomeReport({
    required this.totalIncome,
    required this.totalTransactions,
    required this.perDay,
    required this.perService,
  });

  final int totalIncome;
  final int totalTransactions;
  final List<DayIncome> perDay;
  final List<ServiceIncome> perService;

  factory IncomeReport.fromJson(Map<String, dynamic> j) => IncomeReport(
        totalIncome: _asInt(j['total_income']),
        totalTransactions: _asInt(j['total_transactions']),
        perDay: (j['per_day'] as List).map((e) => DayIncome.fromJson(e as Map<String, dynamic>)).toList(),
        perService:
            (j['per_service'] as List).map((e) => ServiceIncome.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
