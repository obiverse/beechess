import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:meta/meta.dart';

import 'color.dart';
import 'move.dart';
import 'position.dart';
import 'zobrist.dart';

/// A chess game with full history tracking.
///
/// Maintains the complete move history and position hashes
/// for threefold repetition detection and move undoing.
@immutable
class Game {
  const Game._({
    required this.position,
    required this.moves,
    required this.positionHashes,
  });

  /// Create a new game from the starting position.
  factory Game.initial() {
    final position = Position.initial();
    final hash = _computeHash(position);
    return Game._(
      position: position,
      moves: const IListConst([]),
      positionHashes: IList([hash]),
    );
  }

  /// Current position.
  final Position position;

  /// List of moves played (in order).
  final IList<Move> moves;

  /// List of position hashes for repetition detection.
  final IList<int> positionHashes;

  /// Create a game from a FEN string.
  static Game? fromFen(String fen) {
    final position = Position.fromFen(fen);
    if (position == null) return null;
    final hash = _computeHash(position);
    return Game._(
      position: position,
      moves: const IListConst([]),
      positionHashes: IList([hash]),
    );
  }

  /// Number of half-moves (plies) played.
  int get plyCount => moves.length;

  /// Current move number (1-indexed, increments after Black's move).
  int get moveNumber => position.fullmoveNumber;

  /// Make a move and return the new game state.
  ///
  /// Returns null if the move is illegal.
  Game? makeMove(Move move) {
    final newPosition = position.makeMove(move);
    if (newPosition == null) return null;

    final newHash = _computeHash(newPosition);
    return Game._(
      position: newPosition,
      moves: moves.add(move),
      positionHashes: positionHashes.add(newHash),
    );
  }

  /// Make a move from UCI notation.
  Game? makeMoveUci(String uci) {
    final move = Move.parse(uci);
    if (move == null) return null;
    return makeMove(move);
  }

  /// Check if current position is a threefold repetition.
  bool get isThreefoldRepetition {
    if (positionHashes.length < 5) return false; // Need at least 5 positions

    final currentHash = positionHashes.last;
    int count = 0;

    for (final hash in positionHashes) {
      if (hash == currentHash) {
        count++;
        if (count >= 3) return true;
      }
    }
    return false;
  }

  /// Check if the game is drawn by the 50-move rule.
  bool get isFiftyMoveRule => position.canClaimFiftyMoveRule;

  /// Check if the game is over (checkmate, stalemate, or draw).
  bool get isGameOver =>
      position.isGameOver || isThreefoldRepetition || isFiftyMoveRule;

  /// Get the game result.
  GameResult get result {
    if (position.isCheckmate) {
      return position.turn == Color.white
          ? GameResult.blackWins
          : GameResult.whiteWins;
    }
    if (position.isStalemate || isThreefoldRepetition || isFiftyMoveRule) {
      return GameResult.draw;
    }
    return GameResult.ongoing;
  }

  /// Get the last move played (if any).
  Move? get lastMove => moves.isEmpty ? null : moves.last;

  /// Compute Zobrist hash for a position.
  static int _computeHash(Position position) {
    int hash = 0;

    // Piece placement
    for (final sq in position.board.occupiedSquares) {
      final piece = position.board[sq]!;
      hash ^= Zobrist.pieceSquareKey(piece, sq);
    }

    // Side to move
    if (position.turn == Color.black) {
      hash ^= Zobrist.sideToMove;
    }

    // Castling rights (pack into 4 bits)
    int castlingBits = 0;
    if (position.castling.whiteKingside) castlingBits |= 1;
    if (position.castling.whiteQueenside) castlingBits |= 2;
    if (position.castling.blackKingside) castlingBits |= 4;
    if (position.castling.blackQueenside) castlingBits |= 8;
    hash ^= Zobrist.castlingKey(castlingBits);

    // En passant file
    if (position.enPassant != null) {
      hash ^= Zobrist.enPassantKey(position.enPassant!.file);
    }

    return hash;
  }

  /// Convert game to PGN movetext (just the moves, no headers).
  String toMovetext() {
    if (moves.isEmpty) return '';

    final buffer = StringBuffer();
    var pos = Position.initial();

    for (int i = 0; i < moves.length; i++) {
      final move = moves[i];

      // Add move number for white's moves
      if (i % 2 == 0) {
        if (i > 0) buffer.write(' ');
        buffer.write('${(i ~/ 2) + 1}.');
      }

      buffer.write(' ');
      buffer.write(move.toUci()); // TODO: Replace with SAN when implemented

      pos = pos.makeMove(move)!;
    }

    // Add result
    switch (result) {
      case GameResult.whiteWins:
        buffer.write(' 1-0');
      case GameResult.blackWins:
        buffer.write(' 0-1');
      case GameResult.draw:
        buffer.write(' 1/2-1/2');
      case GameResult.ongoing:
        buffer.write(' *');
    }

    return buffer.toString();
  }

  @override
  String toString() => position.toFen();
}

/// Game result.
enum GameResult {
  ongoing,
  whiteWins,
  blackWins,
  draw,
}
