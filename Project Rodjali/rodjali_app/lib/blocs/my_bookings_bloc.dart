import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/api_client.dart';
import '../data/customer_repository.dart';
import '../models/models.dart';

enum MyBookingsStatus { loading, ready, failure }

sealed class MyBookingsEvent {}

class MyBookingsStarted extends MyBookingsEvent {}

class MyBookingsRefreshed extends MyBookingsEvent {}

class MyBookingCancelRequested extends MyBookingsEvent {
  MyBookingCancelRequested(this.booking);
  final Booking booking;
}

class MyBookingsState {
  const MyBookingsState({
    this.status = MyBookingsStatus.loading,
    this.bookings = const [],
    this.busyId,
    this.error,
    this.message,
    this.messageIsError = false,
    this.messageSeq = 0,
  });

  final MyBookingsStatus status;
  final List<Booking> bookings;
  final int? busyId;
  final String? error;
  final String? message;
  final bool messageIsError;
  final int messageSeq; // naik setiap ada pesan baru, dipakai UI untuk SnackBar

  MyBookingsState copyWith({
    MyBookingsStatus? status,
    List<Booking>? bookings,
    int? busyId,
    bool clearBusy = false,
    String? error,
    String? message,
    bool? messageIsError,
  }) {
    return MyBookingsState(
      status: status ?? this.status,
      bookings: bookings ?? this.bookings,
      busyId: clearBusy ? null : (busyId ?? this.busyId),
      error: error ?? this.error,
      message: message ?? this.message,
      messageIsError: messageIsError ?? this.messageIsError,
      messageSeq: message != null ? messageSeq + 1 : messageSeq,
    );
  }
}

class MyBookingsBloc extends Bloc<MyBookingsEvent, MyBookingsState> {
  MyBookingsBloc(this._repo) : super(const MyBookingsState()) {
    on<MyBookingsStarted>((e, emit) => _fetch(emit, spinner: true));
    on<MyBookingsRefreshed>((e, emit) => _fetch(emit, spinner: false));
    on<MyBookingCancelRequested>(_onCancel);
  }

  final CustomerRepository _repo;

  Future<void> _fetch(Emitter<MyBookingsState> emit, {required bool spinner}) async {
    if (spinner) emit(state.copyWith(status: MyBookingsStatus.loading, bookings: const []));
    try {
      final list = await _repo.myBookings();
      emit(state.copyWith(status: MyBookingsStatus.ready, bookings: list));
    } on ApiException catch (e) {
      _fail(emit, e.message);
    } catch (_) {
      _fail(emit, 'Data booking tidak bisa dibaca.');
    }
  }

  void _fail(Emitter<MyBookingsState> emit, String message) {
    if (state.bookings.isEmpty) {
      emit(state.copyWith(status: MyBookingsStatus.failure, error: message));
    } else {
      emit(state.copyWith(message: message, messageIsError: true));
    }
  }

  Future<void> _onCancel(MyBookingCancelRequested e, Emitter<MyBookingsState> emit) async {
    emit(state.copyWith(busyId: e.booking.id));
    try {
      await _repo.cancel(e.booking.id);
      final list = await _repo.myBookings();
      emit(state.copyWith(
        status: MyBookingsStatus.ready,
        bookings: list,
        clearBusy: true,
        message: 'Booking dibatalkan.',
        messageIsError: false,
      ));
    } on ApiException catch (ex) {
      // 422 (lewat batas waktu) dan 403 tampil apa adanya.
      emit(state.copyWith(clearBusy: true, message: ex.message, messageIsError: true));
    } catch (_) {
      emit(state.copyWith(clearBusy: true, message: 'Respons server tidak dikenali.', messageIsError: true));
    }
  }
}
