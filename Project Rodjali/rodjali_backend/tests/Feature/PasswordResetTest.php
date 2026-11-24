<?php

namespace Tests\Feature;

use App\Mail\PasswordResetCodeMail;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class PasswordResetTest extends TestCase
{
    use RefreshDatabase;

    private const EMAIL = 'budi@example.test';

    protected function setUp(): void
    {
        parent::setUp();
        Mail::fake();
        User::create([
            'name' => 'Budi',
            'email' => self::EMAIL,
            'password' => 'lama123',
            'role' => User::ROLE_PELANGGAN,
        ]);
    }

    private function requestCode(): string
    {
        $this->postJson('/api/forgot-password', ['email' => self::EMAIL])->assertOk();

        return Mail::sent(PasswordResetCodeMail::class)->last()->code;
    }

    private function reset(string $code, string $password = 'baru1234')
    {
        return $this->postJson('/api/reset-password', [
            'email' => self::EMAIL,
            'code' => $code,
            'password' => $password,
        ]);
    }

    public function test_kode_dikirim_ke_email_terdaftar_dan_berbentuk_6_digit(): void
    {
        $code = $this->requestCode();

        $this->assertMatchesRegularExpression('/^\d{6}$/', $code);
        Mail::assertSent(PasswordResetCodeMail::class, fn ($m) => $m->hasTo(self::EMAIL));
    }

    public function test_email_tidak_terdaftar_dijawab_sama_dan_tidak_ada_email_terkirim(): void
    {
        $this->postJson('/api/forgot-password', ['email' => 'tidakada@example.test'])->assertOk();

        Mail::assertNothingSent();
    }

    public function test_minta_kode_berulang_dalam_semenit_tidak_mengirim_dua_kali(): void
    {
        $this->requestCode();
        $this->postJson('/api/forgot-password', ['email' => self::EMAIL])->assertOk();

        Mail::assertSent(PasswordResetCodeMail::class, 1);
    }

    public function test_kode_benar_mengubah_password_dan_mencabut_token_lama(): void
    {
        $user = User::where('email', self::EMAIL)->first();
        $user->createToken('mobile');
        $this->assertSame(1, $user->tokens()->count());
        $code = $this->requestCode();

        $this->reset($code)->assertOk();

        // Dicek sebelum login, karena login membuat token baru.
        $this->assertSame(0, $user->tokens()->count());
        $this->postJson('/api/login', ['email' => self::EMAIL, 'password' => 'lama123'])->assertStatus(401);
        $this->postJson('/api/login', ['email' => self::EMAIL, 'password' => 'baru1234'])->assertOk();
    }

    public function test_kode_hanya_bisa_dipakai_sekali(): void
    {
        $code = $this->requestCode();

        $this->reset($code)->assertOk();
        $this->reset($code, 'lainnya99')->assertStatus(422);
    }

    public function test_kode_salah_ditolak_dan_password_tidak_berubah(): void
    {
        $code = $this->requestCode();
        $wrong = $code === '000000' ? '111111' : '000000';

        $this->reset($wrong)->assertStatus(422);

        $this->postJson('/api/login', ['email' => self::EMAIL, 'password' => 'lama123'])->assertOk();
    }

    public function test_lima_kali_salah_membatalkan_kode_walau_akhirnya_benar(): void
    {
        $code = $this->requestCode();
        $wrong = $code === '000000' ? '111111' : '000000';

        for ($i = 0; $i < 5; $i++) {
            $this->reset($wrong)->assertStatus(422);
        }

        $this->reset($code)->assertStatus(422);
        $this->postJson('/api/login', ['email' => self::EMAIL, 'password' => 'lama123'])->assertOk();
    }

    public function test_kode_kedaluwarsa_setelah_15_menit(): void
    {
        $code = $this->requestCode();

        $this->travel(16)->minutes();

        $this->reset($code)->assertStatus(422);
    }

    public function test_password_baru_minimal_6_karakter(): void
    {
        $code = $this->requestCode();

        $this->reset($code, '123')->assertStatus(422);
    }
}
