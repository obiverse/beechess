import 'package:meta/meta.dart';

/// A direction vector for piece movement.
@immutable
class Direction {
  const Direction(this.dr, this.df);

  /// Rank delta (positive = towards rank 8).
  final int dr;

  /// File delta (positive = towards file h).
  final int df;

  // === Cardinal directions ===

  /// North (towards rank 8).
  static const north = Direction(1, 0);

  /// South (towards rank 1).
  static const south = Direction(-1, 0);

  /// East (towards file h).
  static const east = Direction(0, 1);

  /// West (towards file a).
  static const west = Direction(0, -1);

  // === Diagonal directions ===

  /// North-east.
  static const northEast = Direction(1, 1);

  /// North-west.
  static const northWest = Direction(1, -1);

  /// South-east.
  static const southEast = Direction(-1, 1);

  /// South-west.
  static const southWest = Direction(-1, -1);

  // === Piece movement sets ===

  /// Rook directions (cardinal).
  static const List<Direction> rook = [north, south, east, west];

  /// Bishop directions (diagonal).
  static const List<Direction> bishop = [northEast, northWest, southEast, southWest];

  /// Queen/King directions (all 8).
  static const List<Direction> queen = [
    north, south, east, west,
    northEast, northWest, southEast, southWest,
  ];

  /// King directions (same as queen, but moves 1 step).
  static const List<Direction> king = queen;

  /// Knight movement patterns (L-shapes).
  static const List<Direction> knight = [
    Direction(2, 1),
    Direction(2, -1),
    Direction(-2, 1),
    Direction(-2, -1),
    Direction(1, 2),
    Direction(1, -2),
    Direction(-1, 2),
    Direction(-1, -2),
  ];

  /// Pawn capture directions for white (north-east, north-west).
  static const List<Direction> whitePawnCapture = [northEast, northWest];

  /// Pawn capture directions for black (south-east, south-west).
  static const List<Direction> blackPawnCapture = [southEast, southWest];

  @override
  bool operator ==(Object other) =>
      other is Direction && other.dr == dr && other.df == df;

  @override
  int get hashCode => Object.hash(dr, df);

  @override
  String toString() => 'Direction($dr, $df)';
}
