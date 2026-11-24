/// Data profil barbershop untuk halaman "Info Barbershop".
/// Kolom yang dikosongkan ('') tidak ditampilkan.
class ShopInfo {
  const ShopInfo({
    this.name = 'Rodjali Barbershop',
    this.tagline = 'Potong rapi, tampil percaya diri.',
    this.openTime = '10:00', // samakan dengan SHOP_OPEN di .env backend
    this.closeTime = '21:00', // samakan dengan SHOP_CLOSE di .env backend
    this.lateToleranceMinutes = 15, // samakan dengan LATE_TOLERANCE_MINUTES di .env backend
    this.address = '', // contoh: 'Jl. Contoh No. 1, Cikarang'
    this.whatsapp = '', // contoh: '0812-3456-7890'
    this.instagram = '', // contoh: '@rodjali.barbershop'
  });

  final String name;
  final String tagline;
  final String openTime;
  final String closeTime;
  final int lateToleranceMinutes;
  final String address;
  final String whatsapp;
  final String instagram;

  bool get hasContact => address.isNotEmpty || whatsapp.isNotEmpty || instagram.isNotEmpty;

  static const current = ShopInfo();
}