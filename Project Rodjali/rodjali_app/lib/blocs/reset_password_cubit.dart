import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/api_client.dart';
import '../data/auth_repository.dart';

enum ResetStep { email, code, done }

class ResetState {
  const ResetState({
    this.step = ResetStep.email,
    this.busy = false,
    this.email = '',
    this.error,
    this.notice,
  });

  final ResetStep step;
  final bool busy;
  final String email;
  final String? error;
  final String? notice;

  ResetState copyWith({
    ResetStep? step,
    bool? busy,
    String? email,
    String? error,
    bool clearError = false,
    String? notice,
    bool clearNotice = false,
  }) =>
      ResetState(
        step: step ?? this.step,
        busy: busy ?? this.busy,
        email: email ?? this.email,
        error: clearError ? null : (error ?? this.error),
        notice: clearNotice ? null : (notice ?? this.notice),
      );
}

class ResetPasswordCubit extends Cubit<ResetState> {
  ResetPasswordCubit(this._repo) : super(const ResetState());

  final AuthRepository _repo;

  /// Langkah 1 (dan "kirim ulang"): minta kode ke email.
  Future<void> sendCode(String email) async {
    emit(state.copyWith(busy: true, email: email, clearError: true));
    try {
      final msg = await _repo.forgotPassword(email);
      emit(state.copyWith(busy: false, step: ResetStep.code, notice: msg));
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, error: e.message));
    } catch (_) {
      emit(state.copyWith(busy: false, error: 'Respons server tidak dikenali.'));
    }
  }

  /// Langkah 2: kode + password baru.
  Future<void> reset({required String code, required String password}) async {
    emit(state.copyWith(busy: true, clearError: true));
    try {
      await _repo.resetPassword(email: state.email, code: code, password: password);
      emit(state.copyWith(busy: false, step: ResetStep.done));
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, error: e.message));
    } catch (_) {
      emit(state.copyWith(busy: false, error: 'Respons server tidak dikenali.'));
    }
  }

  void backToEmail() => emit(state.copyWith(step: ResetStep.email, clearError: true, clearNotice: true));
}
