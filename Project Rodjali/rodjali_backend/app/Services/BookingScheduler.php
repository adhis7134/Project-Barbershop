<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\Service;
use Carbon\Carbon;
use Illuminate\Validation\ValidationException;

/**
 * Aturan jadwal tunggal: satu slot hanya boleh ditempati satu booking aktif.
 * Dipakai bersama oleh booking pelanggan dan input walk-in kasir,
 * jadi penolakan bentrok selalu terjadi di server.
 */
class BookingScheduler
{
    public function endFor(Service $service, Carbon $start): Carbon
    {
        return $start->copy()->addMinutes($service->duration_minutes);
    }

    public function ensureWithinHours(Carbon $start, Carbon $end): void
    {
        $open = $start->copy()->setTimeFromTimeString(config('rodjali.open'));
        $close = $start->copy()->setTimeFromTimeString(config('rodjali.close'));

        if ($start->lt($open) || $end->gt($close) || !$start->isSameDay($end)) {
            throw ValidationException::withMessages([
                'start_at' => ['Di luar jam buka (' . config('rodjali.open') . '–' . config('rodjali.close') . ').'],
            ]);
        }
    }

    // Panggil di dalam DB::transaction agar lockForUpdate efektif dan tidak ada double booking.
    public function ensureFree(Carbon $start, Carbon $end, ?int $ignoreId = null): void
    {
        $q = Booking::active()
            ->where('start_at', '<', $end)
            ->where('end_at', '>', $start)
            ->lockForUpdate();

        if ($ignoreId) {
            $q->where('id', '!=', $ignoreId);
        }

        if ($q->exists()) {
            abort(409, 'Slot waktu tersebut sudah terisi. Pilih jam lain.');
        }
    }

    /**
     * Cari slot kosong pertama untuk walk-in:
     * ambil waktu terbesar antara (now) dan (akhir booking terakhir hari ini),
     * sehingga walk-in selalu antre DI BELAKANG semua booking aktif yang sudah ada,
     * baik booking online maupun walk-in sebelumnya.
     *
     * Ini mencegah walk-in baru "menyerobot" di tengah-tengah antrian yang sudah ada.
     */
    public function nextAvailableStart(Service $service, Carbon $day): Carbon
    {
        // Waktu mulai paling awal: sekarang (tidak bisa pesan di masa lalu)
        $earliest = now()->startOfMinute();

        // Cari akhir dari booking aktif terakhir hari ini
        $lastEnd = Booking::active()
            ->whereBetween('start_at', [$day->copy()->startOfDay(), $day->copy()->endOfDay()])
            ->max('end_at');

        if ($lastEnd) {
            $lastEnd = Carbon::parse($lastEnd);
            // Walk-in mulai setelah booking terakhir, atau sekarang jika sudah lewat
            $candidate = $lastEnd->gt($earliest) ? $lastEnd : $earliest;
        } else {
            $candidate = $earliest;
        }

        return $candidate;
    }
}
