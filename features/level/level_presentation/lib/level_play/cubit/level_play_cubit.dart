import 'package:bloc/bloc.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_play/cubit/level_play_state.dart';

/// Loads a level by id and exposes it as a [LevelPlayState].
class LevelPlayCubit extends Cubit<LevelPlayState> {
  /// Creates a level play cubit over [repository].
  new({required this.repository}) : super(const LevelPlayLoading());

  /// The repository this cubit loads levels through.
  final ILevelsRepository repository;

  /// Loads the level with [levelId], emitting [LevelPlayPlaying] on success
  /// or [LevelPlayError] if it fails, for example an unknown id.
  Future<void> load(String levelId) async {
    emit(const LevelPlayLoading());
    try {
      final level = await repository.getLevel(levelId);
      emit(LevelPlayPlaying(level));
    } on Exception {
      emit(const LevelPlayError());
    }
  }
}
