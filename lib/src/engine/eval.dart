import '../core/color.dart';
import '../core/piece.dart';
import '../core/position.dart';
import '../core/square.dart';

/// Chess position evaluator.
///
/// Returns score in centipawns from White's perspective.
/// Positive = White advantage, Negative = Black advantage.
class Evaluator {
  Evaluator._();

  /// Evaluate a position.
  ///
  /// Returns score in centipawns from White's perspective.
  static int evaluate(Position position) {
    // Terminal conditions
    if (position.isCheckmate) {
      return position.turn == Color.white ? -mateScore : mateScore;
    }
    if (position.isStalemate) {
      return 0; // Draw
    }

    int score = 0;

    // Material + piece-square tables
    for (final sq in position.board.occupiedSquares) {
      final piece = position.board[sq]!;
      final value = _pieceValue(piece, sq);
      score += piece.color == Color.white ? value : -value;
    }

    return score;
  }

  /// Mate score (high but not max int to allow mate distance tracking)
  static const mateScore = 100000;

  /// Get piece value including positional bonus.
  static int _pieceValue(Piece piece, Square sq) {
    final baseValue = piece.type.value;
    final psqBonus = _getPsqBonus(piece, sq);
    return baseValue + psqBonus;
  }

  /// Get piece-square table bonus.
  static int _getPsqBonus(Piece piece, Square sq) {
    // Mirror square for black (so tables are from white's perspective)
    final index = piece.color == Color.white
        ? sq.index
        : (7 - sq.rank) * 8 + sq.file;

    return switch (piece.type) {
      Pawn() => _pawnPsq[index],
      Knight() => _knightPsq[index],
      Bishop() => _bishopPsq[index],
      Rook() => _rookPsq[index],
      Queen() => _queenPsq[index],
      King() => _kingMiddlegamePsq[index],
    };
  }

  // === Piece-Square Tables ===
  // Values in centipawns, from White's perspective (a1 = index 0)

  static const _pawnPsq = [
    //  a    b    c    d    e    f    g    h
     0,   0,   0,   0,   0,   0,   0,   0,  // rank 1 (never occupied)
     5,  10,  10, -20, -20,  10,  10,   5,  // rank 2
     5,  -5, -10,   0,   0, -10,  -5,   5,  // rank 3
     0,   0,   0,  20,  20,   0,   0,   0,  // rank 4
     5,   5,  10,  25,  25,  10,   5,   5,  // rank 5
    10,  10,  20,  30,  30,  20,  10,  10,  // rank 6
    50,  50,  50,  50,  50,  50,  50,  50,  // rank 7
     0,   0,   0,   0,   0,   0,   0,   0,  // rank 8 (promoted)
  ];

  static const _knightPsq = [
    -50, -40, -30, -30, -30, -30, -40, -50,
    -40, -20,   0,   5,   5,   0, -20, -40,
    -30,   5,  10,  15,  15,  10,   5, -30,
    -30,   0,  15,  20,  20,  15,   0, -30,
    -30,   5,  15,  20,  20,  15,   5, -30,
    -30,   0,  10,  15,  15,  10,   0, -30,
    -40, -20,   0,   0,   0,   0, -20, -40,
    -50, -40, -30, -30, -30, -30, -40, -50,
  ];

  static const _bishopPsq = [
    -20, -10, -10, -10, -10, -10, -10, -20,
    -10,   5,   0,   0,   0,   0,   5, -10,
    -10,  10,  10,  10,  10,  10,  10, -10,
    -10,   0,  10,  10,  10,  10,   0, -10,
    -10,   5,   5,  10,  10,   5,   5, -10,
    -10,   0,   5,  10,  10,   5,   0, -10,
    -10,   0,   0,   0,   0,   0,   0, -10,
    -20, -10, -10, -10, -10, -10, -10, -20,
  ];

  static const _rookPsq = [
      0,   0,   0,   5,   5,   0,   0,   0,
     -5,   0,   0,   0,   0,   0,   0,  -5,
     -5,   0,   0,   0,   0,   0,   0,  -5,
     -5,   0,   0,   0,   0,   0,   0,  -5,
     -5,   0,   0,   0,   0,   0,   0,  -5,
     -5,   0,   0,   0,   0,   0,   0,  -5,
      5,  10,  10,  10,  10,  10,  10,   5,
      0,   0,   0,   0,   0,   0,   0,   0,
  ];

  static const _queenPsq = [
    -20, -10, -10,  -5,  -5, -10, -10, -20,
    -10,   0,   5,   0,   0,   0,   0, -10,
    -10,   5,   5,   5,   5,   5,   0, -10,
      0,   0,   5,   5,   5,   5,   0,  -5,
     -5,   0,   5,   5,   5,   5,   0,  -5,
    -10,   0,   5,   5,   5,   5,   0, -10,
    -10,   0,   0,   0,   0,   0,   0, -10,
    -20, -10, -10,  -5,  -5, -10, -10, -20,
  ];

  static const _kingMiddlegamePsq = [
     20,  30,  10,   0,   0,  10,  30,  20,
     20,  20,   0,   0,   0,   0,  20,  20,
    -10, -20, -20, -20, -20, -20, -20, -10,
    -20, -30, -30, -40, -40, -30, -30, -20,
    -30, -40, -40, -50, -50, -40, -40, -30,
    -30, -40, -40, -50, -50, -40, -40, -30,
    -30, -40, -40, -50, -50, -40, -40, -30,
    -30, -40, -40, -50, -50, -40, -40, -30,
  ];
}
