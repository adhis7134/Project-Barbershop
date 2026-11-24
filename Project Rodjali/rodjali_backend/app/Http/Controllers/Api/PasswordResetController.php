<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Mail\PasswordResetCodeMail;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\RateLimiter;

/**
 * Reset password lewat kode 6 digit yang dikirim ke email.
 * Memakai tabel bawaan Laravel `password_reset_tokens`; yang disimpan adalah hash kode, bukan kodenya.
 */
class PasswordResetController extends Controller
{
    private const EXPIRE_MINUTES = 15;   // masa berlaku kode
    private const RESEND_SECONDS = 60;   // jeda minimal sebelum kode baru dikirim
    private const MAX_ATTEMPTS = 5;      // salah memasukkan kode berapa kali sebelum kode dibatalkan

    // Langkah 1: minta kode. Jawaban selalu sama agar orang lain tidak bisa menebak email mana yang terdaftar.
    public function sendCode(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => 'required|email']);
        $email = strtolower($data['email']);

        $reply = response()->json([
            'message' => 'Jika email terdaftar, kode reset 6 digit sudah dikirim. Berlaku '.self::EXPIRE_MINUTES.' menit.',
        ]);

        $user = User::where('email', $email)->first();
        if (! $user) {
            return $reply;
        }

        $existing = DB::table('password_reset_tokens')->where('email', $email)->first();
        if ($existing && $existing->created_at
            && Carbon::parse($existing->created_at)->gt(now()->subSeconds(self::RESEND_SECONDS))) {
            return $reply; // baru saja dikirim, tidak kirim ulang
        }

        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $email],
            ['token' => Hash::make($code), 'created_at' => now()]
        );
        RateLimiter::clear($this->attemptKey($email));

        try {
            Mail::to($user->email)->send(new PasswordResetCodeMail($code, self::EXPIRE_MINUTES));
        } catch (\Throwable $e) {
            report($e);
            DB::table('password_reset_tokens')->where('email', $email)->delete();
            abort(503, 'Email belum bisa dikirim. Coba lagi nanti.');
        }

        return $reply;
    }

    // Langkah 2: kirim kode + password baru.
    public function reset(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => 'required|email',
            'code' => 'required|digits:6',
            'password' => 'required|string|min:6|max:100',
        ]);
        $email = strtolower($data['email']);
        $key = $this->attemptKey($email);

        if (RateLimiter::tooManyAttempts($key, self::MAX_ATTEMPTS)) {
            DB::table('password_reset_tokens')->where('email', $email)->delete();
            abort(422, 'Terlalu banyak percobaan. Minta kode baru.');
        }

        $row = DB::table('password_reset_tokens')->where('email', $email)->first();
        $user = User::where('email', $email)->first();
        $expired = ! $row || ! $row->created_at
            || Carbon::parse($row->created_at)->lt(now()->subMinutes(self::EXPIRE_MINUTES));

        if (! $user || $expired || ! Hash::check($data['code'], $row->token)) {
            RateLimiter::hit($key, self::EXPIRE_MINUTES * 60);
            abort(422, 'Kode salah atau sudah kedaluwarsa. Minta kode baru.');
        }

        $user->forceFill(['password' => $data['password']])->save(); // di-hash otomatis oleh cast 'hashed'
        $user->tokens()->delete(); // semua perangkat harus masuk ulang dengan password baru
        DB::table('password_reset_tokens')->where('email', $email)->delete();
        RateLimiter::clear($key);

        return response()->json(['message' => 'Password berhasil diubah. Silakan masuk.']);
    }

    private function attemptKey(string $email): string
    {
        return 'password-reset:'.$email;
    }
}
