/// Chess piece color.
///
/// Sealed class enabling exhaustive pattern matching.
sealed class Color {
  const Color._();

  /// White pieces.
  static const white = White._();

  /// Black pieces.
  static const black = Black._();

  /// The opposite color.
  Color get opposite;

  /// Direction of pawn movement (+1 for white, -1 for black).
  int get direction;

  /// Back rank (0 for white, 7 for black).
  int get backRank;

  /// Pawn starting rank (1 for white, 6 for black).
  int get pawnRank;

  /// Promotion rank (7 for white, 0 for black).
  int get promotionRank;

  /// Index for array access (0 for white, 1 for black).
  int get index;

  /// FEN character ('w' or 'b').
  String get fenChar;
}

/// White pieces.
final class White extends Color {
  const White._() : super._();

  @override
  Color get opposite => Color.black;

  @override
  int get direction => 1;

  @override
  int get backRank => 0;

  @override
  int get pawnRank => 1;

  @override
  int get promotionRank => 7;

  @override
  int get index => 0;

  @override
  String get fenChar => 'w';

  @override
  String toString() => 'white';
}

/// Black pieces.
final class Black extends Color {
  const Black._() : super._();

  @override
  Color get opposite => Color.white;

  @override
  int get direction => -1;

  @override
  int get backRank => 7;

  @override
  int get pawnRank => 6;

  @override
  int get promotionRank => 0;

  @override
  int get index => 1;

  @override
  String get fenChar => 'b';

  @override
  String toString() => 'black';
}
