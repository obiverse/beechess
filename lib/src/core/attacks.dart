import 'board.dart';
import 'color.dart';
import 'direction.dart';
import 'piece.dart';
import 'square.dart';

/// Attack detection utilities.
///
/// Determines which squares are attacked by which pieces.
class Attacks {
  Attacks._();

  /// Check if a square is attacked by any piece of the given color.
  static bool isAttacked(Board board, Square square, Color byColor) {
    // Check pawn attacks
    if (_isPawnAttacking(board, square, byColor)) return true;

    // Check knight attacks
    if (_isKnightAttacking(board, square, byColor)) return true;

    // Check king attacks
    if (_isKingAttacking(board, square, byColor)) return true;

    // Check sliding pieces (bishop, rook, queen)
    if (_isSlidingAttacking(board, square, byColor)) return true;

    return false;
  }

  /// Check if the king of the given color is in check.
  static bool isInCheck(Board board, Color kingColor) {
    final kingSquare = board.findKing(kingColor);
    if (kingSquare == null) return false; // No king = invalid position
    return isAttacked(board, kingSquare, kingColor.opposite);
  }

  /// Get all squares attacked by a piece at a given square.
  static Iterable<Square> attacksFrom(Board board, Square from) sync* {
    final piece = board[from];
    if (piece == null) return;

    switch (piece.type) {
      case Pawn():
        yield* _pawnAttacks(from, piece.color);
      case Knight():
        yield* _knightMoves(from);
      case King():
        yield* _kingMoves(from);
      case Bishop():
        yield* _bishopAttacks(board, from);
      case Rook():
        yield* _rookAttacks(board, from);
      case Queen():
        yield* _queenAttacks(board, from);
    }
  }

  // === Private helpers ===

  static bool _isPawnAttacking(Board board, Square target, Color byColor) {
    // To find if target is attacked by a pawn of byColor,
    // we look for pawns in the squares that could attack target.
    // White pawns attack northEast/northWest, so we look southEast/southWest of target.
    // Black pawns attack southEast/southWest, so we look northEast/northWest of target.
    final directions = byColor == Color.white
        ? Direction.whitePawnCapture // Where white pawns attack
        : Direction.blackPawnCapture; // Where black pawns attack

    for (final dir in directions) {
      // Look in the opposite direction to find the attacker
      final attackerSquare = target.shift(-dir.dr, -dir.df);
      if (attackerSquare == null) continue;

      final piece = board[attackerSquare];
      if (piece != null && piece.type == PieceType.pawn && piece.color == byColor) {
        return true;
      }
    }
    return false;
  }

  static bool _isKnightAttacking(Board board, Square target, Color byColor) {
    for (final dir in Direction.knight) {
      final attackerSquare = target.shift(dir.dr, dir.df);
      if (attackerSquare == null) continue;

      final piece = board[attackerSquare];
      if (piece != null && piece.type == PieceType.knight && piece.color == byColor) {
        return true;
      }
    }
    return false;
  }

  static bool _isKingAttacking(Board board, Square target, Color byColor) {
    for (final dir in Direction.king) {
      final attackerSquare = target.shift(dir.dr, dir.df);
      if (attackerSquare == null) continue;

      final piece = board[attackerSquare];
      if (piece != null && piece.type == PieceType.king && piece.color == byColor) {
        return true;
      }
    }
    return false;
  }

  static bool _isSlidingAttacking(Board board, Square target, Color byColor) {
    // Check rook-like attacks (rook and queen)
    for (final dir in Direction.rook) {
      Square? sq = target;
      while (true) {
        sq = sq!.shift(dir.dr, dir.df);
        if (sq == null) break;

        final piece = board[sq];
        if (piece != null) {
          if (piece.color == byColor) {
            if (piece.type == PieceType.rook || piece.type == PieceType.queen) {
              return true;
            }
          }
          break; // Blocked
        }
      }
    }

    // Check bishop-like attacks (bishop and queen)
    for (final dir in Direction.bishop) {
      Square? sq = target;
      while (true) {
        sq = sq!.shift(dir.dr, dir.df);
        if (sq == null) break;

        final piece = board[sq];
        if (piece != null) {
          if (piece.color == byColor) {
            if (piece.type == PieceType.bishop || piece.type == PieceType.queen) {
              return true;
            }
          }
          break; // Blocked
        }
      }
    }

    return false;
  }

  static Iterable<Square> _pawnAttacks(Square from, Color color) sync* {
    final directions = color == Color.white
        ? Direction.whitePawnCapture
        : Direction.blackPawnCapture;

    for (final dir in directions) {
      final to = from.shift(dir.dr, dir.df);
      if (to != null) yield to;
    }
  }

  static Iterable<Square> _knightMoves(Square from) sync* {
    for (final dir in Direction.knight) {
      final to = from.shift(dir.dr, dir.df);
      if (to != null) yield to;
    }
  }

  static Iterable<Square> _kingMoves(Square from) sync* {
    for (final dir in Direction.king) {
      final to = from.shift(dir.dr, dir.df);
      if (to != null) yield to;
    }
  }

  static Iterable<Square> _bishopAttacks(Board board, Square from) sync* {
    for (final dir in Direction.bishop) {
      Square? sq = from;
      while (true) {
        sq = sq!.shift(dir.dr, dir.df);
        if (sq == null) break;
        yield sq;
        if (board[sq] != null) break; // Blocked
      }
    }
  }

  static Iterable<Square> _rookAttacks(Board board, Square from) sync* {
    for (final dir in Direction.rook) {
      Square? sq = from;
      while (true) {
        sq = sq!.shift(dir.dr, dir.df);
        if (sq == null) break;
        yield sq;
        if (board[sq] != null) break; // Blocked
      }
    }
  }

  static Iterable<Square> _queenAttacks(Board board, Square from) sync* {
    yield* _bishopAttacks(board, from);
    yield* _rookAttacks(board, from);
  }
}
