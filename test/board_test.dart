import 'package:beechess/beechess.dart';
import 'package:test/test.dart';

void main() {
  group('Board', () {
    test('empty board has no pieces', () {
      final board = Board.empty;
      for (final sq in Square.all) {
        expect(board[sq], null);
      }
    });

    test('initial position has correct piece count', () {
      final board = Board.initial;
      expect(board.countAllPieces(Color.white), 16);
      expect(board.countAllPieces(Color.black), 16);
    });

    test('initial position has correct piece placement', () {
      final board = Board.initial;

      // White back rank
      expect(board[Square.a1], whiteRook);
      expect(board[Square.b1], whiteKnight);
      expect(board[Square.c1], whiteBishop);
      expect(board[Square.d1], whiteQueen);
      expect(board[Square.e1], whiteKing);
      expect(board[Square.f1], whiteBishop);
      expect(board[Square.g1], whiteKnight);
      expect(board[Square.h1], whiteRook);

      // White pawns
      for (final sq in [
        Square.a2,
        Square.b2,
        Square.c2,
        Square.d2,
        Square.e2,
        Square.f2,
        Square.g2,
        Square.h2,
      ]) {
        expect(board[sq], whitePawn);
      }

      // Black back rank
      expect(board[Square.a8], blackRook);
      expect(board[Square.e8], blackKing);
      expect(board[Square.d8], blackQueen);

      // Black pawns
      for (final sq in [
        Square.a7,
        Square.b7,
        Square.c7,
        Square.d7,
        Square.e7,
        Square.f7,
        Square.g7,
        Square.h7,
      ]) {
        expect(board[sq], blackPawn);
      }

      // Center should be empty
      expect(board[Square.e4], null);
      expect(board[Square.d4], null);
      expect(board[Square.e5], null);
      expect(board[Square.d5], null);
    });

    test('put creates new board with piece', () {
      final board = Board.empty.put(Square.e4, whiteKnight);
      expect(board[Square.e4], whiteKnight);
      expect(Board.empty[Square.e4], null); // Original unchanged
    });

    test('remove creates new board without piece', () {
      final board = Board.initial.remove(Square.e1);
      expect(board[Square.e1], null);
      expect(Board.initial[Square.e1], whiteKing); // Original unchanged
    });

    test('movePiece moves piece correctly', () {
      final board = Board.initial.movePiece(Square.e2, Square.e4);
      expect(board[Square.e2], null);
      expect(board[Square.e4], whitePawn);
    });

    test('findKing returns correct square', () {
      expect(Board.initial.findKing(Color.white), Square.e1);
      expect(Board.initial.findKing(Color.black), Square.e8);
    });

    test('findKing returns null when no king', () {
      final board = Board.empty;
      expect(board.findKing(Color.white), null);
      expect(board.findKing(Color.black), null);
    });

    test('findPiece returns all matching squares', () {
      final knights = Board.initial.findPiece(whiteKnight).toList();
      expect(knights, containsAll([Square.b1, Square.g1]));
      expect(knights.length, 2);
    });

    test('squaresForColor returns correct squares', () {
      final whiteSquares = Board.initial.squaresForColor(Color.white).toList();
      expect(whiteSquares.length, 16);
    });

    test('isEmpty and isOccupied work correctly', () {
      expect(Board.initial.isEmpty(Square.e4), true);
      expect(Board.initial.isOccupied(Square.e4), false);
      expect(Board.initial.isEmpty(Square.e2), false);
      expect(Board.initial.isOccupied(Square.e2), true);
    });

    test('countPieces works correctly', () {
      expect(Board.initial.countPieces(PieceType.pawn, Color.white), 8);
      expect(Board.initial.countPieces(PieceType.knight, Color.black), 2);
      expect(Board.initial.countPieces(PieceType.queen, Color.white), 1);
      expect(Board.initial.countPieces(PieceType.king, Color.black), 1);
    });

    test('equality works', () {
      expect(Board.initial, Board.initial);
      expect(Board.empty, Board.empty);
      expect(Board.initial, isNot(Board.empty));

      final board1 = Board.empty.put(Square.e4, whiteKnight);
      final board2 = Board.empty.put(Square.e4, whiteKnight);
      expect(board1, board2);
    });
  });

  group('Board FEN', () {
    test('initial position round-trip', () {
      final fen = Board.initial.toFenPiecePlacement();
      expect(fen, 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR');

      final parsed = Board.fromFenPiecePlacement(fen);
      expect(parsed, Board.initial);
    });

    test('empty board round-trip', () {
      final fen = Board.empty.toFenPiecePlacement();
      expect(fen, '8/8/8/8/8/8/8/8');

      final parsed = Board.fromFenPiecePlacement(fen);
      expect(parsed, Board.empty);
    });

    test('custom position round-trip', () {
      // Sicilian Defense after e4 c5
      const fen = 'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR';
      final board = Board.fromFenPiecePlacement(fen);
      expect(board, isNotNull);
      expect(board![Square.e4], whitePawn);
      expect(board[Square.c5], blackPawn);
      expect(board[Square.e2], null);
      expect(board.toFenPiecePlacement(), fen);
    });

    test('invalid FEN returns null', () {
      expect(Board.fromFenPiecePlacement(''), null);
      expect(Board.fromFenPiecePlacement('8/8/8'), null); // Too few ranks
      expect(Board.fromFenPiecePlacement('9/8/8/8/8/8/8/8'), null); // Invalid number
      expect(Board.fromFenPiecePlacement('X/8/8/8/8/8/8/8'), null); // Invalid piece
      expect(Board.fromFenPiecePlacement('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBN'), null); // Short rank
    });
  });

  group('CastlingRights', () {
    test('all has all rights', () {
      expect(CastlingRights.all.whiteKingside, true);
      expect(CastlingRights.all.whiteQueenside, true);
      expect(CastlingRights.all.blackKingside, true);
      expect(CastlingRights.all.blackQueenside, true);
      expect(CastlingRights.all.any, true);
    });

    test('none has no rights', () {
      expect(CastlingRights.none.whiteKingside, false);
      expect(CastlingRights.none.whiteQueenside, false);
      expect(CastlingRights.none.blackKingside, false);
      expect(CastlingRights.none.blackQueenside, false);
      expect(CastlingRights.none.any, false);
    });

    test('toFen formats correctly', () {
      expect(CastlingRights.all.toFen(), 'KQkq');
      expect(CastlingRights.none.toFen(), '-');
      expect(
        const CastlingRights(whiteKingside: true, whiteQueenside: false, blackKingside: false, blackQueenside: true).toFen(),
        'Kq',
      );
    });

    test('fromFen parses correctly', () {
      expect(CastlingRights.fromFen('KQkq'), CastlingRights.all);
      expect(CastlingRights.fromFen('-'), CastlingRights.none);
      expect(
        CastlingRights.fromFen('Kq'),
        const CastlingRights(whiteKingside: true, whiteQueenside: false, blackKingside: false, blackQueenside: true),
      );
    });

    test('fromFen returns null for invalid', () {
      expect(CastlingRights.fromFen(''), null);
      expect(CastlingRights.fromFen('X'), null);
      expect(CastlingRights.fromFen('KK'), null); // Duplicate
    });

    test('revokeForColor works', () {
      final rights = CastlingRights.all.revokeForColor(true);
      expect(rights.whiteKingside, false);
      expect(rights.whiteQueenside, false);
      expect(rights.blackKingside, true);
      expect(rights.blackQueenside, true);
    });

    test('revokeKingside works', () {
      final rights = CastlingRights.all.revokeKingside(false);
      expect(rights.whiteKingside, true);
      expect(rights.blackKingside, false);
    });

    test('equality works', () {
      expect(CastlingRights.all, CastlingRights.all);
      expect(CastlingRights.none, CastlingRights.none);
      expect(CastlingRights.all, isNot(CastlingRights.none));
    });
  });

  group('GameState', () {
    test('initial position is correct', () {
      final state = GameState.initial;
      expect(state.board, Board.initial);
      expect(state.turn, Color.white);
      expect(state.castling, CastlingRights.all);
      expect(state.enPassant, null);
      expect(state.halfmoveClock, 0);
      expect(state.fullmoveNumber, 1);
    });

    test('toFen produces correct initial position', () {
      expect(
        GameState.initial.toFen(),
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );
    });

    test('fromFen parses initial position', () {
      final state = GameState.fromFen(
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );
      expect(state, isNotNull);
      expect(state!.board, Board.initial);
      expect(state.turn, Color.white);
      expect(state.castling, CastlingRights.all);
      expect(state.enPassant, null);
    });

    test('fromFen parses position with en passant', () {
      final state = GameState.fromFen(
        'rnbqkbnr/pppp1ppp/8/4pP2/8/8/PPPPP1PP/RNBQKBNR w KQkq e6 0 3',
      );
      expect(state, isNotNull);
      expect(state!.enPassant, Square.e6);
      expect(state.turn, Color.white);
    });

    test('fromFen parses black to move', () {
      final state = GameState.fromFen(
        'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
      );
      expect(state, isNotNull);
      expect(state!.turn, Color.black);
      expect(state.enPassant, Square.e3);
    });

    test('FEN round-trip', () {
      final positions = [
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
        'r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1',
        '8/8/8/8/8/8/8/4K2k w - - 50 100',
      ];

      for (final fen in positions) {
        final state = GameState.fromFen(fen);
        expect(state, isNotNull, reason: 'Failed to parse: $fen');
        expect(state!.toFen(), fen, reason: 'Round-trip failed for: $fen');
      }
    });

    test('fromFen returns null for invalid input', () {
      expect(GameState.fromFen(''), null);
      expect(GameState.fromFen('invalid'), null);
      expect(GameState.fromFen('8/8/8/8/8/8/8/8 x KQkq - 0 1'), null); // Invalid color
      expect(GameState.fromFen('8/8/8/8/8/8/8/8 w XYZ - 0 1'), null); // Invalid castling
      expect(GameState.fromFen('8/8/8/8/8/8/8/8 w KQkq z9 0 1'), null); // Invalid en passant
      expect(GameState.fromFen('8/8/8/8/8/8/8/8 w KQkq - -1 1'), null); // Negative halfmove
      expect(GameState.fromFen('8/8/8/8/8/8/8/8 w KQkq - 0 0'), null); // Zero fullmove
    });

    test('copyWith works correctly', () {
      final state = GameState.initial;
      final newState = state.copyWith(
        turn: Color.black,
        halfmoveClock: 5,
      );

      expect(newState.turn, Color.black);
      expect(newState.halfmoveClock, 5);
      expect(newState.board, state.board); // Unchanged
      expect(state.turn, Color.white); // Original unchanged
    });

    test('clearEnPassant works', () {
      final state = GameState.fromFen(
        'rnbqkbnr/pppp1ppp/8/4pP2/8/8/PPPPP1PP/RNBQKBNR w KQkq e6 0 3',
      )!;
      expect(state.enPassant, Square.e6);

      final cleared = state.copyWith(clearEnPassant: true);
      expect(cleared.enPassant, null);
    });

    test('canClaimFiftyMoveRule works', () {
      final state = GameState.initial;
      expect(state.canClaimFiftyMoveRule, false);

      final fiftyMoves = state.copyWith(halfmoveClock: 100);
      expect(fiftyMoves.canClaimFiftyMoveRule, true);
    });

    test('equality works', () {
      expect(GameState.initial, GameState.initial);
      expect(
        GameState.fromFen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'),
        GameState.initial,
      );
    });
  });
}
