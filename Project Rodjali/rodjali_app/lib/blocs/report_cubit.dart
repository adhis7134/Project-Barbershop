import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../data/owner_repository.dart';
import '../models/models.dart';

enum ReportStatus { loading, ready, failure }

class ReportState {
  const ReportState({
    this.status = ReportStatus.loading,
    required this.from,
    required this.to,
    this.report,
    this.error,
  });

  final ReportStatus status;
  final DateTime from; // jam dinding WIB, hanya tanggal
  final DateTime to;
  final IncomeReport? report;
  final String? error;

  ReportState copyWith({
    ReportStatus? status,
    DateTime? from,
    DateTime? to,
    IncomeReport? report,
    String? error,
  }) =>
      ReportState(
        status: status ?? this.status,
        from: from ?? this.from,
        to: to ?? this.to,
        report: report ?? this.report,
        error: error ?? this.error,
      );
}

class ReportCubit extends Cubit<ReportState> {
  ReportCubit(this._repo) : super(_initial());

  final OwnerRepository _repo;

  // Bawaan: tanggal 1 bulan ini sampai hari ini.
  static ReportState _initial() {
    final t = wibToday();
    return ReportState(from: DateTime.utc(t.year, t.month, 1), to: t);
  }

  Future<void> load() async {
    final from = state.from;
    final to = state.to;
    emit(state.copyWith(status: ReportStatus.loading));
    try {
      final r = await _repo.income(from, to);
      if (state.from != from || state.to != to) return; // rentang sudah diganti lagi
      emit(state.copyWith(status: ReportStatus.ready, report: r));
    } on ApiException catch (e) {
      emit(state.copyWith(status: ReportStatus.failure, error: e.message));
    } catch (_) {
      emit(state.copyWith(status: ReportStatus.failure, error: 'Data laporan tidak bisa dibaca.'));
    }
  }

  Future<void> setRange(DateTime from, DateTime to) {
    emit(state.copyWith(from: from, to: to));
    return load();
  }
}
