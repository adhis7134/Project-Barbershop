<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Booking extends Model
{
    public const DIPESAN = 'dipesan';
    public const DIKERJAKAN = 'dikerjakan';
    public const SELESAI = 'selesai';
    public const DIBATALKAN = 'dibatalkan';
    public const TIDAK_DATANG = 'tidak_datang';

    protected $fillable = [
        'customer_id', 'customer_name', 'customer_phone', 'service_id',
        'start_at', 'end_at', 'status', 'source',
    ];

    protected $casts = [
        'start_at' => 'datetime',
        'end_at' => 'datetime',
    ];

    // Hanya booking aktif yang menempati slot. Dibatalkan/tidak datang otomatis membuka slot.
    public function scopeActive($q)
    {
        return $q->whereIn('status', [self::DIPESAN, self::DIKERJAKAN]);
    }

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function service()
    {
        return $this->belongsTo(Service::class);
    }

    public function transaction()
    {
        return $this->hasOne(Transaction::class);
    }
}
