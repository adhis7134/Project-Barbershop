# Backend API Rodjali Barbershop (Laravel + MySQL)

File di folder ini adalah bagian khusus proyek. Taruh di atas instalasi Laravel yang baru.

## Pasang
1. Buat proyek baru (butuh PHP 8.2+, Composer, MySQL/XAMPP):
   `composer create-project laravel/laravel rodjali_api`
2. Pasang Sanctum untuk token API:
   `php artisan install:api`
3. Salin isi folder ini ke dalam `rodjali_api`, timpa file yang sama
   (`app/Models/User.php` akan menggantikan bawaan Laravel).
4. Daftarkan alias middleware di `bootstrap/app.php`:

   ```php
   ->withMiddleware(function (Middleware $middleware) {
       $middleware->alias([
           'role' => \App\Http\Middleware\RoleMiddleware::class,
       ]);
   })
   ```
5. Atur `.env`:
   ```
   APP_TIMEZONE=Asia/Jakarta
   DB_CONNECTION=mysql
   DB_DATABASE=rodjali
   DB_USERNAME=root
   DB_PASSWORD=
   # opsional, bisa diubah setelah pemilik menjawab
   SHOP_OPEN=10:00
   SHOP_CLOSE=21:00
   LATE_TOLERANCE_MINUTES=15
   CANCEL_MIN_HOURS=2
   QRIS_IMAGE_URL=
   ```
6. Buat database `rodjali`, lalu: `php artisan migrate --seed`
7. Jalankan: `php artisan serve --host=0.0.0.0` (agar HP Android di jaringan yang sama bisa mengakses)
8. Tes: `php artisan test --filter=BookingConflictTest`

Semua request wajib memakai header `Accept: application/json`; endpoint terlindungi memakai
`Authorization: Bearer <token>`.

## Akun demo (password: `password`)
pemilik@rodjali.test, kasir@rodjali.test, pelanggan@rodjali.test

## Endpoint
| Peran | Method & path | Fungsi |
|---|---|---|
| Publik | POST /api/register, /api/login | Daftar pelanggan, masuk |
| Semua | GET /api/me, POST /api/logout, GET /api/services, GET /api/availability?date= | Profil, layanan aktif, slot terisi |
| Kasir/Pemilik | GET /api/cashier/queue?date= | Antrean harian |
| Kasir/Pemilik | POST /api/cashier/walk-in | Input pelanggan tanpa booking |
| Kasir/Pemilik | POST /api/cashier/bookings/{id}/start, /complete, /no-show | Mulai, selesai (buat tagihan), tidak datang |
| Kasir/Pemilik | GET /api/cashier/transactions/{id}/qris | Data layar QRIS |
| Kasir/Pemilik | POST /api/cashier/transactions/{id}/confirm-paid | Konfirmasi lunas |
| Pelanggan | GET/POST /api/bookings, PUT /api/bookings/{id}, POST /api/bookings/{id}/cancel | Booking, ganti jadwal, batal |
| Pemilik | POST/PUT/DELETE /api/services, GET /api/reports/income?from=&to= | Kelola layanan, laporan |

## Status booking
dipesan → dikerjakan → selesai (tagihan dibuat otomatis) → lunas setelah kasir konfirmasi.
dibatalkan dan tidak_datang membuka kembali slot.

## Asumsi yang perlu dikonfirmasi ke pemilik
- Jam buka 10:00–21:00 dan satu jadwal tunggal (satu kapster/kursi).
- Toleransi keterlambatan 15 menit sebelum kasir boleh menandai "tidak datang".
- Pelanggan boleh batal/ganti jadwal paling lambat 2 jam sebelum jam booking.
- Daftar layanan dan harga di seeder hanyalah contoh.
- Gambar QRIS diisi lewat `QRIS_IMAGE_URL` (mis. foto QRIS toko yang diunggah ke hosting).
