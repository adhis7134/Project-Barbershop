<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Service;
use App\Models\Transaction;
use App\Services\BookingScheduler;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CashierController extends Controller
{
    public function __construct(private BookingScheduler $scheduler)
    {
    }

    // Antrean satu hari (default hari ini): gabungan booking online dan walk-in.
    public function queue(Request $request)
    {
        $data = $request->validate(['date' => 'nullable|date_format:Y-m-d']);
        $day = Carbon::parse($data['date'] ?? today());

        $rows = Booking::with(['service', 'transaction'])
            ->whereBetween('start_at', [$day->copy()->startOfDay(), $day->copy()->endOfDay()])
            ->orderBy('start_at')
            ->get();

        return response()->json(['date' => $day->toDateString(), 'data' => $rows]);
    }

    // Jalur kedua masuknya jadwal: pelanggan datang tanpa booking.
    public function walkIn(Request $request)
    {
        $data = $request->validate([
            'customer_name' => 'required|string|max:100',
            'customer_phone' => 'nullable|string|max:20',
            'service_id' => 'required|exists:services,id',
            'start_at' => 'nullable|date_format:Y-m-d H:i',
        ]);

        $service = Service::where('is_active', true)->findOrFail($data['service_id']);
        $today = today();

        // Jika kasir tidak menentukan jam manual, cari slot kosong pertama secara otomatis.
        // Walk-in selalu ditempatkan SETELAH semua booking aktif yang ada hari ini,
        // sehingga pelanggan walk-in tidak bisa didahului oleh booking online yang dibuat belakangan.
        if (isset($data['start_at'])) {
            $start = Carbon::parse($data['start_at']);
        } else {
            $start = $this->scheduler->nextAvailableStart($service, $today);
        }

        $end = $this->scheduler->endFor($service, $start);

        $booking = DB::transaction(function () use ($data, $service, $start, $end) {
            $this->scheduler->ensureWithinHours($start, $end);
            $this->scheduler->ensureFree($start, $end);

            return Booking::create([
                'customer_name' => $data['customer_name'],
                'customer_phone' => $data['customer_phone'] ?? null,
                'service_id' => $service->id,
                'start_at' => $start,
                'end_at' => $end,
                'status' => Booking::DIPESAN,
                'source' => 'walk_in',
            ]);
        });

        return response()->json(['data' => $booking->load('service')], 201);
    }

    public function start(Booking $booking)
    {
        abort_unless($booking->status === Booking::DIPESAN, 422, 'Hanya booking berstatus dipesan yang bisa dimulai.');
        $booking->update(['status' => Booking::DIKERJAKAN]);

        return response()->json(['data' => $booking->load('service')]);
    }

    // Layanan selesai: tagihan dibuat otomatis, menunggu pembayaran QRIS.
    public function complete(Booking $booking)
    {
        abort_unless($booking->status === Booking::DIKERJAKAN, 422, 'Hanya layanan yang sedang dikerjakan yang bisa diselesaikan.');

        $transaction = DB::transaction(function () use ($booking) {
            $booking->update(['status' => Booking::SELESAI]);

            return Transaction::firstOrCreate(
                ['booking_id' => $booking->id],
                ['amount' => $booking->service->price, 'method' => 'qris', 'status' => Transaction::BELUM_LUNAS]
            );
        });

        return response()->json(['data' => $booking->load('service'), 'transaction' => $transaction]);
    }

    // Tandai "tidak datang" setelah lewat batas toleransi, supaya slot terbuka lagi.
    public function noShow(Booking $booking)
    {
        abort_unless($booking->status === Booking::DIPESAN, 422, 'Hanya booking berstatus dipesan yang bisa ditandai tidak datang.');

        $deadline = $booking->start_at->copy()->addMinutes(config('rodjali.late_tolerance_minutes'));
        abort_if(now()->lt($deadline), 422,
            'Belum melewati batas toleransi (' . config('rodjali.late_tolerance_minutes') . ' menit).');

        $booking->update(['status' => Booking::TIDAK_DATANG]);

        return response()->json(['data' => $booking]);
    }

    // Gambar QRIS toko: simpan sebagai storage/app/qris.png (atau .jpg/.jpeg/.webp).
    private function qrisFile(): ?string
    {
        foreach (['png', 'jpg', 'jpeg', 'webp'] as $ext) {
            $path = storage_path("app/qris.$ext");
            if (is_file($path)) {
                return $path;
            }
        }

        return null;
    }

    // Menyajikan gambar QRIS lewat /api supaya ikut aturan CORS (perlu agar Flutter web bisa memuatnya).
    public function qrisImage()
    {
        $path = $this->qrisFile();
        abort_unless($path, 404, 'Gambar QRIS belum diunggah.');

        return response()->file($path);
    }

    // Data untuk layar QRIS di kasir.
    public function qris(Transaction $transaction)
    {
        return response()->json([
            'transaction_id' => $transaction->id,
            'reference' => 'RJL-' . str_pad((string) $transaction->id, 6, '0', STR_PAD_LEFT),
            'amount' => $transaction->amount,
            'merchant' => config('rodjali.qris_merchant_name'),
            'qris_image_url' => $this->qrisFile() ? url('/api/qris-image') : config('rodjali.qris_image_url'),
            'status' => $transaction->status,
        ]);
    }

    // Verifikasi manual oleh kasir (tanpa payment gateway, sesuai lingkup proyek).
    public function confirmPaid(Request $request, Transaction $transaction)
    {
        abort_unless($transaction->status === Transaction::BELUM_LUNAS, 422, 'Transaksi sudah lunas.');

        $transaction->update([
            'status' => Transaction::LUNAS,
            'paid_at' => now(),
            'confirmed_by' => $request->user()->id,
        ]);

        return response()->json(['data' => $transaction]);
    }
}
