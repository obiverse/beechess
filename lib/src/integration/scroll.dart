import 'package:meta/meta.dart';

import '../core/color.dart';
import '../core/game.dart';
import '../core/move.dart';
import '../core/position.dart';
import '../core/zobrist.dart';

/// A Scroll represents a piece of data in the 9S protocol.
///
/// This is a minimal implementation for beechess integration.
/// The full Scroll type lives in the nine_s package.
@immutable
class Scroll {
  const Scroll({
    required this.key,
    required this.data,
    this.type,
  });

  /// Path key (e.g., '/arena/games/{id}/position')
  final String key;

  /// Scroll data payload
  final Map<String, dynamic> data;

  /// Type identifier (e.g., 'chess/position@v1')
  final String? type;

  @override
  String toString() => 'Scroll($key, type: $type)';
}

/// Extension to convert Position to/from Scroll format.
extension PositionScroll on Position {
  /// Convert position to Scroll for 9S storage/transport.
  Scroll toScroll(String gameId) => Scroll(
        key: '/arena/games/$gameId/position',
        data: {
          'fen': toFen(),
          'hash': Zobrist.hashPosition(this),
          'turn': turn == Color.white ? 'w' : 'b',
          'moveNumber': fullmoveNumber,
          'halfmoveClock': halfmoveClock,
          'isCheck': isCheck,
          'isCheckmate': isCheckmate,
          'isStalemate': isStalemate,
        },
        type: 'chess/position@v1',
      );

  /// Reconstruct position from Scroll.
  static Position? fromScroll(Scroll scroll) {
    final fen = scroll.data['fen'] as String?;
    if (fen == null) return null;
    return Position.fromFen(fen);
  }
}

/// Extension to convert Move to/from Scroll data format.
extension MoveScroll on Move {
  /// Convert move to Scroll data map.
  Map<String, dynamic> toScrollData() => {
        'uci': toUci(),
        'from': from.algebraic,
        'to': to.algebraic,
        if (promotion != null) 'promotion': promotion!.letter,
      };

  /// Parse move from Scroll data.
  static Move? fromScrollData(Map<String, dynamic> data) {
    final uci = data['uci'] as String?;
    if (uci == null) return null;
    return Move.parse(uci);
  }
}

/// Extension to convert Game to/from Scroll format.
extension GameScroll on Game {
  /// Convert game to Scroll for 9S storage.
  Scroll toScroll(String gameId) => Scroll(
        key: '/arena/games/$gameId',
        data: {
          'fen': position.toFen(),
          'moves': moves.map((m) => m.toUci()).toList(),
          'result': result.name,
          'plyCount': plyCount,
          'moveNumber': moveNumber,
        },
        type: 'chess/game@v1',
      );

  /// Convert game moves to Scroll.
  Scroll movesToScroll(String gameId) => Scroll(
        key: '/arena/games/$gameId/moves',
        data: {
          'moves': moves.map((m) => m.toScrollData()).toList(),
          'count': moves.length,
        },
        type: 'chess/moves@v1',
      );

  /// Convert game result to Scroll.
  Scroll resultToScroll(String gameId) => Scroll(
        key: '/arena/games/$gameId/result',
        data: {
          'result': result.name,
          'isGameOver': isGameOver,
          if (isGameOver) 'winner': _winner,
        },
        type: 'chess/result@v1',
      );

  String? get _winner => switch (result) {
        GameResult.whiteWins => 'white',
        GameResult.blackWins => 'black',
        _ => null,
      };
}
