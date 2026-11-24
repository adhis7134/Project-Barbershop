<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    // Laporan pendapatan: hanya transaksi lunas, dikelompokkan per hari dan per layanan.
    public function income(Request $request)
    {
        $data = $request->validate([
            'from' => 'nullable|date_format:Y-m-d',
            'to' => 'nullable|date_format:Y-m-d|after_or_equal:from',
        ]);

        $from = Carbon::parse($data['from'] ?? now()->startOfMonth())->startOfDay();
        $to = Carbon::parse($data['to'] ?? now())->endOfDay();

        $base = Transaction::where('transactions.status', Transaction::LUNAS)->whereBetween('transactions.paid_at', [$from, $to]);

        $perDay = (clone $base)
            ->selectRaw('DATE(paid_at) as date, COUNT(*) as transactions, SUM(amount) as total')
            ->groupBy('date')->orderBy('date')->get();

        $perService = (clone $base)
            ->join('bookings', 'bookings.id', '=', 'transactions.booking_id')
            ->join('services', 'services.id', '=', 'bookings.service_id')
            ->selectRaw('services.name as service, COUNT(*) as transactions, SUM(transactions.amount) as total')
            ->groupBy('services.name')->orderByDesc('total')->get();

        return response()->json([
            'from' => $from->toDateString(),
            'to' => $to->toDateString(),
            'total_income' => (int) (clone $base)->sum('amount'),
            'total_transactions' => (clone $base)->count(),
            'per_day' => $perDay,
            'per_service' => $perService,
        ]);
    }
}
