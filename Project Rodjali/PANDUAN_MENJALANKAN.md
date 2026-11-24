# Panduan Menjalankan Aplikasi Mobile Rodjali Barbershop

Aplikasi ini terdiri dari dua bagian utama:
1. **Backend API**: Berbasis **Laravel 11** dan **MySQL** (XAMPP).
2. **Frontend Mobile**: Berbasis **Flutter**.

---

## 1. Akun Demo untuk Login

Database sudah dimigrasikan dan diisi data awal (*seeded*). Anda dapat menggunakan akun berikut untuk login:

| Peran (Role) | Email | Password | Keterangan |
| :--- | :--- | :--- | :--- |
| **Pemilik** | `pemilik@rodjali.test` | `password` | Mengelola layanan, melihat laporan & antrean |
| **Kasir** | `kasir@rodjali.test` | `password` | Mengelola antrean, input walk-in, pembayaran QRIS |
| **Pelanggan** | `pelanggan@rodjali.test` | `password` | Melakukan booking jadwal potong rambut |

*(Atau Anda bisa mendaftar akun baru langsung melalui menu Registrasi di aplikasi).*

---

## 2. Cara Menjalankan (Otomatis via Batch Script)

Cukup klik dua kali file berikut di folder `Project Rodjali`:

1. **Jalankan Backend**:
   - Double-click `jalankan_backend.bat`
   - Script akan otomatis mengecek MySQL XAMPP dan menjalankan server Laravel di `http://127.0.0.1:8000`.

2. **Jalankan Aplikasi Flutter**:
   - **Di Google Chrome (Paling Cepat & Ringan)**: Double-click `jalankan_app_chrome.bat`
   - **Di Android Emulator**: Double-click `jalankan_app_emulator.bat`

---

## 3. Cara Menjalankan Manual Lewat Terminal (VS Code / PowerShell)

### Langkah A: Nyalakan Backend & Database
1. Buka XAMPP Control Panel, klik **Start** pada **MySQL**.
2. Buka terminal di folder backend:
   ```powershell
   cd "c:\Users\MyBook Hype AMD\OneDrive\Documents\TUGAS SEMESTER 5\Tugas Mobile Programming\Project Rodjali\Project Rodjali\rodjali_backend"
   php artisan serve --host=0.0.0.0 --port=8000
   ```

### Langkah B: Jalankan Aplikasi Flutter
Buka terminal baru di folder aplikasi Flutter:
```powershell
cd "c:\Users\MyBook Hype AMD\OneDrive\Documents\TUGAS SEMESTER 5\Tugas Mobile Programming\Project Rodjali\Project Rodjali\rodjali_app"
```

- **Untuk Web (Chrome)**:
  ```powershell
  flutter run -d chrome
  ```
- **Untuk Android Emulator**:
  ```powershell
  flutter run -d Medium_Phone --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
  ```
- **Untuk HP Fisik (USB Debugging)**:
  ```powershell
  adb reverse tcp:8000 tcp:8000
  flutter run
  ```
