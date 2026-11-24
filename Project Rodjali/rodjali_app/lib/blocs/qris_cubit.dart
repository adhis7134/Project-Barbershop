import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/api_client.dart';
import '../data/cashier_repository.dart';
import '../models/models.dart';

enum QrisStatus { loading, ready, confirming, failure }

class QrisState {
  const QrisState({this.status = QrisStatus.loading, this.info, this.error});

  final QrisStatus status;
  final QrisInfo? info;
  final String? error;
}

class QrisCubit extends Cubit<QrisState> {
  QrisCubit(this._repo, this.transactionId) : super(const QrisState());

  final CashierRepository _repo;
  final int transactionId;

  Future<void> load() async {
    emit(QrisState(status: QrisStatus.loading, info: state.info));
    try {
      emit(QrisState(status: QrisStatus.ready, info: await _repo.qris(transactionId)));
    } on ApiException catch (e) {
      emit(QrisState(status: QrisStatus.failure, info: state.info, error: e.message));
    } catch (_) {
      emit(QrisState(status: QrisStatus.failure, info: state.info, error: 'Data QRIS tidak bisa dibaca.'));
    }
  }

  Future<void> confirmPaid() async {
    emit(QrisState(status: QrisStatus.confirming, info: state.info));
    try {
      await _repo.confirmPaid(transactionId);
      emit(QrisState(status: QrisStatus.ready, info: await _repo.qris(transactionId)));
    } on ApiException catch (e) {
      emit(QrisState(status: QrisStatus.ready, info: state.info, error: e.message));
    } catch (_) {
      emit(QrisState(status: QrisStatus.ready, info: state.info, error: 'Respons server tidak dikenali.'));
    }
  }
}
