<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    public const BELUM_LUNAS = 'belum_lunas';
    public const LUNAS = 'lunas';

    protected $fillable = ['booking_id', 'amount', 'method', 'status', 'paid_at', 'confirmed_by'];

    protected $casts = [
        'amount' => 'integer',
        'paid_at' => 'datetime',
    ];

    public function booking()
    {
        return $this->belongsTo(Booking::class);
    }
}
