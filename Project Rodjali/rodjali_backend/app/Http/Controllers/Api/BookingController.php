<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Service;
use App\Services\BookingScheduler;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BookingController extends Controller
{
    public function __construct(private BookingScheduler $scheduler)
    {
    }

    // Slot yang sudah terisi pada satu tanggal, supaya aplikasi bisa menonaktifkan jam tersebut.
    public function availability(Request $request)
    {
        $data = $request->validate(['date' => 'required|date_format:Y-m-d']);
        $day = Carbon::parse($data['date']);

        $taken = Booking::active()
            ->whereBetween('start_at', [$day->copy()->startOfDay(), $day->copy()->endOfDay()])
            ->orderBy('start_at')
            ->get(['start_at', 'end_at']);

        return response()->json([
            'date' => $data['date'],
            'open' => config('rodjali.open'),
            'close' => config('rodjali.close'),
            'taken' => $taken,
        ]);
    }

    public function index(Request $request)
    {
        $bookings = Booking::with(['service', 'transaction'])
            ->where('customer_id', $request->user()->id)
            ->orderByDesc('start_at')
            ->get();

        return response()->json(['data' => $bookings]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'service_id' => 'required|exists:services,id',
            'start_at' => 'required|date_format:Y-m-d H:i|after:now',
        ]);

        $service = Service::where('is_active', true)->findOrFail($data['service_id']);
        $start = Carbon::parse($data['start_at']);
        $end = $this->scheduler->endFor($service, $start);
        $user = $request->user();

        $booking = DB::transaction(function () use ($service, $start, $end, $user) {
            $this->scheduler->ensureWithinHours($start, $end);
            $this->scheduler->ensureFree($start, $end);

            return Booking::create([
                'customer_id' => $user->id,
                'customer_name' => $user->name,
                'customer_phone' => $user->phone,
                'service_id' => $service->id,
                'start_at' => $start,
                'end_at' => $end,
                'status' => Booking::DIPESAN,
                'source' => 'online',
            ]);
        });

        return response()->json(['data' => $booking->load('service')], 201);
    }

    // Ganti jadwal. Hanya booking milik sendiri, berstatus dipesan, dan belum terlalu dekat waktunya.
    public function update(Request $request, Booking $booking)
    {
        $this->authorizeChange($request, $booking);

        $data = $request->validate([
            'start_at' => 'required|date_format:Y-m-d H:i|after:now',
        ]);

        $start = Carbon::parse($data['start_at']);
        $end = $this->scheduler->endFor($booking->service, $start);

        DB::transaction(function () use ($booking, $start, $end) {
            $this->scheduler->ensureWithinHours($start, $end);
            $this->scheduler->ensureFree($start, $end, $booking->id);
            $booking->update(['start_at' => $start, 'end_at' => $end]);
        });

        return response()->json(['data' => $booking->fresh('service')]);
    }

    public function cancel(Request $request, Booking $booking)
    {
        $this->authorizeChange($request, $booking);

        $booking->update(['status' => Booking::DIBATALKAN]);

        return response()->json(['data' => $booking]);
    }

    private function authorizeChange(Request $request, Booking $booking): void
    {
        abort_unless($booking->customer_id === $request->user()->id, 403, 'Bukan booking Anda.');
        abort_unless($booking->status === Booking::DIPESAN, 422, 'Booking ini sudah tidak bisa diubah.');

        $limit = now()->addHours(config('rodjali.cancel_min_hours'));
        abort_if($booking->start_at->lt($limit), 422,
            'Perubahan hanya bisa dilakukan minimal ' . config('rodjali.cancel_min_hours') . ' jam sebelum jadwal.');
    }
}
