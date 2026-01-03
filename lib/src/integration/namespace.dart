import '../core/game.dart';
import '../format/pgn.dart';
import 'scroll.dart';

/// Result type for namespace operations.
sealed class NineResult<T> {
  const NineResult();
}

/// Successful result.
class Ok<T> extends NineResult<T> {
  const Ok(this.value);
  final T value;
}

/// Error result.
class Err<T> extends NineResult<T> {
  const Err(this.error);
  final NineError error;
}

/// Error types for namespace operations.
sealed class NineError {
  const NineError(this.message);
  final String message;
}

class NotFoundError extends NineError {
  const NotFoundError(String path) : super('Not found: $path');
}

class InvalidDataError extends NineError {
  const InvalidDataError(String details) : super('Invalid data: $details');
}

class PermissionError extends NineError {
  const PermissionError(String path) : super('Permission denied: $path');
}

class IllegalMoveError extends NineError {
  const IllegalMoveError(String move) : super('Illegal move: $move');
}

/// Abstract namespace interface for 9S protocol.
abstract class Namespace {
  /// Read data at the given path.
  NineResult<Scroll?> read(String path);

  /// Write data at the given path.
  NineResult<Scroll> write(String path, Map<String, dynamic> data);

  /// List paths under the given prefix.
  NineResult<List<String>> list(String prefix);

  /// Watch for changes at the given path (returns stream key).
  NineResult<String> watch(String path);
}

/// Chess game namespace for 9S integration.
///
/// Provides read/write access to a chess game via the 9S protocol.
///
/// ## Paths
/// - `/position` - Current position (FEN, hash, turn, etc.)
/// - `/moves` - List of moves played
/// - `/result` - Game result (ongoing, white wins, etc.)
/// - `/fen` - Just the FEN string
/// - `/pgn` - Game in PGN format
/// - `/move` - Write to make a move
class ChessGameNamespace implements Namespace {
  ChessGameNamespace({
    required this.gameId,
    Game? game,
    this.whitePubkey,
    this.blackPubkey,
  }) : _game = game ?? Game.initial();

  final String gameId;
  Game _game;

  /// White player's public key (for multiplayer).
  final String? whitePubkey;

  /// Black player's public key (for multiplayer).
  final String? blackPubkey;

  /// Current game state.
  Game get game => _game;

  @override
  NineResult<Scroll?> read(String path) {
    return switch (path) {
      '/position' => Ok(_game.position.toScroll(gameId)),
      '/moves' => Ok(_game.movesToScroll(gameId)),
      '/result' => Ok(_game.resultToScroll(gameId)),
      '/fen' => Ok(Scroll(
          key: '/arena/games/$gameId/fen',
          data: {'fen': _game.position.toFen()},
          type: 'chess/fen@v1',
        )),
      '/pgn' => Ok(Scroll(
          key: '/arena/games/$gameId/pgn',
          data: {
            'pgn': Pgn.format(_game, headers: _pgnHeaders),
          },
          type: 'chess/pgn@v1',
        )),
      '/meta' => Ok(Scroll(
          key: '/arena/games/$gameId/meta',
          data: {
            if (whitePubkey != null) 'white': whitePubkey,
            if (blackPubkey != null) 'black': blackPubkey,
            'gameId': gameId,
            'plyCount': _game.plyCount,
          },
          type: 'chess/meta@v1',
        )),
      _ => const Err(NotFoundError('Unknown path')),
    };
  }

  @override
  NineResult<Scroll> write(String path, Map<String, dynamic> data) {
    if (path == '/move') {
      final move = MoveScroll.fromScrollData(data);
      if (move == null) {
        return const Err(InvalidDataError('Invalid move format'));
      }

      final newGame = _game.makeMove(move);
      if (newGame == null) {
        return Err(IllegalMoveError(move.toUci()));
      }

      _game = newGame;
      return Ok(_game.position.toScroll(gameId));
    }

    if (path == '/reset') {
      _game = Game.initial();
      return Ok(_game.position.toScroll(gameId));
    }

    if (path == '/fen') {
      final fen = data['fen'] as String?;
      if (fen == null) {
        return const Err(InvalidDataError('Missing fen field'));
      }
      final game = Game.fromFen(fen);
      if (game == null) {
        return const Err(InvalidDataError('Invalid FEN'));
      }
      _game = game;
      return Ok(_game.position.toScroll(gameId));
    }

    return Err(PermissionError(path));
  }

  @override
  NineResult<List<String>> list(String prefix) {
    if (prefix == '/' || prefix.isEmpty) {
      return const Ok([
        '/position',
        '/moves',
        '/result',
        '/fen',
        '/pgn',
        '/meta',
      ]);
    }
    return const Ok([]);
  }

  @override
  NineResult<String> watch(String path) {
    // Would return a stream key in full implementation
    return Ok('$gameId:$path');
  }

  Map<String, String> get _pgnHeaders => {
        if (whitePubkey != null) 'White': whitePubkey!,
        if (blackPubkey != null) 'Black': blackPubkey!,
        'Event': 'Beeverse Arena',
        'Site': '9S',
      };
}
