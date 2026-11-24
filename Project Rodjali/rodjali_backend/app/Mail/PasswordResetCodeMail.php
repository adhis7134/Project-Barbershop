<?php

namespace App\Mail;

use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;

class PasswordResetCodeMail extends Mailable
{
    public function __construct(public string $code, public int $minutes)
    {
    }

    public function envelope(): Envelope
    {
        return new Envelope(subject: 'Kode reset password Rodjali Barbershop');
    }

    public function content(): Content
    {
        $html = '<p>Halo,</p>'
            .'<p>Kode reset password Anda: <strong style="font-size:22px;letter-spacing:4px">'.e($this->code).'</strong></p>'
            .'<p>Kode berlaku '.$this->minutes.' menit dan hanya bisa dipakai sekali.</p>'
            .'<p>Jika Anda tidak merasa meminta reset password, abaikan email ini.</p>'
            .'<p>Rodjali Barbershop</p>';

        return new Content(htmlString: $html);
    }
}
