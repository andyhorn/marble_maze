import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:level_presentation/bubble_level/cubit/bubble_level_state.dart';
import 'package:tilt_domain/tilt_domain.dart';

/// Turns the accelerometer's gravity readings into a [BubbleLevelState]: the
/// device's tilt from flat, low-pass smoothed so the bubble does not jitter.
class BubbleLevelCubit extends Cubit<BubbleLevelState> {
  /// Creates a bubble level cubit that listens to [tiltRepository].
  new({required ITiltRepository tiltRepository})
    : super(const BubbleLevelState()) {
    _subscription = tiltRepository.watchGravity().listen(_onGravity);
  }

  /// How much of each new reading is blended in, from 0 (frozen) to 1
  /// (unsmoothed).
  static const double smoothing = 0.3;

  late final StreamSubscription<RawGravity> _subscription;

  void _onGravity(RawGravity gravity) {
    // Relative to the out-of-screen axis, so the angle is the tilt from a
    // device lying flat and does not scale with a light shake.
    final xAngle = math.atan2(gravity.x, gravity.z);
    final yAngle = math.atan2(gravity.y, gravity.z);
    final previous = state;
    emit(
      BubbleLevelState(
        xAngle: previous.hasReading
            ? previous.xAngle + (xAngle - previous.xAngle) * smoothing
            : xAngle,
        yAngle: previous.hasReading
            ? previous.yAngle + (yAngle - previous.yAngle) * smoothing
            : yAngle,
        hasReading: true,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
