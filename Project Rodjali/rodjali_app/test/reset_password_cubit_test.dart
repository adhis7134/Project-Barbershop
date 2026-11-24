import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:rodjali_app/blocs/reset_password_cubit.dart';
import 'package:rodjali_app/core/api_client.dart';
import 'package:rodjali_app/data/auth_repository.dart';

/// Server palsu: mencatat request dan menjawab sesuai [handler].
class _Fake {
  _Fake(this.handler);

  final (int, Map<String, dynamic>) Function(http.Request) handler;
  final requests = <http.Request>[];

  ResetPasswordCubit cubit() {
    final client = MockClient((req) async {
      requests.add(req);
      final (status, body) = handler(req);
      return http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});
    });
    return ResetPasswordCubit(AuthRepository(ApiClient(client: client)));
  }
}

void main() {
  test('sendCode berhasil: pindah ke langkah kode dan menampilkan pesan server', () async {
    final fake = _Fake((_) => (200, {'message': 'Jika email terdaftar, kode sudah dikirim.'}));
    final cubit = fake.cubit();

    await cubit.sendCode('budi@example.test');

    expect(cubit.state.step, ResetStep.code);
    expect(cubit.state.email, 'budi@example.test');
    expect(cubit.state.notice, 'Jika email terdaftar, kode sudah dikirim.');
    expect(cubit.state.busy, false);
    expect(fake.requests.single.url.path, endsWith('/forgot-password'));
    expect(jsonDecode(fake.requests.single.body), {'email': 'budi@example.test'});
  });

  test('sendCode gagal (email tidak bisa dikirim): tetap di langkah email dengan pesan error', () async {
    final fake = _Fake((_) => (503, {'message': 'Email belum bisa dikirim. Coba lagi nanti.'}));
    final cubit = fake.cubit();

    await cubit.sendCode('budi@example.test');

    expect(cubit.state.step, ResetStep.email);
    expect(cubit.state.error, 'Email belum bisa dikirim. Coba lagi nanti.');
  });

  test('reset berhasil: mengirim email, kode, dan password baru lalu selesai', () async {
    final fake = _Fake((req) => req.url.path.endsWith('/forgot-password')
        ? (200, {'message': 'ok'})
        : (200, {'message': 'Password berhasil diubah. Silakan masuk.'}));
    final cubit = fake.cubit();

    await cubit.sendCode('budi@example.test');
    await cubit.reset(code: '123456', password: 'baru1234');

    expect(cubit.state.step, ResetStep.done);
    final req = fake.requests.last;
    expect(req.url.path, endsWith('/reset-password'));
    expect(jsonDecode(req.body), {'email': 'budi@example.test', 'code': '123456', 'password': 'baru1234'});
  });

  test('reset dengan kode salah: tetap di langkah kode dan menampilkan pesan server', () async {
    final fake = _Fake((req) => req.url.path.endsWith('/forgot-password')
        ? (200, {'message': 'ok'})
        : (422, {'message': 'Kode salah atau sudah kedaluwarsa. Minta kode baru.'}));
    final cubit = fake.cubit();

    await cubit.sendCode('budi@example.test');
    await cubit.reset(code: '000000', password: 'baru1234');

    expect(cubit.state.step, ResetStep.code);
    expect(cubit.state.error, 'Kode salah atau sudah kedaluwarsa. Minta kode baru.');
    expect(cubit.state.busy, false);
  });

  test('backToEmail mengembalikan ke langkah email dan membersihkan pesan', () async {
    final fake = _Fake((_) => (200, {'message': 'ok'}));
    final cubit = fake.cubit();

    await cubit.sendCode('budi@example.test');
    cubit.backToEmail();

    expect(cubit.state.step, ResetStep.email);
    expect(cubit.state.notice, isNull);
    expect(cubit.state.error, isNull);
  });
}
