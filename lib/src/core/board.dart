import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:meta/meta.dart';

import 'color.dart';
import 'piece.dart';
import 'square.dart';

/// Immutable chess board representation.
///
/// Uses an IList<Piece?> for O(1) access while maintaining immutability.
/// The board is indexed by square index (0-63), where:
/// - 0 = a1, 7 = h1, 56 = a8, 63 = h8
@immutable
class Board {
  const Board._(this._squares);

  /// The 64 squares, indexed by Square.index.
  final IList<Piece?> _squares;

  /// Empty board with no pieces.
  static final empty = Board._(IList(List.filled(64, null)));

  /// Standard starting position.
  static final initial = Board._(_initialSquares);

  /// Get piece at square.
  Piece? operator [](Square sq) => _squares[sq.index];

  /// Get piece at square (alias for []).
  Piece? pieceAt(Square sq) => _squares[sq.index];

  /// Whether a square is empty.
  bool isEmpty(Square sq) => _squares[sq.index] == null;

  /// Whether a square is occupied.
  bool isOccupied(Square sq) => _squares[sq.index] != null;

  /// Put a piece on a square, returning a new board.
  Board put(Square sq, Piece piece) {
    return Board._(_squares.replace(sq.index, piece));
  }

  /// Remove a piece from a square, returning a new board.
  Board remove(Square sq) {
    return Board._(_squares.replace(sq.index, null));
  }

  /// Set square to piece or null, returning a new board.
  Board set(Square sq, Piece? piece) {
    return Board._(_squares.replace(sq.index, piece));
  }

  /// Move a piece from one square to another, returning a new board.
  ///
  /// Does not validate the move - just moves whatever is at [from] to [to].
  Board movePiece(Square from, Square to) {
    final piece = _squares[from.index];
    return Board._(_squares.replace(from.index, null).replace(to.index, piece));
  }

  /// Find all squares containing a specific piece.
  Iterable<Square> findPiece(Piece piece) sync* {
    for (final sq in Square.all) {
      if (_squares[sq.index] == piece) yield sq;
    }
  }

  /// Find the king square for a color.
  ///
  /// Returns null if no king found (invalid position).
  Square? findKing(Color color) {
    final king = Piece(PieceType.king, color);
    for (final sq in Square.all) {
      if (_squares[sq.index] == king) return sq;
    }
    return null;
  }

  /// Get all occupied squares.
  Iterable<Square> get occupiedSquares sync* {
    for (final sq in Square.all) {
      if (_squares[sq.index] != null) yield sq;
    }
  }

  /// Get all squares occupied by a color.
  Iterable<Square> squaresForColor(Color color) sync* {
    for (final sq in Square.all) {
      final piece = _squares[sq.index];
      if (piece != null && piece.color == color) yield sq;
    }
  }

  /// Count pieces of a type and color.
  int countPieces(PieceType type, Color color) {
    final piece = Piece(type, color);
    return _squares.where((p) => p == piece).length;
  }

  /// Count all pieces for a color.
  int countAllPieces(Color color) {
    return _squares.where((p) => p != null && p.color == color).length;
  }

  /// Generate FEN piece placement string.
  String toFenPiecePlacement() {
    final buffer = StringBuffer();

    for (int rank = 7; rank >= 0; rank--) {
      int emptyCount = 0;

      for (int file = 0; file < 8; file++) {
        final sq = Square(rank * 8 + file);
        final piece = _squares[sq.index];

        if (piece == null) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            buffer.write(emptyCount);
            emptyCount = 0;
          }
          buffer.write(piece.fenChar);
        }
      }

      if (emptyCount > 0) {
        buffer.write(emptyCount);
      }

      if (rank > 0) {
        buffer.write('/');
      }
    }

    return buffer.toString();
  }

  /// Parse FEN piece placement string.
  ///
  /// Returns null if the FEN is invalid.
  static Board? fromFenPiecePlacement(String fen) {
    final ranks = fen.split('/');
    if (ranks.length != 8) return null;

    final squares = List<Piece?>.filled(64, null);

    for (int rank = 7; rank >= 0; rank--) {
      final rankStr = ranks[7 - rank];
      int file = 0;

      for (final char in rankStr.split('')) {
        if (file > 7) return null;

        final digit = int.tryParse(char);
        if (digit != null) {
          // Skip empty squares
          if (digit < 1 || digit > 8) return null;
          file += digit;
        } else {
          // Parse piece
          final piece = Piece.fromFenChar(char);
          if (piece == null) return null;

          final sq = Square(rank * 8 + file);
          squares[sq.index] = piece;
          file++;
        }
      }

      if (file != 8) return null;
    }

    return Board._(IList(squares));
  }

  @override
  bool operator ==(Object other) =>
      other is Board && other._squares == _squares;

  @override
  int get hashCode => _squares.hashCode;

  @override
  String toString() => toFenPiecePlacement();
}

/// Initial position squares.
final IList<Piece?> _initialSquares = IList([
  // Rank 1 (index 0-7)
  whiteRook, whiteKnight, whiteBishop, whiteQueen,
  whiteKing, whiteBishop, whiteKnight, whiteRook,
  // Rank 2 (index 8-15)
  whitePawn, whitePawn, whitePawn, whitePawn,
  whitePawn, whitePawn, whitePawn, whitePawn,
  // Ranks 3-6 (index 16-47)
  null, null, null, null, null, null, null, null,
  null, null, null, null, null, null, null, null,
  null, null, null, null, null, null, null, null,
  null, null, null, null, null, null, null, null,
  // Rank 7 (index 48-55)
  blackPawn, blackPawn, blackPawn, blackPawn,
  blackPawn, blackPawn, blackPawn, blackPawn,
  // Rank 8 (index 56-63)
  blackRook, blackKnight, blackBishop, blackQueen,
  blackKing, blackBishop, blackKnight, blackRook,
]);
