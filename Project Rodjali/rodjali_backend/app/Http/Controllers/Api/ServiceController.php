<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Service;
use Illuminate\Http\Request;

class ServiceController extends Controller
{
    // Pemilik melihat semua layanan; peran lain hanya yang aktif.
    public function index(Request $request)
    {
        $q = Service::orderBy('name');

        if ($request->user()->role !== 'pemilik') {
            $q->where('is_active', true);
        }

        return response()->json(['data' => $q->get()]);
    }

    public function store(Request $request)
    {
        $service = Service::create($this->rules($request));

        return response()->json(['data' => $service], 201);
    }

    public function update(Request $request, Service $service)
    {
        $service->update($this->rules($request, true));

        return response()->json(['data' => $service]);
    }

    // Layanan yang sudah punya riwayat booking dinonaktifkan, bukan dihapus, agar laporan tetap utuh.
    public function destroy(Service $service)
    {
        if ($service->bookings()->exists()) {
            $service->update(['is_active' => false]);

            return response()->json(['message' => 'Layanan sudah punya riwayat, jadi dinonaktifkan.']);
        }

        $service->delete();

        return response()->json(['message' => 'Layanan dihapus.']);
    }

    private function rules(Request $request, bool $partial = false): array
    {
        $req = $partial ? 'sometimes|' : '';

        return $request->validate([
            'name' => $req . 'required|string|max:100',
            'price' => $req . 'required|integer|min:0',
            'duration_minutes' => $req . 'required|integer|min:5|max:480',
            'is_active' => 'sometimes|boolean',
        ]);
    }
}
