import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../data/cashier_repository.dart';
import '../models/models.dart';

enum QueueStatus { loading, ready, failure }

enum QueueAction { start, complete, noShow }

sealed class QueueEvent {}

class QueueStarted extends QueueEvent {}

class QueueRefreshed extends QueueEvent {}

class QueueDateChanged extends QueueEvent {
  QueueDateChanged(this.date);
  final DateTime date;
}

class QueueActionRequested extends QueueEvent {
  QueueActionRequested(this.booking, this.action);
  final Booking booking;
  final QueueAction action;
}

class QueueQrisHandled extends QueueEvent {}

class QueueState {
  const QueueState({
    required this.status,
    required this.date,
    this.bookings = const [],
    this.busyId,
    this.error,
    this.message,
    this.messageIsError = false,
    this.messageSeq = 0,
    this.qrisTransactionId,
  });

  final QueueStatus status;
  final DateTime date;
  final List<Booking> bookings;
  final int? busyId;
  final String? error;
  final String? message;
  final bool messageIsError;
  final int messageSeq; // naik setiap ada pesan baru, dipakai UI untuk menampilkan SnackBar
  final int? qrisTransactionId; // diisi setelah "selesai" agar UI membuka layar QRIS

  QueueState copyWith({
    QueueStatus? status,
    DateTime? date,
    List<Booking>? bookings,
    int? busyId,
    bool clearBusy = false,
    String? error,
    String? message,
    bool? messageIsError,
    int? qrisTransactionId,
    bool clearQris = false,
  }) {
    return QueueState(
      status: status ?? this.status,
      date: date ?? this.date,
      bookings: bookings ?? this.bookings,
      busyId: clearBusy ? null : (busyId ?? this.busyId),
      error: error ?? this.error,
      message: message ?? this.message,
      messageIsError: messageIsError ?? this.messageIsError,
      messageSeq: message != null ? messageSeq + 1 : messageSeq,
      qrisTransactionId: clearQris ? null : (qrisTransactionId ?? this.qrisTransactionId),
    );
  }
}

class QueueBloc extends Bloc<QueueEvent, QueueState> {
  QueueBloc(this._repo) : super(QueueState(status: QueueStatus.loading, date: wibToday())) {
    on<QueueStarted>((e, emit) => _fetch(emit, spinner: true));
    on<QueueRefreshed>((e, emit) => _fetch(emit, spinner: false));
    on<QueueDateChanged>((e, emit) {
      emit(state.copyWith(date: e.date));
      return _fetch(emit, spinner: true);
    });
    on<QueueActionRequested>(_onAction);
    on<QueueQrisHandled>((e, emit) => emit(state.copyWith(clearQris: true)));
  }

  final CashierRepository _repo;

  Future<void> _fetch(Emitter<QueueState> emit, {required bool spinner}) async {
    if (spinner) emit(state.copyWith(status: QueueStatus.loading, bookings: const []));
    try {
      final list = await _repo.queue(state.date);
      emit(state.copyWith(status: QueueStatus.ready, bookings: list));
    } on ApiException catch (e) {
      _fail(emit, e.message);
    } catch (_) {
      _fail(emit, 'Data antrean tidak bisa dibaca.');
    }
  }

  void _fail(Emitter<QueueState> emit, String message) {
    if (state.bookings.isEmpty) {
      emit(state.copyWith(status: QueueStatus.failure, error: message));
    } else {
      emit(state.copyWith(message: message, messageIsError: true));
    }
  }

  Future<void> _onAction(QueueActionRequested e, Emitter<QueueState> emit) async {
    final id = e.booking.id;
    emit(state.copyWith(busyId: id));
    try {
      int? qrisTx;
      String? ok;
      switch (e.action) {
        case QueueAction.start:
          await _repo.start(id);
          ok = 'Layanan dimulai.';
        case QueueAction.complete:
          qrisTx = (await _repo.complete(id)).id;
        case QueueAction.noShow:
          await _repo.noShow(id);
          ok = 'Ditandai tidak datang. Slot dibuka lagi.';
      }
      final list = await _repo.queue(state.date);
      emit(state.copyWith(
        status: QueueStatus.ready,
        bookings: list,
        clearBusy: true,
        qrisTransactionId: qrisTx,
        message: ok,
        messageIsError: false,
      ));
    } on ApiException catch (ex) {
      emit(state.copyWith(clearBusy: true, message: ex.message, messageIsError: true));
    } catch (_) {
      emit(state.copyWith(clearBusy: true, message: 'Respons server tidak dikenali.', messageIsError: true));
    }
  }
}
