import 'package:bloc/bloc.dart';
import 'package:level_domain/level_domain.dart';
import 'package:level_presentation/level_select/cubit/level_list_entry.dart';
import 'package:level_presentation/level_select/cubit/level_select_state.dart';
import 'package:progress_domain/progress_domain.dart';

/// Loads every manifest level together with the player's saved best times,
/// exposing them as a [LevelSelectState].
class LevelSelectCubit extends Cubit<LevelSelectState> {
  /// Creates a level select cubit over [levelsRepository] and
  /// [progressRepository].
  new({required this.levelsRepository, required this.progressRepository})
    : super(const LevelSelectLoading());

  /// The repository this cubit loads the level manifest through.
  final ILevelsRepository levelsRepository;

  /// The repository this cubit reads saved best times through.
  final IProgressRepository progressRepository;

  /// Loads the manifest and saved records, emitting [LevelSelectLoaded] on
  /// success or [LevelSelectError] if the manifest fails to load.
  Future<void> load() async {
    emit(const LevelSelectLoading());
    try {
      final manifest = await levelsRepository.getManifest();
      final records = await progressRepository.getRecords();
      final entries = [
        for (final entry in manifest)
          LevelListEntry(
            id: entry.id,
            title: entry.title,
            par: entry.par,
            bestTime: records[entry.id]?.bestTime,
          ),
      ];
      emit(LevelSelectLoaded(entries));
    } on Exception {
      emit(const LevelSelectError());
    }
  }
}
