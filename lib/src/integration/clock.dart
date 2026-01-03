import 'package:meta/meta.dart';

import '../core/color.dart';

/// Time control settings for a chess game.
@immutable
class TimeControl {
  const TimeControl(this.initialSecs, this.incrementSecs);

  /// Initial time in seconds.
  final int initialSecs;

  /// Increment per move in seconds.
  final int incrementSecs;

  /// Bullet: 1 minute, no increment.
  static const bullet1_0 = TimeControl(60, 0);

  /// Bullet: 2 minutes, 1 second increment.
  static const bullet2_1 = TimeControl(120, 1);

  /// Blitz: 3 minutes, no increment.
  static const blitz3_0 = TimeControl(180, 0);

  /// Blitz: 5 minutes, no increment.
  static const blitz5_0 = TimeControl(300, 0);

  /// Blitz: 5 minutes, 3 second increment.
  static const blitz5_3 = TimeControl(300, 3);

  /// Rapid: 10 minutes, no increment.
  static const rapid10_0 = TimeControl(600, 0);

  /// Rapid: 15 minutes, 10 second increment.
  static const rapid15_10 = TimeControl(900, 10);

  /// Classical: 30 minutes, no increment.
  static const classical30_0 = TimeControl(1800, 0);

  /// Time control name (e.g., "5+3").
  String get name => '${initialSecs ~/ 60}+$incrementSecs';

  /// Category based on initial time.
  String get category {
    if (initialSecs < 180) return 'bullet';
    if (initialSecs < 600) return 'blitz';
    if (initialSecs < 1800) return 'rapid';
    return 'classical';
  }

  /// Initial time in milliseconds.
  int get initialMs => initialSecs * 1000;

  /// Increment in milliseconds.
  int get incrementMs => incrementSecs * 1000;

  @override
  String toString() => 'TimeControl($name)';

  @override
  bool operator ==(Object other) =>
      other is TimeControl &&
      other.initialSecs == initialSecs &&
      other.incrementSecs == incrementSecs;

  @override
  int get hashCode => Object.hash(initialSecs, incrementSecs);
}

/// Game clock for tracking remaining time.
class GameClock {
  GameClock(this.timeControl)
      : whiteTimeMs = timeControl.initialMs,
        blackTimeMs = timeControl.initialMs;

  /// Time control settings.
  final TimeControl timeControl;

  /// White's remaining time in milliseconds.
  int whiteTimeMs;

  /// Black's remaining time in milliseconds.
  int blackTimeMs;

  /// Which clock is currently running (null if both stopped).
  Color? _running;

  /// When the current clock started.
  DateTime? _lastTick;

  /// Whether the clock is running.
  bool get isRunning => _running != null;

  /// Which side's clock is running.
  Color? get running => _running;

  /// Get remaining time for a color.
  int timeMs(Color color) {
    var time = color == Color.white ? whiteTimeMs : blackTimeMs;

    // If this clock is running, subtract elapsed time
    if (_running == color && _lastTick != null) {
      final elapsed = DateTime.now().difference(_lastTick!).inMilliseconds;
      time -= elapsed;
    }

    return time;
  }

  /// Get remaining time in seconds.
  double timeSecs(Color color) => timeMs(color) / 1000.0;

  /// Check if a side has flagged (run out of time).
  bool isFlagged(Color color) => timeMs(color) <= 0;

  /// Start the clock for the given color.
  void start(Color color) {
    // Capture current time before switching
    _captureElapsed();

    _running = color;
    _lastTick = DateTime.now();
  }

  /// Stop both clocks.
  void stop() {
    _captureElapsed();
    _running = null;
    _lastTick = null;
  }

  /// Switch to the other player's clock and add increment.
  void switchClock() {
    if (_running == null) return;

    // Capture elapsed time
    _captureElapsed();

    // Add increment to the player who just moved
    if (_running == Color.white) {
      whiteTimeMs += timeControl.incrementMs;
      _running = Color.black;
    } else {
      blackTimeMs += timeControl.incrementMs;
      _running = Color.white;
    }

    _lastTick = DateTime.now();
  }

  /// Add increment without switching (for manual adjustments).
  void addIncrement(Color color) {
    if (color == Color.white) {
      whiteTimeMs += timeControl.incrementMs;
    } else {
      blackTimeMs += timeControl.incrementMs;
    }
  }

  /// Add arbitrary time (for adjustments).
  void addTime(Color color, int ms) {
    if (color == Color.white) {
      whiteTimeMs += ms;
    } else {
      blackTimeMs += ms;
    }
  }

  /// Capture elapsed time and update the running clock.
  void _captureElapsed() {
    if (_running != null && _lastTick != null) {
      final elapsed = DateTime.now().difference(_lastTick!).inMilliseconds;
      if (_running == Color.white) {
        whiteTimeMs -= elapsed;
      } else {
        blackTimeMs -= elapsed;
      }
    }
  }

  /// Reset clocks to initial time.
  void reset() {
    whiteTimeMs = timeControl.initialMs;
    blackTimeMs = timeControl.initialMs;
    _running = null;
    _lastTick = null;
  }

  /// Format time for display (MM:SS or M:SS.t for low time).
  String formatTime(Color color) {
    final ms = timeMs(color);
    if (ms <= 0) return '0:00';

    final totalSecs = ms ~/ 1000;
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;

    if (ms < 10000) {
      // Show tenths when under 10 seconds
      final tenths = (ms ~/ 100) % 10;
      return '$mins:${secs.toString().padLeft(2, '0')}.$tenths';
    }

    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  String toString() =>
      'GameClock(white: ${formatTime(Color.white)}, black: ${formatTime(Color.black)})';
}
