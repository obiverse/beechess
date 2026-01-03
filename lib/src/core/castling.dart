import 'package:meta/meta.dart';

/// Castling rights for both sides.
///
/// Immutable value object representing available castling options.
@immutable
class CastlingRights {
  const CastlingRights({
    this.whiteKingside = true,
    this.whiteQueenside = true,
    this.blackKingside = true,
    this.blackQueenside = true,
  });

  /// No castling rights available.
  static const none = CastlingRights(
    whiteKingside: false,
    whiteQueenside: false,
    blackKingside: false,
    blackQueenside: false,
  );

  /// All castling rights available (initial position).
  static const all = CastlingRights();

  /// White can castle kingside (O-O).
  final bool whiteKingside;

  /// White can castle queenside (O-O-O).
  final bool whiteQueenside;

  /// Black can castle kingside (O-O).
  final bool blackKingside;

  /// Black can castle queenside (O-O-O).
  final bool blackQueenside;

  /// Whether any castling is possible.
  bool get any =>
      whiteKingside || whiteQueenside || blackKingside || blackQueenside;

  /// Copy with modified rights.
  CastlingRights copyWith({
    bool? whiteKingside,
    bool? whiteQueenside,
    bool? blackKingside,
    bool? blackQueenside,
  }) {
    return CastlingRights(
      whiteKingside: whiteKingside ?? this.whiteKingside,
      whiteQueenside: whiteQueenside ?? this.whiteQueenside,
      blackKingside: blackKingside ?? this.blackKingside,
      blackQueenside: blackQueenside ?? this.blackQueenside,
    );
  }

  /// Revoke all castling rights for a color (when king moves).
  CastlingRights revokeForColor(bool isWhite) {
    if (isWhite) {
      return copyWith(whiteKingside: false, whiteQueenside: false);
    } else {
      return copyWith(blackKingside: false, blackQueenside: false);
    }
  }

  /// Revoke kingside castling for a color (when h-rook moves).
  CastlingRights revokeKingside(bool isWhite) {
    if (isWhite) {
      return copyWith(whiteKingside: false);
    } else {
      return copyWith(blackKingside: false);
    }
  }

  /// Revoke queenside castling for a color (when a-rook moves).
  CastlingRights revokeQueenside(bool isWhite) {
    if (isWhite) {
      return copyWith(whiteQueenside: false);
    } else {
      return copyWith(blackQueenside: false);
    }
  }

  /// Format as FEN castling string (e.g., "KQkq", "Kq", "-").
  String toFen() {
    if (!any) return '-';

    final buffer = StringBuffer();
    if (whiteKingside) buffer.write('K');
    if (whiteQueenside) buffer.write('Q');
    if (blackKingside) buffer.write('k');
    if (blackQueenside) buffer.write('q');
    return buffer.toString();
  }

  /// Parse FEN castling string.
  ///
  /// Returns null if invalid.
  static CastlingRights? fromFen(String fen) {
    if (fen.isEmpty) return null;
    if (fen == '-') return none;

    bool wk = false, wq = false, bk = false, bq = false;

    for (final char in fen.split('')) {
      switch (char) {
        case 'K':
          if (wk) return null; // Duplicate
          wk = true;
        case 'Q':
          if (wq) return null;
          wq = true;
        case 'k':
          if (bk) return null;
          bk = true;
        case 'q':
          if (bq) return null;
          bq = true;
        default:
          return null; // Invalid character
      }
    }

    return CastlingRights(
      whiteKingside: wk,
      whiteQueenside: wq,
      blackKingside: bk,
      blackQueenside: bq,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CastlingRights &&
      other.whiteKingside == whiteKingside &&
      other.whiteQueenside == whiteQueenside &&
      other.blackKingside == blackKingside &&
      other.blackQueenside == blackQueenside;

  @override
  int get hashCode =>
      Object.hash(whiteKingside, whiteQueenside, blackKingside, blackQueenside);

  @override
  String toString() => toFen();
}
