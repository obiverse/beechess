import 'package:meta/meta.dart';

import 'piece.dart';
import 'square.dart';

/// A chess move.
@immutable
class Move {
  const Move(this.from, this.to, [this.promotion]);

  /// Source square.
  final Square from;

  /// Destination square.
  final Square to;

  /// Promotion piece type (null if not a promotion).
  final PieceType? promotion;

  /// Whether this is a promotion move.
  bool get isPromotion => promotion != null;

  /// Format as UCI notation (e.g., "e2e4", "a7a8q").
  String toUci() {
    final base = '${from.algebraic}${to.algebraic}';
    if (promotion case final p?) {
      return '$base${p.letter.toLowerCase()}';
    }
    return base;
  }

  /// Parse UCI notation (e.g., "e2e4", "a7a8q").
  ///
  /// Returns null if the notation is invalid.
  static Move? parse(String uci) {
    if (uci.length < 4 || uci.length > 5) return null;

    final from = Square.parse(uci.substring(0, 2));
    final to = Square.parse(uci.substring(2, 4));

    if (from == null || to == null) return null;

    PieceType? promotion;
    if (uci.length == 5) {
      promotion = PieceType.fromLetter(uci[4]);
      if (promotion == null || promotion == PieceType.king || promotion == PieceType.pawn) {
        return null;
      }
    }

    return Move(from, to, promotion);
  }

  @override
  bool operator ==(Object other) =>
      other is Move &&
      other.from == from &&
      other.to == to &&
      other.promotion == promotion;

  @override
  int get hashCode => Object.hash(from, to, promotion);

  @override
  String toString() => toUci();
}
