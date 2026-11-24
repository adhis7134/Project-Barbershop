import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../data/customer_repository.dart';
import '../models/models.dart';

enum BookingFormStatus { loading, ready, submitting, success, loadFailed }

class BookingFormState {
  const BookingFormState({
    this.status = BookingFormStatus.loading,
    this.services = const [],
    this.serviceId,
    required this.date,
    this.availability,
    this.slotsLoading = false,
    this.slot,
    this.error,
  });

  final BookingFormStatus status;
  final List<Service> services;
  final int? serviceId;
  final DateTime date;
  final Availability? availability;
  final bool slotsLoading;
  final DateTime? slot; // jam mulai terpilih (jam dinding WIB)
  final String? error;

  Service? get service {
    for (final s in services) {
      if (s.id == serviceId) return s;
    }
    return null;
  }

  bool get canSubmit => status == BookingFormStatus.ready && service != null && slot != null && !slotsLoading;

  BookingFormState copyWith({
    BookingFormStatus? status,
    List<Service>? services,
    int? serviceId,
    DateTime? date,
    Availability? availability,
    bool? slotsLoading,
    DateTime? slot,
    bool clearSlot = false,
    String? error,
    bool clearError = false,
  }) {
    return BookingFormState(
      status: status ?? this.status,
      services: services ?? this.services,
      serviceId: serviceId ?? this.serviceId,
      date: date ?? this.date,
      availability: availability ?? this.availability,
      slotsLoading: slotsLoading ?? this.slotsLoading,
      slot: clearSlot ? null : (slot ?? this.slot),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Dipakai untuk booking baru ([editing] null) dan ganti jadwal ([editing] diisi; layanan tetap).
class BookingFormCubit extends Cubit<BookingFormState> {
  BookingFormCubit(this._repo, {this.editing})
      : super(BookingFormState(
          date: editing == null
              ? wibToday()
              : DateTime.utc(editing.startAt.year, editing.startAt.month, editing.startAt.day),
        ));

  final CustomerRepository _repo;
  final Booking? editing;

  /// Jadwal lama sendiri tidak boleh dihitung bentrok saat ganti jadwal.
  TakenSlot? get ignoreSlot => editing == null ? null : TakenSlot(start: editing!.startAt, end: editing!.endAt);

  Future<void> load() async {
    emit(state.copyWith(status: BookingFormStatus.loading, clearError: true));
    try {
      final List<Service> services;
      int? serviceId;
      if (editing != null) {
        final s = editing!.service;
        services = [?s];
        serviceId = s?.id;
      } else {
        services = (await _repo.services()).where((s) => s.isActive).toList();
      }
      final av = await _repo.availability(state.date);
      emit(state.copyWith(
        status: BookingFormStatus.ready,
        services: services,
        serviceId: serviceId,
        availability: av,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(status: BookingFormStatus.loadFailed, error: e.message));
    } catch (_) {
      emit(state.copyWith(status: BookingFormStatus.loadFailed, error: 'Data jadwal tidak bisa dibaca.'));
    }
  }

  void selectService(int id) => emit(state.copyWith(serviceId: id, clearSlot: true, clearError: true));

  void selectSlot(DateTime start) => emit(state.copyWith(slot: start, clearError: true));

  Future<void> selectDate(DateTime date) async {
    emit(state.copyWith(date: date, slotsLoading: true, clearSlot: true, clearError: true));
    try {
      final av = await _repo.availability(date);
      if (state.date != date) return; // pengguna sudah pindah tanggal lagi
      emit(state.copyWith(availability: av, slotsLoading: false));
    } on ApiException catch (e) {
      if (state.date != date) return;
      emit(state.copyWith(slotsLoading: false, error: e.message));
    } catch (_) {
      if (state.date != date) return;
      emit(state.copyWith(slotsLoading: false, error: 'Jadwal tidak bisa dimuat.'));
    }
  }

  Future<void> submit() async {
    final slot = state.slot;
    final service = state.service;
    if (slot == null || service == null) return;

    emit(state.copyWith(status: BookingFormStatus.submitting, clearError: true));
    try {
      if (editing != null) {
        await _repo.reschedule(editing!.id, slot);
      } else {
        await _repo.book(serviceId: service.id, startAt: slot);
      }
      emit(state.copyWith(status: BookingFormStatus.success));
    } on ApiException catch (e) {
      emit(state.copyWith(status: BookingFormStatus.ready, error: e.message, clearSlot: true));
      if (e.isConflict) await _refreshAvailability(); // slot yang direbut orang lain langsung abu-abu
    } catch (_) {
      emit(state.copyWith(status: BookingFormStatus.ready, error: 'Respons server tidak dikenali.'));
    }
  }

  Future<void> _refreshAvailability() async {
    try {
      final av = await _repo.availability(state.date);
      emit(state.copyWith(availability: av));
    } catch (_) {
      // Abaikan; pesan 409 sudah tampil.
    }
  }
}
