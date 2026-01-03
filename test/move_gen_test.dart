import 'package:beechess/beechess.dart';
import 'package:test/test.dart';

void main() {
  group('Attacks', () {
    test('initial position has no checks', () {
      expect(Attacks.isInCheck(Board.initial, Color.white), false);
      expect(Attacks.isInCheck(Board.initial, Color.black), false);
    });

    test('pawn attacks diagonally', () {
      final pos = Position.fromFen('8/8/8/8/3p4/2P5/8/8 w - - 0 1')!;
      expect(Attacks.isAttacked(pos.board, Square.d4, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.b4, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.c4, Color.white), false);
    });

    test('knight attacks correctly', () {
      final pos = Position.fromFen('8/8/8/8/3N4/8/8/8 w - - 0 1')!;
      // Knight on d4 attacks: c2, e2, b3, f3, b5, f5, c6, e6
      expect(Attacks.isAttacked(pos.board, Square.c2, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.e2, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.b3, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.f3, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.b5, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.f5, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.c6, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.e6, Color.white), true);
      // Not attacked
      expect(Attacks.isAttacked(pos.board, Square.d5, Color.white), false);
      expect(Attacks.isAttacked(pos.board, Square.e4, Color.white), false);
    });

    test('bishop attacks diagonally', () {
      final pos = Position.fromFen('8/8/8/8/3B4/8/8/8 w - - 0 1')!;
      expect(Attacks.isAttacked(pos.board, Square.a1, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.h8, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.a7, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.g1, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.d5, Color.white), false);
    });

    test('rook attacks horizontally and vertically', () {
      final pos = Position.fromFen('8/8/8/8/3R4/8/8/8 w - - 0 1')!;
      expect(Attacks.isAttacked(pos.board, Square.d1, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.d8, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.a4, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.h4, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.e5, Color.white), false);
    });

    test('queen attacks all directions', () {
      final pos = Position.fromFen('8/8/8/8/3Q4/8/8/8 w - - 0 1')!;
      // Rook-like
      expect(Attacks.isAttacked(pos.board, Square.d1, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.h4, Color.white), true);
      // Bishop-like
      expect(Attacks.isAttacked(pos.board, Square.a1, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.h8, Color.white), true);
    });

    test('king attacks adjacent squares', () {
      final pos = Position.fromFen('8/8/8/8/3K4/8/8/8 w - - 0 1')!;
      expect(Attacks.isAttacked(pos.board, Square.c3, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.d3, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.e3, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.c4, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.e4, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.c5, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.d5, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.e5, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.b4, Color.white), false);
    });

    test('sliding piece is blocked', () {
      final pos = Position.fromFen('8/8/3p4/8/3R4/8/8/8 w - - 0 1')!;
      expect(Attacks.isAttacked(pos.board, Square.d6, Color.white), true);
      expect(Attacks.isAttacked(pos.board, Square.d7, Color.white), false); // Blocked
      expect(Attacks.isAttacked(pos.board, Square.d8, Color.white), false); // Blocked
    });

    test('isInCheck detects check', () {
      // White rook on e1 gives check to black king on e8 (same file)
      final pos = Position.fromFen('4k3/8/8/8/8/8/8/4R2K w - - 0 1')!;
      expect(Attacks.isInCheck(pos.board, Color.black), true);
      expect(Attacks.isInCheck(pos.board, Color.white), false);
    });
  });

  group('MoveGen initial position', () {
    test('white has 20 moves', () {
      final pos = Position.initial();
      final moves = pos.legalMoves;
      expect(moves.length, 20);
    });

    test('pawn can move 1 or 2 squares from start', () {
      final pos = Position.initial();
      final moves = pos.legalMoves;

      // e2-e3 and e2-e4 should be available
      expect(moves.any((m) => m.toUci() == 'e2e3'), true);
      expect(moves.any((m) => m.toUci() == 'e2e4'), true);
    });

    test('knight can move from initial position', () {
      final pos = Position.initial();
      final moves = pos.legalMoves;

      expect(moves.any((m) => m.toUci() == 'g1f3'), true);
      expect(moves.any((m) => m.toUci() == 'g1h3'), true);
      expect(moves.any((m) => m.toUci() == 'b1a3'), true);
      expect(moves.any((m) => m.toUci() == 'b1c3'), true);
    });
  });

  group('Position', () {
    test('makeMove returns new position', () {
      final pos = Position.initial();
      final newPos = pos.makeMoveUci('e2e4');

      expect(newPos, isNotNull);
      expect(newPos!.turn, Color.black);
      expect(newPos.board[Square.e4], whitePawn);
      expect(newPos.board[Square.e2], null);
      expect(newPos.enPassant, Square.e3);
    });

    test('makeMove returns null for illegal move', () {
      final pos = Position.initial();
      // Can't move king through pieces
      expect(pos.makeMoveUci('e1e3'), null);
    });

    test('after e4 e5, 20 moves for white', () {
      final pos = Position.initial()
          .makeMoveUci('e2e4')!
          .makeMoveUci('e7e5')!;

      expect(pos.legalMoves.length, 29); // More moves because center is open
    });

    test('FEN round-trip after moves', () {
      final pos = Position.initial()
          .makeMoveUci('e2e4')!
          .makeMoveUci('e7e5')!
          .makeMoveUci('g1f3')!;

      final fen = pos.toFen();
      final parsed = Position.fromFen(fen);
      expect(parsed, isNotNull);
      expect(parsed!.toFen(), fen);
    });
  });

  group('Captures', () {
    test('pawn can capture diagonally', () {
      final pos = Position.fromFen('8/8/8/3p4/4P3/8/8/8 w - - 0 1')!;
      final moves = pos.legalMoves;
      expect(moves.any((m) => m.toUci() == 'e4d5'), true); // Capture
      expect(moves.any((m) => m.toUci() == 'e4e5'), true); // Push
    });

    test('knight can capture', () {
      final pos = Position.fromFen('8/8/5p2/8/4N3/8/8/8 w - - 0 1')!;
      final moves = pos.legalMoves;
      expect(moves.any((m) => m.toUci() == 'e4f6'), true); // Capture pawn
    });
  });

  group('En passant', () {
    test('en passant capture is legal', () {
      // After 1. e4 e6 2. e5 d5, white can capture en passant
      final pos = Position.fromFen('rnbqkbnr/ppp2ppp/4p3/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3')!;
      final moves = pos.legalMoves;
      expect(moves.any((m) => m.toUci() == 'e5d6'), true);
    });

    test('en passant removes captured pawn', () {
      final pos = Position.fromFen('rnbqkbnr/ppp2ppp/4p3/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3')!;
      final newPos = pos.makeMoveUci('e5d6')!;

      expect(newPos.board[Square.d6], whitePawn);
      expect(newPos.board[Square.d5], null); // Captured pawn removed
      expect(newPos.board[Square.e5], null);
    });
  });

  group('Castling', () {
    test('kingside castling is legal', () {
      final pos = Position.fromFen('r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1')!;
      final moves = pos.legalMoves;
      expect(moves.any((m) => m.toUci() == 'e1g1'), true); // Kingside
      expect(moves.any((m) => m.toUci() == 'e1c1'), true); // Queenside
    });

    test('kingside castling moves rook', () {
      final pos = Position.fromFen('r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1')!;
      final newPos = pos.makeMoveUci('e1g1')!;

      expect(newPos.board[Square.g1], whiteKing);
      expect(newPos.board[Square.f1], whiteRook);
      expect(newPos.board[Square.e1], null);
      expect(newPos.board[Square.h1], null);
    });

    test('queenside castling moves rook', () {
      final pos = Position.fromFen('r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1')!;
      final newPos = pos.makeMoveUci('e1c1')!;

      expect(newPos.board[Square.c1], whiteKing);
      expect(newPos.board[Square.d1], whiteRook);
      expect(newPos.board[Square.e1], null);
      expect(newPos.board[Square.a1], null);
    });

    test('castling revokes castling rights', () {
      final pos = Position.fromFen('r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1')!;
      final newPos = pos.makeMoveUci('e1g1')!;

      expect(newPos.castling.whiteKingside, false);
      expect(newPos.castling.whiteQueenside, false);
      expect(newPos.castling.blackKingside, true);
      expect(newPos.castling.blackQueenside, true);
    });

    test('cannot castle through check', () {
      // Rook on f8 attacks f1, so white can't castle kingside
      final pos = Position.fromFen('5r2/8/8/8/8/8/8/R3K2R w KQ - 0 1')!;
      final moves = pos.legalMoves;
      expect(moves.any((m) => m.toUci() == 'e1g1'), false);
    });

    test('cannot castle out of check', () {
      final pos = Position.fromFen('4r3/8/8/8/8/8/8/R3K2R w KQ - 0 1')!;
      expect(pos.isCheck, true);
      final moves = pos.legalMoves;
      expect(moves.any((m) => m.toUci() == 'e1g1'), false);
      expect(moves.any((m) => m.toUci() == 'e1c1'), false);
    });

    test('cannot castle when blocked', () {
      final pos = Position.fromFen('r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R2QK2R w KQkq - 0 1')!;
      final moves = pos.legalMoves;
      expect(moves.any((m) => m.toUci() == 'e1c1'), false); // Blocked by queen
    });
  });

  group('Promotion', () {
    test('pawn promotion generates 4 moves', () {
      final pos = Position.fromFen('8/P7/8/8/8/8/8/8 w - - 0 1')!;
      final moves = pos.legalMoves;
      expect(moves.length, 4);
      expect(moves.any((m) => m.toUci() == 'a7a8q'), true);
      expect(moves.any((m) => m.toUci() == 'a7a8r'), true);
      expect(moves.any((m) => m.toUci() == 'a7a8b'), true);
      expect(moves.any((m) => m.toUci() == 'a7a8n'), true);
    });

    test('promotion changes piece type', () {
      final pos = Position.fromFen('8/P7/8/8/8/8/8/8 w - - 0 1')!;
      final newPos = pos.makeMoveUci('a7a8q')!;
      expect(newPos.board[Square.a8], whiteQueen);
    });

    test('capture promotion generates 4 moves', () {
      final pos = Position.fromFen('1n6/P7/8/8/8/8/8/8 w - - 0 1')!;
      final moves = pos.legalMoves;
      // 4 push promotions + 4 capture promotions = 8
      expect(moves.length, 8);
      expect(moves.any((m) => m.toUci() == 'a7b8q'), true);
    });
  });

  group('Check and checkmate', () {
    test('fool\'s mate is checkmate', () {
      final pos = Position.initial()
          .makeMoveUci('f2f3')!
          .makeMoveUci('e7e5')!
          .makeMoveUci('g2g4')!
          .makeMoveUci('d8h4')!;

      expect(pos.isCheck, true);
      expect(pos.isCheckmate, true);
      expect(pos.hasLegalMoves, false);
    });

    test('stalemate is detected', () {
      // Black king trapped in corner with no legal moves but not in check
      final pos = Position.fromFen('k7/2Q5/1K6/8/8/8/8/8 b - - 0 1')!;
      expect(pos.isCheck, false);
      expect(pos.isStalemate, true);
      expect(pos.hasLegalMoves, false);
    });

    test('check is detected', () {
      // Black king in check from rook, but can escape to b8
      final pos = Position.fromFen('k7/8/8/8/8/8/8/R3K3 b - - 0 1')!;
      expect(pos.isCheck, true);
      expect(pos.isCheckmate, false);
      expect(pos.hasLegalMoves, true);
    });

    test('cannot make move that leaves king in check', () {
      // Black king on h8, white bishop on a1, black pawn on d4 is pinned on the diagonal
      // Moving the pawn would expose king to check from the bishop
      final pos = Position.fromFen('7k/8/8/8/3p4/8/8/B3K3 b - - 0 1')!;
      final moves = pos.legalMoves;
      // d4 pawn is pinned on the diagonal and cannot move forward
      expect(moves.any((m) => m.from == Square.d4 && m.to == Square.d3), false);
      // King can still move
      expect(moves.any((m) => m.from == Square.h8), true);
    });
  });

  group('Halfmove clock and fullmove number', () {
    test('halfmove clock increments on quiet move', () {
      final pos = Position.initial();
      final newPos = pos.makeMoveUci('g1f3')!;
      expect(newPos.halfmoveClock, 1);
    });

    test('halfmove clock resets on pawn move', () {
      final pos = Position.initial()
          .makeMoveUci('g1f3')!
          .makeMoveUci('g8f6')!;
      expect(pos.halfmoveClock, 2);

      final afterPawn = pos.makeMoveUci('e2e4')!;
      expect(afterPawn.halfmoveClock, 0);
    });

    test('fullmove number increments after black move', () {
      final pos = Position.initial();
      expect(pos.fullmoveNumber, 1);

      final afterWhite = pos.makeMoveUci('e2e4')!;
      expect(afterWhite.fullmoveNumber, 1);

      final afterBlack = afterWhite.makeMoveUci('e7e5')!;
      expect(afterBlack.fullmoveNumber, 2);
    });
  });
}
