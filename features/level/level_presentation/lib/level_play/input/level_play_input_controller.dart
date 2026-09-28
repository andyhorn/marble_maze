import 'dart:async';

import 'package:material_ui/material_ui.dart' show ChangeNotifier;
import 'package:tilt_domain/tilt_domain.dart';

/// Combines the accelerometer and touch into a single [tilt] for level
/// play, choosing between them and owning the one-time "drag to tilt" hint.
///
/// [initialize] probes the accelerometer: if [ITiltRepository.isAvailable]
/// is false, or no reading arrives within [firstEventTimeout], input falls
/// back to touch only and [showHint] turns on until [hintDuration] passes or
/// the player starts a drag. While a finger is down, touch always overrides
/// the accelerometer. [calibrate] should be called once per level-play
/// visit, on the tap to start.
class LevelPlayInputController extends ChangeNotifier {
  /// Creates an input controller reading from [repository].
  new({
    required ITiltRepository repository,
    TiltFilter? tiltFilter,
    TouchTiltMapper? touchTiltMapper,
    this.firstEventTimeout = const Duration(milliseconds: 500),
    this.hintDuration = const Duration(seconds: 4),
  }) : // External name repository is clearer at call sites than the
       // private field it initializes.
       // ignore: prefer_initializing_formals
       _repository = repository,
       _tiltFilter = tiltFilter ?? TiltFilter(),
       _touchTiltMapper = touchTiltMapper ?? TouchTiltMapper();

  /// How long [initialize] waits for a first accelerometer reading before
  /// falling back to touch.
  final Duration firstEventTimeout;

  /// How long the "drag to tilt" hint stays up before it dismisses itself.
  final Duration hintDuration;

  final ITiltRepository _repository;
  final TiltFilter _tiltFilter;
  final TouchTiltMapper _touchTiltMapper;

  StreamSubscription<RawGravity>? _gravitySubscription;
  Timer? _hintTimer;
  RawGravity? _latestGravity;
  bool _useAccelerometer = false;
  bool _showHint = false;
  Tilt _lastTilt = Tilt.flat;

  /// Whether the accelerometer is the active input source (subject to the
  /// touch override below).
  bool get useAccelerometer => _useAccelerometer;

  /// Whether the one-time "drag to tilt" hint should be shown.
  bool get showHint => _showHint;

  /// The board's current tilt: touch while a finger is down, otherwise the
  /// accelerometer if available, otherwise touch (including its
  /// release-ease).
  ///
  /// Reading this advances the accelerometer's smoothing, so it is meant to
  /// be read once per frame by the board; anything else that only wants to
  /// display the tilt should read [lastTilt].
  Tilt get tilt {
    final Tilt current;
    if (_touchTiltMapper.isDragging) {
      current = _touchTiltMapper.tilt;
    } else if (_useAccelerometer) {
      final gravity = _latestGravity;
      current = gravity == null ? Tilt.flat : _tiltFilter.filter(gravity);
    } else {
      current = _touchTiltMapper.tilt;
    }
    return _lastTilt = current;
  }

  /// The tilt most recently returned by [tilt], without advancing any
  /// smoothing. [Tilt.flat] until the board first reads [tilt].
  Tilt get lastTilt => _lastTilt;

  /// Probes the accelerometer and settles [useAccelerometer] and
  /// [showHint]. Call once per level-play visit, before [tilt] is read.
  Future<void> initialize() async {
    final available = await _repository.isAvailable();
    if (!available) {
      _fallBackToTouch();
      return;
    }

    final gotFirstEvent = await _waitForFirstEvent();
    if (gotFirstEvent) {
      _useAccelerometer = true;
      notifyListeners();
    } else {
      _fallBackToTouch();
    }
  }

  Future<bool> _waitForFirstEvent() {
    final completer = Completer<bool>();
    final timer = Timer(firstEventTimeout, () {
      if (!completer.isCompleted) completer.complete(false);
    });

    _gravitySubscription = _repository.watchGravity().listen(
      (gravity) {
        _latestGravity = gravity;
        if (!completer.isCompleted) completer.complete(true);
      },
      onError: (Object _) {
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    return completer.future.whenComplete(timer.cancel);
  }

  void _fallBackToTouch() {
    unawaited(_gravitySubscription?.cancel());
    _gravitySubscription = null;
    _useAccelerometer = false;
    _showHint = true;
    _hintTimer = Timer(hintDuration, _dismissHint);
    notifyListeners();
  }

  void _dismissHint() {
    if (!_showHint) return;
    _hintTimer?.cancel();
    _showHint = false;
    notifyListeners();
  }

  /// Sets the accelerometer's neutral orientation.
  ///
  /// With [toHeldAngle] (the default), the latest gravity reading becomes
  /// neutral, so however the device is held counts as flat; a no-op if no
  /// reading has arrived yet. Without it, a device lying flat is neutral
  /// and tilt is measured as it physically is.
  void calibrate({bool toHeldAngle = true}) {
    if (!toHeldAngle) {
      _tiltFilter.calibrate(RawGravity.flat);
      return;
    }
    final gravity = _latestGravity;
    if (gravity != null) _tiltFilter.calibrate(gravity);
  }

  /// Advances the touch release-ease by [elapsed]. Call once per frame.
  void update(Duration elapsed) => _touchTiltMapper.update(elapsed);

  /// Starts a touch drag at [dx], [dy] in logical pixels, dismissing the
  /// hint if it is showing.
  void dragStart(double dx, double dy) {
    _touchTiltMapper.dragStart(dx, dy);
    _dismissHint();
  }

  /// Updates the touch drag to [dx], [dy] in logical pixels.
  void dragUpdate(double dx, double dy) => _touchTiltMapper.dragUpdate(dx, dy);

  /// Ends the touch drag, whether by release or cancellation.
  void dragEnd() => _touchTiltMapper.dragEnd();

  @override
  void dispose() {
    _hintTimer?.cancel();
    unawaited(_gravitySubscription?.cancel());
    super.dispose();
  }
}
