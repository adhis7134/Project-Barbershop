<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('bookings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('customer_name');
            $table->string('customer_phone', 20)->nullable();
            $table->foreignId('service_id')->constrained('services');
            $table->dateTime('start_at');
            $table->dateTime('end_at');
            $table->enum('status', ['dipesan', 'dikerjakan', 'selesai', 'dibatalkan', 'tidak_datang'])->default('dipesan');
            $table->enum('source', ['online', 'walk_in'])->default('online');
            $table->timestamps();

            $table->index(['start_at', 'end_at']);
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bookings');
    }
};
