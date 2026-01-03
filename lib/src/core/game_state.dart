import 'package:meta/meta.dart';

import 'board.dart';
import 'castling.dart';
import 'color.dart';
import 'square.dart';

/// Complete immutable chess game state.
///
/// Contains all information needed to fully describe a chess position:
/// - Board (piece placement)
/// - Side to move
/// - Castling rights
/// - En passant target square
/// - Halfmove clock (for 50-move rule)
/// - Fullmove number
@immutable
class GameState {
  const GameState({
    required this.board,
    required this.turn,
    required this.castling,
    this.enPassant,
    this.halfmoveClock = 0,
    this.fullmoveNumber = 1,
  });

  /// The board position.
  final Board board;

  /// Side to move.
  final Color turn;

  /// Castling availability.
  final CastlingRights castling;

  /// En passant target square (the square a pawn can capture to, not where the pawn is).
  final Square? enPassant;

  /// Halfmove clock (moves since last pawn move or capture).
  final int halfmoveClock;

  /// Fullmove number (starts at 1, increments after Black's move).
  final int fullmoveNumber;

  /// Initial chess position.
  static final initial = GameState(
    board: Board.initial,
    turn: Color.white,
    castling: CastlingRights.all,
  );

  /// Empty board (for testing/setup).
  static final empty = GameState(
    board: Board.empty,
    turn: Color.white,
    castling: CastlingRights.none,
  );

  /// Copy with new values.
  GameState copyWith({
    Board? board,
    Color? turn,
    CastlingRights? castling,
    Square? enPassant,
    bool clearEnPassant = false,
    int? halfmoveClock,
    int? fullmoveNumber,
  }) {
    return GameState(
      board: board ?? this.board,
      turn: turn ?? this.turn,
      castling: castling ?? this.castling,
      enPassant: clearEnPassant ? null : (enPassant ?? this.enPassant),
      halfmoveClock: halfmoveClock ?? this.halfmoveClock,
      fullmoveNumber: fullmoveNumber ?? this.fullmoveNumber,
    );
  }

  /// Whether the 50-move rule draw can be claimed.
  bool get canClaimFiftyMoveRule => halfmoveClock >= 100;

  /// Parse FEN string.
  ///
  /// Returns null if the FEN is invalid.
  static GameState? fromFen(String fen) {
    final parts = fen.trim().split(RegExp(r'\s+'));
    if (parts.length < 4 || parts.length > 6) return null;

    // 1. Piece placement
    final board = Board.fromFenPiecePlacement(parts[0]);
    if (board == null) return null;

    // 2. Active color
    final Color turn;
    switch (parts[1]) {
      case 'w':
        turn = Color.white;
      case 'b':
        turn = Color.black;
      default:
        return null;
    }

    // 3. Castling availability
    final castling = CastlingRights.fromFen(parts[2]);
    if (castling == null) return null;

    // 4. En passant target square
    Square? enPassant;
    if (parts[3] != '-') {
      enPassant = Square.parse(parts[3]);
      if (enPassant == null) return null;
    }

    // 5. Halfmove clock (optional, default 0)
    int halfmoveClock = 0;
    if (parts.length > 4) {
      halfmoveClock = int.tryParse(parts[4]) ?? -1;
      if (halfmoveClock < 0) return null;
    }

    // 6. Fullmove number (optional, default 1)
    int fullmoveNumber = 1;
    if (parts.length > 5) {
      fullmoveNumber = int.tryParse(parts[5]) ?? 0;
      if (fullmoveNumber < 1) return null;
    }

    return GameState(
      board: board,
      turn: turn,
      castling: castling,
      enPassant: enPassant,
      halfmoveClock: halfmoveClock,
      fullmoveNumber: fullmoveNumber,
    );
  }

  /// Format as FEN string.
  String toFen() {
    final parts = [
      board.toFenPiecePlacement(),
      turn.fenChar,
      castling.toFen(),
      enPassant?.algebraic ?? '-',
      halfmoveClock.toString(),
      fullmoveNumber.toString(),
    ];
    return parts.join(' ');
  }

  @override
  bool operator ==(Object other) =>
      other is GameState &&
      other.board == board &&
      other.turn == turn &&
      other.castling == castling &&
      other.enPassant == enPassant &&
      other.halfmoveClock == halfmoveClock &&
      other.fullmoveNumber == fullmoveNumber;

  @override
  int get hashCode => Object.hash(
        board,
        turn,
        castling,
        enPassant,
        halfmoveClock,
        fullmoveNumber,
      );

  @override
  String toString() => toFen();
}
