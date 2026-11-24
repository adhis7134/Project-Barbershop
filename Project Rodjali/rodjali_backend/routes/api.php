<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BookingController;
use App\Http\Controllers\Api\CashierController;
use App\Http\Controllers\Api\PasswordResetController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\ServiceController;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Lupa password: kode 6 digit dikirim ke email, lalu dipakai untuk membuat password baru.
Route::post('/forgot-password', [PasswordResetController::class, 'sendCode'])->middleware('throttle:5,1');
Route::post('/reset-password', [PasswordResetController::class, 'reset'])->middleware('throttle:10,1');
// Gambar QRIS dibuka tanpa token karena dimuat langsung oleh widget gambar.
Route::get('/qris-image', [CashierController::class, 'qrisImage']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/services', [ServiceController::class, 'index']);
    Route::get('/availability', [BookingController::class, 'availability']);

    // Pemilik: kelola layanan dan lihat laporan
    Route::middleware('role:pemilik')->group(function () {
        Route::post('/services', [ServiceController::class, 'store']);
        Route::put('/services/{service}', [ServiceController::class, 'update']);
        Route::delete('/services/{service}', [ServiceController::class, 'destroy']);
        Route::get('/reports/income', [ReportController::class, 'income']);
    });

    // Pelanggan: booking, ganti jadwal, batal, lihat status
    Route::middleware('role:pelanggan')->group(function () {
        Route::get('/bookings', [BookingController::class, 'index']);
        Route::post('/bookings', [BookingController::class, 'store']);
        Route::put('/bookings/{booking}', [BookingController::class, 'update']);
        Route::post('/bookings/{booking}/cancel', [BookingController::class, 'cancel']);
    });

    // Kasir (pemilik juga boleh): antrean, walk-in, layanan, QRIS, konfirmasi lunas
    Route::middleware('role:kasir,pemilik')->prefix('cashier')->group(function () {
        Route::get('/queue', [CashierController::class, 'queue']);
        Route::post('/walk-in', [CashierController::class, 'walkIn']);
        Route::post('/bookings/{booking}/start', [CashierController::class, 'start']);
        Route::post('/bookings/{booking}/complete', [CashierController::class, 'complete']);
        Route::post('/bookings/{booking}/no-show', [CashierController::class, 'noShow']);
        Route::get('/transactions/{transaction}/qris', [CashierController::class, 'qris']);
        Route::post('/transactions/{transaction}/confirm-paid', [CashierController::class, 'confirmPaid']);
    });
});
