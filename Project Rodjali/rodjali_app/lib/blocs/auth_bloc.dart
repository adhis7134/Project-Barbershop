import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/api_client.dart';
import '../data/auth_repository.dart';
import '../models/models.dart';

sealed class AuthEvent {}

class AuthStarted extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  AuthLoginRequested(this.email, this.password);
  final String email;
  final String password;
}

class AuthRegisterRequested extends AuthEvent {
  AuthRegisterRequested({required this.name, required this.email, this.phone, required this.password});
  final String name;
  final String email;
  final String? phone;
  final String password;
}

class AuthLogoutRequested extends AuthEvent {}

class AuthSessionExpired extends AuthEvent {}

sealed class AuthState {}

/// Sedang memeriksa token tersimpan (layar pembuka).
class AuthInitial extends AuthState {}

/// Proses login berjalan; form login tetap tampil.
class AuthInProgress extends AuthState {}

class Authenticated extends AuthState {
  Authenticated(this.user);
  final AppUser user;
}

class Unauthenticated extends AuthState {
  Unauthenticated({this.error});
  final String? error;
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthSessionExpired>(_onExpired);
  }

  final AuthRepository _repo;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    try {
      final user = await _repo.restore();
      emit(user == null ? Unauthenticated() : Authenticated(user));
    } on ApiException catch (e) {
      emit(Unauthenticated(error: e.status == 401 ? null : e.message));
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthInProgress());
    try {
      final user = await _repo.login(event.email, event.password);
      emit(Authenticated(user));
    } on ApiException catch (e) {
      emit(Unauthenticated(error: e.message));
    } catch (_) {
      emit(Unauthenticated(error: 'Respons server tidak dikenali.'));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthInProgress());
    try {
      final user = await _repo.register(
        name: event.name,
        email: event.email,
        phone: event.phone,
        password: event.password,
      );
      emit(Authenticated(user));
    } on ApiException catch (e) {
      emit(Unauthenticated(error: e.message));
    } catch (_) {
      emit(Unauthenticated(error: 'Respons server tidak dikenali.'));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _repo.logout();
    emit(Unauthenticated());
  }

  Future<void> _onExpired(AuthSessionExpired event, Emitter<AuthState> emit) async {
    await _repo.forgetSession();
    emit(Unauthenticated(error: 'Sesi berakhir, silakan masuk lagi.'));
  }
}
