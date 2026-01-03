import '../core/position.dart';

/// Perft (Performance Test) for move generation validation.
///
/// Counts the number of leaf nodes at a given depth to verify
/// move generation correctness against known values.
class Perft {
  Perft._();

  /// Count nodes at depth from position.
  ///
  /// Returns the total number of positions reachable at exactly [depth] plies.
  static int perft(Position position, int depth) {
    if (depth == 0) return 1;

    final moves = position.legalMoves;
    if (depth == 1) return moves.length;

    int nodes = 0;
    for (final move in moves) {
      final newPos = position.makeMove(move);
      if (newPos != null) {
        nodes += perft(newPos, depth - 1);
      }
    }
    return nodes;
  }

  /// Divide: perft with per-move breakdown.
  ///
  /// Returns a map from UCI move string to node count.
  static Map<String, int> divide(Position position, int depth) {
    final result = <String, int>{};
    final moves = position.legalMoves;

    for (final move in moves) {
      final newPos = position.makeMove(move);
      if (newPos != null) {
        final nodes = depth > 1 ? perft(newPos, depth - 1) : 1;
        result[move.toUci()] = nodes;
      }
    }

    return result;
  }
}

/// Known perft results for validation.
class PerftResults {
  PerftResults._();

  /// Initial position perft results.
  static const initial = [
    1,         // depth 0
    20,        // depth 1
    400,       // depth 2
    8902,      // depth 3
    197281,    // depth 4
    4865609,   // depth 5
    119060324, // depth 6
  ];

  /// Position 2: Kiwipete (complex tactical position)
  /// FEN: r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -
  static const kiwipete = [
    1,          // depth 0
    48,         // depth 1
    2039,       // depth 2
    97862,      // depth 3
    4085603,    // depth 4
    193690690,  // depth 5
  ];

  /// Position 3: Focus on en passant and promotion
  /// FEN: 8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - -
  static const position3 = [
    1,         // depth 0
    14,        // depth 1
    191,       // depth 2
    2812,      // depth 3
    43238,     // depth 4
    674624,    // depth 5
  ];

  /// Position 4: Focus on castling and checks
  /// FEN: r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq -
  static const position4 = [
    1,         // depth 0
    6,         // depth 1
    264,       // depth 2
    9467,      // depth 3
    422333,    // depth 4
    15833292,  // depth 5
  ];

  /// Position 5: Mirrored position 4
  /// FEN: r2q1rk1/pP1p2pp/Q4n2/bbp1p3/Np6/1B3NBn/pPPP1PPP/R3K2R b KQ -
  static const position5 = [
    1,         // depth 0
    6,         // depth 1
    264,       // depth 2
    9467,      // depth 3
    422333,    // depth 4
    15833292,  // depth 5
  ];
}
