/// A square on the chessboard (0-63).
///
/// Extension type providing zero-cost abstraction over [int].
/// Squares are indexed row-major: a1=0, b1=1, ..., h8=63.
extension type const Square(int index) implements int {
  // === Compile-time constants for all 64 squares ===

  static const a1 = Square(0);
  static const b1 = Square(1);
  static const c1 = Square(2);
  static const d1 = Square(3);
  static const e1 = Square(4);
  static const f1 = Square(5);
  static const g1 = Square(6);
  static const h1 = Square(7);

  static const a2 = Square(8);
  static const b2 = Square(9);
  static const c2 = Square(10);
  static const d2 = Square(11);
  static const e2 = Square(12);
  static const f2 = Square(13);
  static const g2 = Square(14);
  static const h2 = Square(15);

  static const a3 = Square(16);
  static const b3 = Square(17);
  static const c3 = Square(18);
  static const d3 = Square(19);
  static const e3 = Square(20);
  static const f3 = Square(21);
  static const g3 = Square(22);
  static const h3 = Square(23);

  static const a4 = Square(24);
  static const b4 = Square(25);
  static const c4 = Square(26);
  static const d4 = Square(27);
  static const e4 = Square(28);
  static const f4 = Square(29);
  static const g4 = Square(30);
  static const h4 = Square(31);

  static const a5 = Square(32);
  static const b5 = Square(33);
  static const c5 = Square(34);
  static const d5 = Square(35);
  static const e5 = Square(36);
  static const f5 = Square(37);
  static const g5 = Square(38);
  static const h5 = Square(39);

  static const a6 = Square(40);
  static const b6 = Square(41);
  static const c6 = Square(42);
  static const d6 = Square(43);
  static const e6 = Square(44);
  static const f6 = Square(45);
  static const g6 = Square(46);
  static const h6 = Square(47);

  static const a7 = Square(48);
  static const b7 = Square(49);
  static const c7 = Square(50);
  static const d7 = Square(51);
  static const e7 = Square(52);
  static const f7 = Square(53);
  static const g7 = Square(54);
  static const h7 = Square(55);

  static const a8 = Square(56);
  static const b8 = Square(57);
  static const c8 = Square(58);
  static const d8 = Square(59);
  static const e8 = Square(60);
  static const f8 = Square(61);
  static const g8 = Square(62);
  static const h8 = Square(63);

  /// All 64 squares in order (a1, b1, ..., h8).
  static const all = [
    a1, b1, c1, d1, e1, f1, g1, h1,
    a2, b2, c2, d2, e2, f2, g2, h2,
    a3, b3, c3, d3, e3, f3, g3, h3,
    a4, b4, c4, d4, e4, f4, g4, h4,
    a5, b5, c5, d5, e5, f5, g5, h5,
    a6, b6, c6, d6, e6, f6, g6, h6,
    a7, b7, c7, d7, e7, f7, g7, h7,
    a8, b8, c8, d8, e8, f8, g8, h8,
  ];

  // === Derived properties ===

  /// Rank (0-7), where 0 is rank 1 and 7 is rank 8.
  int get rank => index ~/ 8;

  /// File (0-7), where 0 is file a and 7 is file h.
  int get file => index % 8;

  /// Algebraic notation (e.g., "e4", "a1", "h8").
  String get algebraic => '${String.fromCharCode(97 + file)}${rank + 1}';

  /// Whether this is a light square (a1 is dark).
  bool get isLight => (rank + file) % 2 == 1;

  /// Whether this is a dark square.
  bool get isDark => !isLight;

  // === Movement ===

  /// Shift by rank and file deltas, returning null if out of bounds.
  ///
  /// [dr] is the rank delta (positive = towards rank 8).
  /// [df] is the file delta (positive = towards file h).
  Square? shift(int dr, int df) {
    final newRank = rank + dr;
    final newFile = file + df;
    if (newRank < 0 || newRank > 7 || newFile < 0 || newFile > 7) {
      return null;
    }
    return Square(newRank * 8 + newFile);
  }

  // === Parsing ===

  /// Parse algebraic notation (e.g., "e4") to Square.
  ///
  /// Returns null if the notation is invalid.
  static Square? parse(String notation) {
    if (notation.length != 2) return null;

    final fileChar = notation.codeUnitAt(0);
    final rankChar = notation.codeUnitAt(1);

    // 'a' = 97, 'h' = 104
    if (fileChar < 97 || fileChar > 104) return null;
    // '1' = 49, '8' = 56
    if (rankChar < 49 || rankChar > 56) return null;

    final file = fileChar - 97;
    final rank = rankChar - 49;

    return Square(rank * 8 + file);
  }

  /// Create square from rank and file (0-7 each).
  ///
  /// Returns null if out of bounds.
  static Square? fromRankFile(int rank, int file) {
    if (rank < 0 || rank > 7 || file < 0 || file > 7) return null;
    return Square(rank * 8 + file);
  }

}
