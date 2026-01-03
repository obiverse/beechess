import 'package:meta/meta.dart';

import 'color.dart';
import 'direction.dart';

/// Chess piece type.
///
/// Sealed class enabling exhaustive pattern matching.
sealed class PieceType {
  const PieceType._();

  /// King piece type.
  static const king = King._();

  /// Queen piece type.
  static const queen = Queen._();

  /// Rook piece type.
  static const rook = Rook._();

  /// Bishop piece type.
  static const bishop = Bishop._();

  /// Knight piece type.
  static const knight = Knight._();

  /// Pawn piece type.
  static const pawn = Pawn._();

  /// All piece types.
  static const all = [king, queen, rook, bishop, knight, pawn];

  /// FEN letter (uppercase: K, Q, R, B, N, P).
  String get letter;

  /// Material value in centipawns.
  int get value;

  /// Whether this piece slides (queen, rook, bishop).
  bool get isSliding;

  /// Movement directions for this piece type.
  List<Direction> get directions;

  /// Index for array access (0-5).
  int get index;

  /// Parse piece type from FEN letter.
  static PieceType? fromLetter(String letter) {
    return switch (letter.toUpperCase()) {
      'K' => king,
      'Q' => queen,
      'R' => rook,
      'B' => bishop,
      'N' => knight,
      'P' => pawn,
      _ => null,
    };
  }
}

/// King piece type.
final class King extends PieceType {
  const King._() : super._();

  @override
  String get letter => 'K';

  @override
  int get value => 20000;

  @override
  bool get isSliding => false;

  @override
  List<Direction> get directions => Direction.king;

  @override
  int get index => 0;

  @override
  String toString() => 'King';
}

/// Queen piece type.
final class Queen extends PieceType {
  const Queen._() : super._();

  @override
  String get letter => 'Q';

  @override
  int get value => 900;

  @override
  bool get isSliding => true;

  @override
  List<Direction> get directions => Direction.queen;

  @override
  int get index => 1;

  @override
  String toString() => 'Queen';
}

/// Rook piece type.
final class Rook extends PieceType {
  const Rook._() : super._();

  @override
  String get letter => 'R';

  @override
  int get value => 500;

  @override
  bool get isSliding => true;

  @override
  List<Direction> get directions => Direction.rook;

  @override
  int get index => 2;

  @override
  String toString() => 'Rook';
}

/// Bishop piece type.
final class Bishop extends PieceType {
  const Bishop._() : super._();

  @override
  String get letter => 'B';

  @override
  int get value => 330;

  @override
  bool get isSliding => true;

  @override
  List<Direction> get directions => Direction.bishop;

  @override
  int get index => 3;

  @override
  String toString() => 'Bishop';
}

/// Knight piece type.
final class Knight extends PieceType {
  const Knight._() : super._();

  @override
  String get letter => 'N';

  @override
  int get value => 320;

  @override
  bool get isSliding => false;

  @override
  List<Direction> get directions => Direction.knight;

  @override
  int get index => 4;

  @override
  String toString() => 'Knight';
}

/// Pawn piece type.
final class Pawn extends PieceType {
  const Pawn._() : super._();

  @override
  String get letter => 'P';

  @override
  int get value => 100;

  @override
  bool get isSliding => false;

  @override
  List<Direction> get directions => const [];

  @override
  int get index => 5;

  @override
  String toString() => 'Pawn';
}

/// A chess piece (type + color).
@immutable
class Piece {
  const Piece(this.type, this.color);

  /// The piece type.
  final PieceType type;

  /// The piece color.
  final Color color;

  /// Unicode symbol for this piece.
  String get symbol {
    return switch ((type, color)) {
      (King(), White()) => '♔',
      (Queen(), White()) => '♕',
      (Rook(), White()) => '♖',
      (Bishop(), White()) => '♗',
      (Knight(), White()) => '♘',
      (Pawn(), White()) => '♙',
      (King(), Black()) => '♚',
      (Queen(), Black()) => '♛',
      (Rook(), Black()) => '♜',
      (Bishop(), Black()) => '♝',
      (Knight(), Black()) => '♞',
      (Pawn(), Black()) => '♟',
    };
  }

  /// FEN character (uppercase for white, lowercase for black).
  String get fenChar {
    final letter = type.letter;
    return color == Color.white ? letter : letter.toLowerCase();
  }

  /// Parse piece from FEN character.
  static Piece? fromFenChar(String char) {
    if (char.isEmpty) return null;

    final isWhite = char == char.toUpperCase();
    final pieceType = PieceType.fromLetter(char);

    if (pieceType == null) return null;

    return Piece(pieceType, isWhite ? Color.white : Color.black);
  }

  @override
  bool operator ==(Object other) =>
      other is Piece && other.type == type && other.color == color;

  @override
  int get hashCode => Object.hash(type, color);

  @override
  String toString() => '${color.fenChar.toUpperCase()}${type.letter}';
}

// === Piece constants for convenience ===

/// White king.
const whiteKing = Piece(PieceType.king, Color.white);

/// White queen.
const whiteQueen = Piece(PieceType.queen, Color.white);

/// White rook.
const whiteRook = Piece(PieceType.rook, Color.white);

/// White bishop.
const whiteBishop = Piece(PieceType.bishop, Color.white);

/// White knight.
const whiteKnight = Piece(PieceType.knight, Color.white);

/// White pawn.
const whitePawn = Piece(PieceType.pawn, Color.white);

/// Black king.
const blackKing = Piece(PieceType.king, Color.black);

/// Black queen.
const blackQueen = Piece(PieceType.queen, Color.black);

/// Black rook.
const blackRook = Piece(PieceType.rook, Color.black);

/// Black bishop.
const blackBishop = Piece(PieceType.bishop, Color.black);

/// Black knight.
const blackKnight = Piece(PieceType.knight, Color.black);

/// Black pawn.
const blackPawn = Piece(PieceType.pawn, Color.black);
