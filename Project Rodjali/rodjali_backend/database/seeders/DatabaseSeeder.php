<?php

namespace Database\Seeders;

use App\Models\Service;
use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Akun demo. Ganti nama/email/password dengan data asli pemilik dan kasir sebelum UAT.
        User::create(['name' => 'Pemilik Rodjali', 'email' => 'pemilik@rodjali.test', 'password' => 'password', 'role' => 'pemilik']);
        User::create(['name' => 'Kasir Rodjali', 'email' => 'kasir@rodjali.test', 'password' => 'password', 'role' => 'kasir']);
        User::create(['name' => 'Pelanggan Demo', 'email' => 'pelanggan@rodjali.test', 'phone' => '081200000000', 'password' => 'password', 'role' => 'pelanggan']);

        // PLACEHOLDER: daftar layanan dan harga asli belum didapat dari pemilik.
        foreach ([
            ['Potong Rambut', 35000, 30],
            ['Potong + Cuci', 45000, 45],
            ['Cukur Jenggot', 20000, 20],
        ] as [$name, $price, $minutes]) {
            Service::create(['name' => $name, 'price' => $price, 'duration_minutes' => $minutes]);
        }
    }
}
