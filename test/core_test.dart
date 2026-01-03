import 'package:beechess/beechess.dart';
import 'package:test/test.dart';

void main() {
  group('Square', () {
    test('constants have correct indices', () {
      expect(Square.a1.index, 0);
      expect(Square.h1.index, 7);
      expect(Square.a8.index, 56);
      expect(Square.h8.index, 63);
      expect(Square.e4.index, 28);
    });

    test('rank and file are correct', () {
      expect(Square.a1.rank, 0);
      expect(Square.a1.file, 0);
      expect(Square.h8.rank, 7);
      expect(Square.h8.file, 7);
      expect(Square.e4.rank, 3);
      expect(Square.e4.file, 4);
    });

    test('algebraic notation is correct', () {
      expect(Square.a1.algebraic, 'a1');
      expect(Square.h8.algebraic, 'h8');
      expect(Square.e4.algebraic, 'e4');
      expect(Square.d5.algebraic, 'd5');
    });

    test('parse returns correct square', () {
      expect(Square.parse('a1'), Square.a1);
      expect(Square.parse('h8'), Square.h8);
      expect(Square.parse('e4'), Square.e4);
      expect(Square.parse('d5'), Square.d5);
    });

    test('parse returns null for invalid input', () {
      expect(Square.parse(''), null);
      expect(Square.parse('a'), null);
      expect(Square.parse('a9'), null);
      expect(Square.parse('i1'), null);
      expect(Square.parse('a0'), null);
    });

    test('parse/algebraic round-trip for all squares', () {
      for (final sq in Square.all) {
        expect(Square.parse(sq.algebraic), sq);
      }
    });

    test('shift returns correct square', () {
      expect(Square.e4.shift(1, 0), Square.e5);
      expect(Square.e4.shift(-1, 0), Square.e3);
      expect(Square.e4.shift(0, 1), Square.f4);
      expect(Square.e4.shift(0, -1), Square.d4);
      expect(Square.e4.shift(1, 1), Square.f5);
    });

    test('shift returns null at boundaries', () {
      expect(Square.a1.shift(-1, 0), null);
      expect(Square.a1.shift(0, -1), null);
      expect(Square.h8.shift(1, 0), null);
      expect(Square.h8.shift(0, 1), null);
    });

    test('light and dark squares are correct', () {
      // a1 is dark (rank 0 + file 0 = 0, even = dark)
      expect(Square.a1.isDark, true);
      expect(Square.a1.isLight, false);
      // a2 is light (rank 1 + file 0 = 1, odd = light)
      expect(Square.a2.isDark, false);
      expect(Square.a2.isLight, true);
      // h1 is light (rank 0 + file 7 = 7, odd = light)
      expect(Square.h1.isLight, true);
      // h8 is dark (rank 7 + file 7 = 14, even = dark)
      expect(Square.h8.isDark, true);
    });

    test('all contains 64 squares', () {
      expect(Square.all.length, 64);
    });
  });

  group('Color', () {
    test('opposite returns correct color', () {
      expect(Color.white.opposite, Color.black);
      expect(Color.black.opposite, Color.white);
      expect(Color.white.opposite.opposite, Color.white);
    });

    test('direction is correct', () {
      expect(Color.white.direction, 1);
      expect(Color.black.direction, -1);
    });

    test('backRank is correct', () {
      expect(Color.white.backRank, 0);
      expect(Color.black.backRank, 7);
    });

    test('pawnRank is correct', () {
      expect(Color.white.pawnRank, 1);
      expect(Color.black.pawnRank, 6);
    });

    test('promotionRank is correct', () {
      expect(Color.white.promotionRank, 7);
      expect(Color.black.promotionRank, 0);
    });

    test('index is correct', () {
      expect(Color.white.index, 0);
      expect(Color.black.index, 1);
    });

    test('fenChar is correct', () {
      expect(Color.white.fenChar, 'w');
      expect(Color.black.fenChar, 'b');
    });

    test('exhaustive pattern matching works', () {
      String describe(Color c) => switch (c) {
        White() => 'white',
        Black() => 'black',
      };
      expect(describe(Color.white), 'white');
      expect(describe(Color.black), 'black');
    });
  });

  group('Direction', () {
    test('cardinal directions are correct', () {
      expect(Direction.north.dr, 1);
      expect(Direction.north.df, 0);
      expect(Direction.south.dr, -1);
      expect(Direction.south.df, 0);
      expect(Direction.east.dr, 0);
      expect(Direction.east.df, 1);
      expect(Direction.west.dr, 0);
      expect(Direction.west.df, -1);
    });

    test('diagonal directions are correct', () {
      expect(Direction.northEast.dr, 1);
      expect(Direction.northEast.df, 1);
      expect(Direction.northWest.dr, 1);
      expect(Direction.northWest.df, -1);
    });

    test('rook has 4 directions', () {
      expect(Direction.rook.length, 4);
    });

    test('bishop has 4 directions', () {
      expect(Direction.bishop.length, 4);
    });

    test('queen has 8 directions', () {
      expect(Direction.queen.length, 8);
    });

    test('knight has 8 L-shapes', () {
      expect(Direction.knight.length, 8);
    });

    test('equality works', () {
      expect(Direction.north, const Direction(1, 0));
      expect(Direction.north, isNot(Direction.south));
    });
  });

  group('PieceType', () {
    test('all piece types exist', () {
      expect(PieceType.all.length, 6);
    });

    test('letters are correct', () {
      expect(PieceType.king.letter, 'K');
      expect(PieceType.queen.letter, 'Q');
      expect(PieceType.rook.letter, 'R');
      expect(PieceType.bishop.letter, 'B');
      expect(PieceType.knight.letter, 'N');
      expect(PieceType.pawn.letter, 'P');
    });

    test('values are correct', () {
      expect(PieceType.pawn.value, 100);
      expect(PieceType.knight.value, 320);
      expect(PieceType.bishop.value, 330);
      expect(PieceType.rook.value, 500);
      expect(PieceType.queen.value, 900);
      expect(PieceType.king.value, 20000);
    });

    test('isSliding is correct', () {
      expect(PieceType.king.isSliding, false);
      expect(PieceType.queen.isSliding, true);
      expect(PieceType.rook.isSliding, true);
      expect(PieceType.bishop.isSliding, true);
      expect(PieceType.knight.isSliding, false);
      expect(PieceType.pawn.isSliding, false);
    });

    test('fromLetter works', () {
      expect(PieceType.fromLetter('K'), PieceType.king);
      expect(PieceType.fromLetter('k'), PieceType.king);
      expect(PieceType.fromLetter('Q'), PieceType.queen);
      expect(PieceType.fromLetter('n'), PieceType.knight);
      expect(PieceType.fromLetter('X'), null);
    });

    test('indices are unique', () {
      final indices = PieceType.all.map((p) => p.index).toSet();
      expect(indices.length, 6);
    });
  });

  group('Piece', () {
    test('constants exist', () {
      expect(whiteKing.type, PieceType.king);
      expect(whiteKing.color, Color.white);
      expect(blackPawn.type, PieceType.pawn);
      expect(blackPawn.color, Color.black);
    });

    test('fenChar is correct', () {
      expect(whiteKing.fenChar, 'K');
      expect(blackKing.fenChar, 'k');
      expect(whitePawn.fenChar, 'P');
      expect(blackPawn.fenChar, 'p');
    });

    test('symbol is correct', () {
      expect(whiteKing.symbol, '♔');
      expect(blackKing.symbol, '♚');
      expect(whitePawn.symbol, '♙');
      expect(blackPawn.symbol, '♟');
    });

    test('fromFenChar works', () {
      expect(Piece.fromFenChar('K'), whiteKing);
      expect(Piece.fromFenChar('k'), blackKing);
      expect(Piece.fromFenChar('P'), whitePawn);
      expect(Piece.fromFenChar('p'), blackPawn);
      expect(Piece.fromFenChar('N'), whiteKnight);
      expect(Piece.fromFenChar('n'), blackKnight);
    });

    test('fromFenChar returns null for invalid', () {
      expect(Piece.fromFenChar(''), null);
      expect(Piece.fromFenChar('X'), null);
    });

    test('equality works', () {
      expect(const Piece(PieceType.king, Color.white), whiteKing);
      expect(whiteKing, isNot(blackKing));
      expect(whiteKing, isNot(whiteQueen));
    });

    test('all 12 piece/color combinations', () {
      for (final type in PieceType.all) {
        for (final color in [Color.white, Color.black]) {
          final piece = Piece(type, color);
          expect(Piece.fromFenChar(piece.fenChar), piece);
        }
      }
    });
  });

  group('Move', () {
    test('basic move construction', () {
      final move = Move(Square.e2, Square.e4);
      expect(move.from, Square.e2);
      expect(move.to, Square.e4);
      expect(move.promotion, null);
      expect(move.isPromotion, false);
    });

    test('promotion move construction', () {
      final move = Move(Square.a7, Square.a8, PieceType.queen);
      expect(move.from, Square.a7);
      expect(move.to, Square.a8);
      expect(move.promotion, PieceType.queen);
      expect(move.isPromotion, true);
    });

    test('toUci formats correctly', () {
      expect(Move(Square.e2, Square.e4).toUci(), 'e2e4');
      expect(Move(Square.g1, Square.f3).toUci(), 'g1f3');
      expect(Move(Square.a7, Square.a8, PieceType.queen).toUci(), 'a7a8q');
      expect(Move(Square.h7, Square.h8, PieceType.knight).toUci(), 'h7h8n');
    });

    test('parse works for standard moves', () {
      final move = Move.parse('e2e4');
      expect(move, isNotNull);
      expect(move!.from, Square.e2);
      expect(move.to, Square.e4);
      expect(move.promotion, null);
    });

    test('parse works for promotions', () {
      final move = Move.parse('a7a8q');
      expect(move, isNotNull);
      expect(move!.from, Square.a7);
      expect(move.to, Square.a8);
      expect(move.promotion, PieceType.queen);
    });

    test('parse returns null for invalid input', () {
      expect(Move.parse(''), null);
      expect(Move.parse('e2'), null);
      expect(Move.parse('e2e4e6'), null);
      expect(Move.parse('e9e4'), null);
      expect(Move.parse('e2e4k'), null);  // Can't promote to king
      expect(Move.parse('e2e4p'), null);  // Can't promote to pawn
    });

    test('parse/toUci round-trip', () {
      final moves = ['e2e4', 'g1f3', 'a7a8q', 'h2h1r', 'b7b8n', 'c2c1b'];
      for (final uci in moves) {
        final move = Move.parse(uci);
        expect(move, isNotNull);
        expect(move!.toUci(), uci);
      }
    });

    test('equality works', () {
      expect(Move(Square.e2, Square.e4), Move(Square.e2, Square.e4));
      expect(
        Move(Square.a7, Square.a8, PieceType.queen),
        Move(Square.a7, Square.a8, PieceType.queen),
      );
      expect(
        Move(Square.e2, Square.e4),
        isNot(Move(Square.e2, Square.e3)),
      );
      expect(
        Move(Square.a7, Square.a8, PieceType.queen),
        isNot(Move(Square.a7, Square.a8, PieceType.rook)),
      );
    });
  });
}
