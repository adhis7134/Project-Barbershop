import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/api_client.dart';
import '../data/owner_repository.dart';
import '../models/models.dart';

enum ServicesStatus { loading, ready, failure }

class ServicesState {
  const ServicesState({
    this.status = ServicesStatus.loading,
    this.services = const [],
    this.busy = false,
    this.error,
    this.message,
    this.messageIsError = false,
    this.messageSeq = 0,
  });

  final ServicesStatus status;
  final List<Service> services;
  final bool busy;
  final String? error;
  final String? message;
  final bool messageIsError;
  final int messageSeq; // naik setiap ada pesan baru, dipakai UI untuk SnackBar

  ServicesState copyWith({
    ServicesStatus? status,
    List<Service>? services,
    bool? busy,
    String? error,
    String? message,
    bool? messageIsError,
  }) =>
      ServicesState(
        status: status ?? this.status,
        services: services ?? this.services,
        busy: busy ?? this.busy,
        error: error ?? this.error,
        message: message ?? this.message,
        messageIsError: messageIsError ?? this.messageIsError,
        messageSeq: message != null ? messageSeq + 1 : messageSeq,
      );
}

class ServicesCubit extends Cubit<ServicesState> {
  ServicesCubit(this._repo) : super(const ServicesState());

  final OwnerRepository _repo;

  Future<void> load({bool spinner = true}) async {
    if (spinner) emit(state.copyWith(status: ServicesStatus.loading));
    try {
      final list = await _repo.services();
      emit(state.copyWith(status: ServicesStatus.ready, services: list));
    } on ApiException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('Daftar layanan tidak bisa dibaca.');
    }
  }

  void _fail(String message) {
    if (state.services.isEmpty) {
      emit(state.copyWith(status: ServicesStatus.failure, error: message));
    } else {
      emit(state.copyWith(message: message, messageIsError: true));
    }
  }

  /// Mengembalikan pesan error untuk ditampilkan di form, atau null jika berhasil.
  Future<String?> save({
    Service? existing,
    required String name,
    required int price,
    required int duration,
  }) async {
    try {
      if (existing == null) {
        await _repo.create(name: name, price: price, duration: duration);
      } else {
        await _repo.update(existing.id, name: name, price: price, duration: duration);
      }
      await load(spinner: false);
      emit(state.copyWith(
        message: existing == null ? 'Layanan ditambahkan.' : 'Layanan diperbarui.',
        messageIsError: false,
      ));
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Respons server tidak dikenali.';
    }
  }

  Future<void> setActive(Service s, bool value) async {
    emit(state.copyWith(busy: true));
    try {
      await _repo.update(s.id, isActive: value);
      await load(spinner: false);
      emit(state.copyWith(
        busy: false,
        message: value ? '${s.name} diaktifkan.' : '${s.name} dinonaktifkan.',
        messageIsError: false,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, message: e.message, messageIsError: true));
    } catch (_) {
      emit(state.copyWith(busy: false, message: 'Respons server tidak dikenali.', messageIsError: true));
    }
  }

  Future<void> remove(Service s) async {
    emit(state.copyWith(busy: true));
    try {
      final msg = await _repo.remove(s.id);
      await load(spinner: false);
      emit(state.copyWith(busy: false, message: msg, messageIsError: false));
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, message: e.message, messageIsError: true));
    } catch (_) {
      emit(state.copyWith(busy: false, message: 'Respons server tidak dikenali.', messageIsError: true));
    }
  }
}
