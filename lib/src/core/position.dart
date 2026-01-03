import 'attacks.dart';
import 'board.dart';
import 'castling.dart';
import 'color.dart';
import 'game_state.dart';
import 'move.dart';
import 'move_gen.dart';
import 'piece.dart';
import 'square.dart';

/// A chess position with move generation and game logic.
///
/// This is the main entry point for working with chess positions.
/// It wraps GameState and provides higher-level operations.
class Position {
  const Position(this.state);

  /// Create the standard starting position.
  factory Position.initial() => Position(GameState.initial);

  /// The underlying game state.
  final GameState state;

  /// Parse a FEN string.
  ///
  /// Returns null if the FEN is invalid.
  static Position? fromFen(String fen) {
    final state = GameState.fromFen(fen);
    if (state == null) return null;
    return Position(state);
  }

  // === Delegated properties ===

  /// The board.
  Board get board => state.board;

  /// Side to move.
  Color get turn => state.turn;

  /// Castling rights.
  CastlingRights get castling => state.castling;

  /// En passant target square.
  Square? get enPassant => state.enPassant;

  /// Halfmove clock.
  int get halfmoveClock => state.halfmoveClock;

  /// Fullmove number.
  int get fullmoveNumber => state.fullmoveNumber;

  // === Move generation ===

  /// All legal moves from this position.
  List<Move> get legalMoves => MoveGen.legalMoves(state);

  /// Whether there are any legal moves.
  bool get hasLegalMoves => legalMoves.isNotEmpty;

  // === Check and checkmate ===

  /// Whether the current side's king is in check.
  bool get isCheck => Attacks.isInCheck(board, turn);

  /// Whether the current side is checkmated.
  bool get isCheckmate => isCheck && !hasLegalMoves;

  /// Whether the game is a stalemate.
  bool get isStalemate => !isCheck && !hasLegalMoves;

  /// Whether the game is over (checkmate or stalemate).
  bool get isGameOver => !hasLegalMoves;

  /// Whether a draw can be claimed under the 50-move rule.
  bool get canClaimFiftyMoveRule => state.canClaimFiftyMoveRule;

  // === Move execution ===

  /// Make a move and return the new position.
  ///
  /// Returns null if the move is illegal.
  Position? makeMove(Move move) {
    // Verify the move is legal
    if (!legalMoves.contains(move)) return null;

    return Position(_applyMove(state, move));
  }

  /// Make a move from UCI notation.
  ///
  /// Returns null if the move is invalid or illegal.
  Position? makeMoveUci(String uci) {
    final move = Move.parse(uci);
    if (move == null) return null;
    return makeMove(move);
  }

  /// Apply a move to the state (assumes move is legal).
  static GameState _applyMove(GameState state, Move move) {
    var board = state.board;
    final piece = board[move.from];
    if (piece == null) return state; // Invalid move

    var castling = state.castling;
    Square? newEnPassant;
    var halfmoveClock = state.halfmoveClock + 1;
    var fullmoveNumber = state.fullmoveNumber;

    final isCapture = board[move.to] != null ||
        (piece.type == PieceType.pawn && move.to == state.enPassant);
    final isPawnMove = piece.type == PieceType.pawn;

    // Reset halfmove clock on pawn move or capture
    if (isPawnMove || isCapture) {
      halfmoveClock = 0;
    }

    // Handle castling rights
    if (piece.type == PieceType.king) {
      castling = castling.revokeForColor(state.turn == Color.white);

      // Move rook for castling
      final fileDiff = move.to.file - move.from.file;
      if (fileDiff.abs() == 2) {
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

    // Revoke castling if rook moves or is captured
    if (move.from == Square.a1 || move.to == Square.a1) {
      castling = castling.copyWith(whiteQueenside: false);
    }
    if (move.from == Square.h1 || move.to == Square.h1) {
      castling = castling.copyWith(whiteKingside: false);
    }
    if (move.from == Square.a8 || move.to == Square.a8) {
      castling = castling.copyWith(blackQueenside: false);
    }
    if (move.from == Square.h8 || move.to == Square.h8) {
      castling = castling.copyWith(blackKingside: false);
    }

    // Handle en passant capture
    if (isPawnMove && move.to == state.enPassant) {
      final capturedPawnRank = state.turn == Color.white
          ? move.to.rank - 1
          : move.to.rank + 1;
      final capturedPawnSquare = Square(capturedPawnRank * 8 + move.to.file);
      board = board.remove(capturedPawnSquare);
    }

    // Set new en passant square for double pawn push
    if (isPawnMove && (move.to.rank - move.from.rank).abs() == 2) {
      final epRank = (move.from.rank + move.to.rank) ~/ 2;
      newEnPassant = Square(epRank * 8 + move.from.file);
    }

    // Move the piece
    board = board.movePiece(move.from, move.to);

    // Handle promotion
    if (move.promotion != null) {
      board = board.put(move.to, Piece(move.promotion!, piece.color));
    }

    // Increment fullmove number after Black's move
    if (state.turn == Color.black) {
      fullmoveNumber++;
    }

    return GameState(
      board: board,
      turn: state.turn.opposite,
      castling: castling,
      enPassant: newEnPassant,
      halfmoveClock: halfmoveClock,
      fullmoveNumber: fullmoveNumber,
    );
  }

  // === FEN ===

  /// Convert to FEN string.
  String toFen() => state.toFen();

  @override
  String toString() => toFen();

  @override
  bool operator ==(Object other) =>
      other is Position && other.state == state;

  @override
  int get hashCode => state.hashCode;
}
