<?php

namespace Tests\Feature;

use App\Models\Booking;
use App\Models\Service;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BookingConflictTest extends TestCase
{
    use RefreshDatabase;

    private function slot(string $time): string
    {
        return now()->addDay()->format('Y-m-d') . ' ' . $time;
    }

    public function test_overlapping_booking_is_rejected_and_no_show_reopens_slot(): void
    {
        $service = Service::create(['name' => 'Potong', 'price' => 35000, 'duration_minutes' => 30]);
        $a = User::create(['name' => 'A', 'email' => 'a@t.test', 'password' => 'secret1', 'role' => 'pelanggan']);
        $b = User::create(['name' => 'B', 'email' => 'b@t.test', 'password' => 'secret1', 'role' => 'pelanggan']);

        $this->actingAs($a, 'sanctum')
            ->postJson('/api/bookings', ['service_id' => $service->id, 'start_at' => $this->slot('11:00')])
            ->assertCreated();

        // Bentrok sebagian (11:15 masih di dalam 11:00–11:30)
        $this->actingAs($b, 'sanctum')
            ->postJson('/api/bookings', ['service_id' => $service->id, 'start_at' => $this->slot('11:15')])
            ->assertStatus(409);

        // Setelah booking pertama tidak datang, slot terbuka lagi
        Booking::first()->update(['status' => Booking::TIDAK_DATANG]);

        $this->actingAs($b, 'sanctum')
            ->postJson('/api/bookings', ['service_id' => $service->id, 'start_at' => $this->slot('11:15')])
            ->assertCreated();
    }

    public function test_customer_cannot_open_cashier_routes(): void
    {
        $c = User::create(['name' => 'C', 'email' => 'c@t.test', 'password' => 'secret1', 'role' => 'pelanggan']);

        $this->actingAs($c, 'sanctum')->getJson('/api/cashier/queue')->assertForbidden();
    }
}
