import 'attacks.dart';
import 'board.dart';
import 'color.dart';
import 'direction.dart';
import 'game_state.dart';
import 'move.dart';
import 'piece.dart';
import 'square.dart';

/// Move generation for chess.
///
/// Generates all legal moves from a position.
class MoveGen {
  MoveGen._();

  /// Generate all legal moves for the current position.
  static List<Move> legalMoves(GameState state) {
    final pseudoLegal = _pseudoLegalMoves(state);
    return pseudoLegal.where((move) => _isLegal(state, move)).toList();
  }

  /// Generate all pseudo-legal moves (may leave king in check).
  static List<Move> _pseudoLegalMoves(GameState state) {
    final moves = <Move>[];
    final board = state.board;
    final turn = state.turn;

    for (final from in board.squaresForColor(turn)) {
      final piece = board[from]!;
      switch (piece.type) {
        case Pawn():
          moves.addAll(_pawnMoves(state, from));
        case Knight():
          moves.addAll(_knightMoves(board, from, turn));
        case Bishop():
          moves.addAll(_slidingMoves(board, from, turn, Direction.bishop));
        case Rook():
          moves.addAll(_slidingMoves(board, from, turn, Direction.rook));
        case Queen():
          moves.addAll(_slidingMoves(board, from, turn, Direction.queen));
        case King():
          moves.addAll(_kingMoves(state, from));
      }
    }

    return moves;
  }

  /// Check if a pseudo-legal move is actually legal.
  static bool _isLegal(GameState state, Move move) {
    // Make the move and check if our king is in check
    final newBoard = _applyMoveToBoard(state, move);
    return !Attacks.isInCheck(newBoard, state.turn);
  }

  /// Apply a move to the board (for legality checking).
  static Board _applyMoveToBoard(GameState state, Move move) {
    var board = state.board;
    final piece = board[move.from];
    if (piece == null) return board;

    // Handle castling
    if (piece.type == PieceType.king) {
      final fileDiff = move.to.file - move.from.file;
      if (fileDiff.abs() == 2) {
        // Castling - also move the rook
        if (fileDiff > 0) {
          // Kingside
          final rookFrom = Square(move.from.rank * 8 + 7);
          final rookTo = Square(move.from.rank * 8 + 5);
          board = board.movePiece(rookFrom, rookTo);
        } else {
          // Queenside
          final rookFrom = Square(move.from.rank * 8);
          final rookTo = Square(move.from.rank * 8 + 3);
          board = board.movePiece(rookFrom, rookTo);
        }
      }
    }

    // Handle en passant capture
    if (piece.type == PieceType.pawn && move.to == state.enPassant) {
      final capturedPawnRank = state.turn == Color.white
          ? move.to.rank - 1
          : move.to.rank + 1;
      final capturedPawnSquare = Square(capturedPawnRank * 8 + move.to.file);
      board = board.remove(capturedPawnSquare);
    }

    // Move the piece
    board = board.movePiece(move.from, move.to);

    // Handle promotion
    if (move.promotion != null) {
      board = board.put(move.to, Piece(move.promotion!, piece.color));
    }

    return board;
  }

  // === Piece-specific move generation ===

  static Iterable<Move> _pawnMoves(GameState state, Square from) sync* {
    final board = state.board;
    final color = state.turn;
    final dir = color.direction;
    final startRank = color.pawnRank;
    final promotionRank = color.promotionRank;

    // Single push
    final oneStep = from.shift(dir, 0);
    if (oneStep != null && board.isEmpty(oneStep)) {
      if (oneStep.rank == promotionRank) {
        // Promotion
        yield Move(from, oneStep, PieceType.queen);
        yield Move(from, oneStep, PieceType.rook);
        yield Move(from, oneStep, PieceType.bishop);
        yield Move(from, oneStep, PieceType.knight);
      } else {
        yield Move(from, oneStep);

        // Double push from starting position
        if (from.rank == startRank) {
          final twoStep = from.shift(dir * 2, 0);
          if (twoStep != null && board.isEmpty(twoStep)) {
            yield Move(from, twoStep);
          }
        }
      }
    }

    // Captures
    for (final df in [-1, 1]) {
      final capture = from.shift(dir, df);
      if (capture == null) continue;

      final canCapture = _isEnemyPiece(board, capture, color) ||
          capture == state.enPassant;

      if (canCapture) {
        if (capture.rank == promotionRank) {
          yield Move(from, capture, PieceType.queen);
          yield Move(from, capture, PieceType.rook);
          yield Move(from, capture, PieceType.bishop);
          yield Move(from, capture, PieceType.knight);
        } else {
          yield Move(from, capture);
        }
      }
    }
  }

  static Iterable<Move> _knightMoves(Board board, Square from, Color color) sync* {
    for (final dir in Direction.knight) {
      final to = from.shift(dir.dr, dir.df);
      if (to == null) continue;
      if (!_isFriendlyPiece(board, to, color)) {
        yield Move(from, to);
      }
    }
  }

  static Iterable<Move> _slidingMoves(
    Board board,
    Square from,
    Color color,
    List<Direction> directions,
  ) sync* {
    for (final dir in directions) {
      Square? to = from;
      while (true) {
        to = to!.shift(dir.dr, dir.df);
        if (to == null) break;

        if (_isFriendlyPiece(board, to, color)) break;

        yield Move(from, to);

        if (board[to] != null) break; // Stop after capture
      }
    }
  }

  static Iterable<Move> _kingMoves(GameState state, Square from) sync* {
    final board = state.board;
    final color = state.turn;

    // Normal king moves
    for (final dir in Direction.king) {
      final to = from.shift(dir.dr, dir.df);
      if (to == null) continue;
      if (!_isFriendlyPiece(board, to, color)) {
        yield Move(from, to);
      }
    }

    // Castling
    yield* _castlingMoves(state, from);
  }

  static Iterable<Move> _castlingMoves(GameState state, Square kingSquare) sync* {
    final board = state.board;
    final color = state.turn;
    final castling = state.castling;

    // Can't castle if in check
    if (Attacks.isInCheck(board, color)) return;

    final rank = color.backRank;
    final isWhite = color == Color.white;

    // Kingside castling
    final canKingside = isWhite ? castling.whiteKingside : castling.blackKingside;
    if (canKingside) {
      final f = Square(rank * 8 + 5); // f1 or f8
      final g = Square(rank * 8 + 6); // g1 or g8

      if (board.isEmpty(f) && board.isEmpty(g)) {
        // Check that king doesn't pass through check
        if (!Attacks.isAttacked(board, f, color.opposite) &&
            !Attacks.isAttacked(board, g, color.opposite)) {
          yield Move(kingSquare, g);
        }
      }
    }

    // Queenside castling
    final canQueenside = isWhite ? castling.whiteQueenside : castling.blackQueenside;
    if (canQueenside) {
      final d = Square(rank * 8 + 3); // d1 or d8
      final c = Square(rank * 8 + 2); // c1 or c8
      final b = Square(rank * 8 + 1); // b1 or b8

      if (board.isEmpty(d) && board.isEmpty(c) && board.isEmpty(b)) {
        // Check that king doesn't pass through check
        if (!Attacks.isAttacked(board, d, color.opposite) &&
            !Attacks.isAttacked(board, c, color.opposite)) {
          yield Move(kingSquare, c);
        }
      }
    }
  }

  // === Helpers ===

  static bool _isFriendlyPiece(Board board, Square sq, Color color) {
    final piece = board[sq];
    return piece != null && piece.color == color;
  }

  static bool _isEnemyPiece(Board board, Square sq, Color color) {
    final piece = board[sq];
    return piece != null && piece.color != color;
  }
}
