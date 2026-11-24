import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../data/cashier_repository.dart';
import '../models/models.dart';

enum WalkInStatus { loading, ready, submitting, success, loadFailed }

class WalkInState {
  const WalkInState({
    this.status = WalkInStatus.loading,
    this.services = const [],
    this.selectedServiceId,
    this.availability,
    this.slotsLoading = false,
    this.selectedSlot,
    this.error,
  });

  final WalkInStatus status;
  final List<Service> services;
  final int? selectedServiceId;
  final Availability? availability;
  final bool slotsLoading;
  final DateTime? selectedSlot; // jam mulai yang dipilih kasir (opsional)
  final String? error;

  Service? get selectedService {
    for (final s in services) {
      if (s.id == selectedServiceId) return s;
    }
    return null;
  }

  WalkInState copyWith({
    WalkInStatus? status,
    List<Service>? services,
    int? selectedServiceId,
    Availability? availability,
    bool? slotsLoading,
    DateTime? selectedSlot,
    bool clearSlot = false,
    String? error,
    bool clearError = false,
  }) =>
      WalkInState(
        status: status ?? this.status,
        services: services ?? this.services,
        selectedServiceId: selectedServiceId ?? this.selectedServiceId,
        availability: availability ?? this.availability,
        slotsLoading: slotsLoading ?? this.slotsLoading,
        selectedSlot: clearSlot ? null : (selectedSlot ?? this.selectedSlot),
        error: clearError ? null : (error ?? this.error),
      );
}

class WalkInCubit extends Cubit<WalkInState> {
  WalkInCubit(this._repo) : super(const WalkInState());

  final CashierRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: WalkInStatus.loading, clearError: true));
    try {
      final all = await _repo.services();
      final av = await _repo.availability(wibToday());
      emit(state.copyWith(
        status: WalkInStatus.ready,
        services: all.where((s) => s.isActive).toList(),
        availability: av,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: WalkInStatus.loadFailed, error: e.message));
    } catch (_) {
      emit(state.copyWith(status: WalkInStatus.loadFailed, error: 'Daftar layanan tidak bisa dibaca.'));
    }
  }

  void select(int? serviceId) =>
      emit(state.copyWith(selectedServiceId: serviceId, clearSlot: true, clearError: true));

  void selectSlot(DateTime slot) => emit(state.copyWith(selectedSlot: slot, clearError: true));

  Future<void> submit({required String name, String? phone}) async {
    final serviceId = state.selectedServiceId;
    if (serviceId == null) return;
    emit(state.copyWith(status: WalkInStatus.submitting, clearError: true));
    try {
      await _repo.walkIn(
        name: name,
        phone: phone,
        serviceId: serviceId,
        startAt: state.selectedSlot,
      );
      emit(state.copyWith(status: WalkInStatus.success));
    } on ApiException catch (e) {
      emit(state.copyWith(status: WalkInStatus.ready, error: e.message, clearSlot: true));
      // Jika slot sudah direbut (409), refresh availability supaya slot langsung abu-abu.
      if (e.isConflict) await _refreshAvailability();
    } catch (_) {
      emit(state.copyWith(status: WalkInStatus.ready, error: 'Respons server tidak dikenali.'));
    }
  }

  Future<void> _refreshAvailability() async {
    try {
      final av = await _repo.availability(wibToday());
      emit(state.copyWith(availability: av));
    } catch (_) {
      // Abaikan; pesan 409 sudah tampil.
    }
  }
}
