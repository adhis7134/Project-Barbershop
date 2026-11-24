<?php

// Semua nilai bisa diubah lewat .env tanpa mengubah kode.
return [
    'open'  => env('SHOP_OPEN', '10:00'),
    'close' => env('SHOP_CLOSE', '21:00'),

    // BELUM DIKONFIRMASI ke pemilik: nilai di bawah adalah asumsi sementara.
    'late_tolerance_minutes' => (int) env('LATE_TOLERANCE_MINUTES', 15),
    'cancel_min_hours'       => (int) env('CANCEL_MIN_HOURS', 2),

    'qris_merchant_name' => env('QRIS_MERCHANT_NAME', 'Rodjali Barbershop'),
    'qris_image_url'     => env('QRIS_IMAGE_URL', ''),
];
