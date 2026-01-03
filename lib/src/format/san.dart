import '../core/color.dart';
import '../core/move.dart';
import '../core/piece.dart';
import '../core/position.dart';
import '../core/square.dart';

/// Standard Algebraic Notation (SAN) for chess moves.
///
/// SAN is the human-readable notation used in chess publications:
/// - e4, Nf3, Bxe5, O-O, exd5, Nbd2, e8=Q, Nf3+, Qxf7#
class San {
  San._();

  /// Parse SAN notation in context of a position.
  ///
  /// Returns null if the SAN is invalid or the move is illegal.
  static Move? parse(String san, Position position) {
    if (san.isEmpty) return null;

    // Handle castling
    if (san == 'O-O' || san == '0-0') {
      return _findCastlingMove(position, kingside: true);
    }
    if (san == 'O-O-O' || san == '0-0-0') {
      return _findCastlingMove(position, kingside: false);
    }

    // Remove check/checkmate indicators
    var s = san.replaceAll(RegExp(r'[+#!?]+$'), '');
    if (s.isEmpty) return null;

    // Parse promotion
    PieceType? promotion;
    if (s.contains('=')) {
      final parts = s.split('=');
      if (parts.length != 2 || parts[1].isEmpty) return null;
      promotion = PieceType.fromLetter(parts[1][0]);
      if (promotion == null || promotion is Pawn || promotion is King) {
        return null;
      }
      s = parts[0];
    }

    // Need at least destination square (2 chars)
    if (s.length < 2) return null;

    // Parse destination square (last 2 chars)
    final toStr = s.substring(s.length - 2);
    final to = Square.parse(toStr);
    if (to == null) return null;
    s = s.substring(0, s.length - 2);

    // Remove capture indicator
    final isCapture = s.endsWith('x');
    if (isCapture) {
      s = s.substring(0, s.length - 1);
    }

    // Determine piece type
    PieceType pieceType;
    String disambiguation = '';

    if (s.isEmpty) {
      // Pawn move (e.g., "e4", "exd5")
      pieceType = PieceType.pawn;
    } else if (_isPieceChar(s[0])) {
      // Piece move (e.g., "Nf3", "Bxe5", "Qh4e1")
      final parsed = PieceType.fromLetter(s[0]);
      if (parsed == null) return null;
      pieceType = parsed;
      disambiguation = s.substring(1);
    } else {
      // Pawn capture with file (e.g., "exd5" -> "e")
      pieceType = PieceType.pawn;
      disambiguation = s;
    }

    // Parse disambiguation
    int? fromFile;
    int? fromRank;

    for (final c in disambiguation.runes) {
      final char = String.fromCharCode(c);
      if (char.compareTo('a') >= 0 && char.compareTo('h') <= 0) {
        fromFile = c - 'a'.codeUnitAt(0);
      } else if (char.compareTo('1') >= 0 && char.compareTo('8') <= 0) {
        fromRank = c - '1'.codeUnitAt(0);
      }
    }

    // Find matching legal move
    final legalMoves = position.legalMoves;
    for (final move in legalMoves) {
      if (move.to != to) continue;

      final piece = position.board[move.from];
      if (piece == null || piece.type != pieceType) continue;

      // Check disambiguation
      if (fromFile != null && move.from.file != fromFile) continue;
      if (fromRank != null && move.from.rank != fromRank) continue;

      // Check promotion
      if (promotion != null) {
        if (move.promotion != promotion) continue;
      } else if (move.promotion != null) {
        continue; // Move has promotion but SAN doesn't
      }

      return move;
    }

    return null;
  }

  /// Format a move as SAN notation.
  ///
  /// Requires the position before the move is made.
  static String format(Move move, Position position) {
    final piece = position.board[move.from];
    if (piece == null) return move.toUci();

    final buffer = StringBuffer();

    // Handle castling
    if (piece.type is King && (move.from.file - move.to.file).abs() > 1) {
      return move.to.file > move.from.file ? 'O-O' : 'O-O-O';
    }

    // Piece letter (not for pawns)
    if (piece.type is! Pawn) {
      buffer.write(piece.type.letter.toUpperCase());
    }

    // Disambiguation
    final disambiguation = _getDisambiguation(move, position);
    buffer.write(disambiguation);

    // Capture indicator
    final capturedPiece = position.board[move.to];
    final isEnPassant = piece.type is Pawn &&
        move.from.file != move.to.file &&
        capturedPiece == null;

    if (capturedPiece != null || isEnPassant) {
      if (piece.type is Pawn && disambiguation.isEmpty) {
        buffer.write(_fileChar(move.from.file));
      }
      buffer.write('x');
    }

    // Destination square
    buffer.write(move.to.algebraic);

    // Promotion
    if (move.promotion != null) {
      buffer.write('=');
      buffer.write(move.promotion!.letter.toUpperCase());
    }

    // Check/checkmate indicator
    final newPos = position.makeMove(move);
    if (newPos != null) {
      if (newPos.isCheckmate) {
        buffer.write('#');
      } else if (newPos.isCheck) {
        buffer.write('+');
      }
    }

    return buffer.toString();
  }

  /// Get disambiguation string for a move.
  ///
  /// Returns file, rank, or both as needed to uniquely identify the piece.
  static String _getDisambiguation(Move move, Position position) {
    final piece = position.board[move.from];
    if (piece == null) return '';

    // Pawns use file for captures only (handled separately)
    // Kings never need disambiguation
    if (piece.type is Pawn || piece.type is King) {
      return '';
    }

    // Find other pieces of same type that can reach same square
    final ambiguous = position.legalMoves
        .where((m) =>
            m.to == move.to &&
            m.from != move.from &&
            position.board[m.from]?.type == piece.type)
        .toList();

    if (ambiguous.isEmpty) return '';

    // Check if file disambiguation is sufficient
    if (ambiguous.every((m) => m.from.file != move.from.file)) {
      return _fileChar(move.from.file);
    }

    // Check if rank disambiguation is sufficient
    if (ambiguous.every((m) => m.from.rank != move.from.rank)) {
      return '${move.from.rank + 1}';
    }

    // Need both (full square)
    return move.from.algebraic;
  }

  /// Find the castling move for the current position.
  static Move? _findCastlingMove(Position position, {required bool kingside}) {
    final turn = position.turn;
    final rank = turn == Color.white ? 0 : 7;
    final kingFrom = Square.fromRankFile(rank, 4);
    final kingTo = Square.fromRankFile(rank, kingside ? 6 : 2);

    if (kingFrom == null || kingTo == null) return null;

    for (final move in position.legalMoves) {
      if (move.from == kingFrom && move.to == kingTo) {
        final piece = position.board[move.from];
        if (piece?.type is King) {
          return move;
        }
      }
    }
    return null;
  }

  /// Check if character is a piece letter.
  static bool _isPieceChar(String c) {
    return 'KQRBN'.contains(c.toUpperCase());
  }

  /// Get file character (a-h).
  static String _fileChar(int file) {
    return String.fromCharCode('a'.codeUnitAt(0) + file);
  }
}
