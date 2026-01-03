import 'package:beechess/beechess.dart';
import 'package:test/test.dart';

void main() {
  group('SAN format', () {
    test('formats simple pawn move', () {
      final pos = Position.initial();
      final move = Move.parse('e2e4')!;
      expect(San.format(move, pos), 'e4');
    });

    test('formats knight move', () {
      final pos = Position.initial();
      final move = Move.parse('g1f3')!;
      expect(San.format(move, pos), 'Nf3');
    });

    test('formats capture', () {
      final pos = Position.fromFen('rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2')!;
      final move = Move.parse('e4d5')!;
      expect(San.format(move, pos), 'exd5');
    });

    test('formats piece capture', () {
      final pos = Position.fromFen('rnbqkbnr/ppp1pppp/8/3p4/2B1P3/8/PPPP1PPP/RNBQK1NR w KQkq - 0 2')!;
      final move = Move.parse('c4d5')!;
      expect(San.format(move, pos), 'Bxd5');
    });

    test('formats kingside castling', () {
      final pos = Position.fromFen('r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4')!;
      final move = Move.parse('e1g1')!;
      expect(San.format(move, pos), 'O-O');
    });

    test('formats queenside castling', () {
      final pos = Position.fromFen('r3kbnr/pppqpppp/2n5/3p1b2/3P1B2/2N5/PPPQPPPP/R3KBNR w KQkq - 6 5')!;
      final move = Move.parse('e1c1')!;
      expect(San.format(move, pos), 'O-O-O');
    });

    test('formats promotion', () {
      // Position where promotion doesn't give check
      final pos = Position.fromFen('8/P7/8/8/8/8/7k/4K3 w - - 0 1')!;
      final move = Move.parse('a7a8q')!;
      expect(San.format(move, pos), 'a8=Q');
    });

    test('formats promotion with capture', () {
      final pos = Position.fromFen('1n6/P7/8/8/8/8/8/4K2k w - - 0 1')!;
      final move = Move.parse('a7b8q')!;
      expect(San.format(move, pos), 'axb8=Q');
    });

    test('formats check', () {
      final pos = Position.fromFen('4k3/8/8/8/8/8/8/4K2R w - - 0 1')!;
      final move = Move.parse('h1h8')!;
      expect(San.format(move, pos), 'Rh8+');
    });

    test('formats checkmate', () {
      // Scholar's mate position - Qxf7#
      final pos = Position.fromFen('r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4')!;
      final move = Move.parse('h5f7')!;
      expect(San.format(move, pos), 'Qxf7#');
    });

    test('formats knight disambiguation by file', () {
      // Two knights can reach same square d2: Na1 and Nc1
      final pos = Position.fromFen('8/8/8/8/8/8/8/N1N1K2k w - - 0 1')!;
      final move = Move.parse('a1b3')!;
      expect(San.format(move, pos), 'Nab3');
    });

    test('formats rook disambiguation by rank', () {
      // Two rooks can reach same square, different ranks
      final pos = Position.fromFen('R7/8/8/8/8/8/8/R3K2k w - - 0 1')!;
      final move = Move.parse('a1a4')!;
      expect(San.format(move, pos), 'R1a4');
    });
  });

  group('SAN parse', () {
    test('parses simple pawn move', () {
      final pos = Position.initial();
      final move = San.parse('e4', pos);
      expect(move?.toUci(), 'e2e4');
    });

    test('parses knight move', () {
      final pos = Position.initial();
      final move = San.parse('Nf3', pos);
      expect(move?.toUci(), 'g1f3');
    });

    test('parses capture', () {
      final pos = Position.fromFen('rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2')!;
      final move = San.parse('exd5', pos);
      expect(move?.toUci(), 'e4d5');
    });

    test('parses piece capture', () {
      final pos = Position.fromFen('rnbqkbnr/ppp1pppp/8/3p4/2B1P3/8/PPPP1PPP/RNBQK1NR w KQkq - 0 2')!;
      final move = San.parse('Bxd5', pos);
      expect(move?.toUci(), 'c4d5');
    });

    test('parses kingside castling O-O', () {
      final pos = Position.fromFen('r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4')!;
      final move = San.parse('O-O', pos);
      expect(move?.toUci(), 'e1g1');
    });

    test('parses kingside castling 0-0', () {
      final pos = Position.fromFen('r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4')!;
      final move = San.parse('0-0', pos);
      expect(move?.toUci(), 'e1g1');
    });

    test('parses queenside castling O-O-O', () {
      final pos = Position.fromFen('r3kbnr/pppqpppp/2n5/3p1b2/3P1B2/2N5/PPPQPPPP/R3KBNR w KQkq - 6 5')!;
      final move = San.parse('O-O-O', pos);
      expect(move?.toUci(), 'e1c1');
    });

    test('parses promotion', () {
      final pos = Position.fromFen('8/P7/8/8/8/8/8/4K2k w - - 0 1')!;
      final move = San.parse('a8=Q', pos);
      expect(move?.toUci(), 'a7a8q');
    });

    test('parses promotion with capture', () {
      final pos = Position.fromFen('1n6/P7/8/8/8/8/8/4K2k w - - 0 1')!;
      final move = San.parse('axb8=Q', pos);
      expect(move?.toUci(), 'a7b8q');
    });

    test('parses with check indicator', () {
      final pos = Position.fromFen('4k3/8/8/8/8/8/8/4K2R w - - 0 1')!;
      final move = San.parse('Rh8+', pos);
      expect(move?.toUci(), 'h1h8');
    });

    test('parses with checkmate indicator', () {
      final pos = Position.fromFen('r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4')!;
      final move = San.parse('Qxf7#', pos);
      expect(move?.toUci(), 'h5f7');
    });

    test('parses knight disambiguation by file', () {
      final pos = Position.fromFen('8/8/8/8/8/8/8/N1N1K2k w - - 0 1')!;
      final move = San.parse('Nab3', pos);
      expect(move?.toUci(), 'a1b3');
    });

    test('parses rook disambiguation by rank', () {
      final pos = Position.fromFen('R7/8/8/8/8/8/8/R3K2k w - - 0 1')!;
      final move = San.parse('R1a4', pos);
      expect(move?.toUci(), 'a1a4');
    });

    test('returns null for invalid SAN', () {
      final pos = Position.initial();
      expect(San.parse('Xyz', pos), null);
      expect(San.parse('', pos), null);
      expect(San.parse('e9', pos), null);
    });

    test('returns null for illegal move', () {
      final pos = Position.initial();
      expect(San.parse('e5', pos), null); // Can't move pawn 3 squares
      expect(San.parse('Ke2', pos), null); // Can't move king yet
    });
  });

  group('SAN round-trip', () {
    test('format then parse returns same move', () {
      final pos = Position.initial();
      final originalMove = Move.parse('e2e4')!;

      final san = San.format(originalMove, pos);
      final parsedMove = San.parse(san, pos);

      expect(parsedMove, originalMove);
    });

    test('round-trip works for various moves', () {
      final testCases = [
        ('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1', 'e2e4'),
        ('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1', 'g1f3'),
        ('rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2', 'e4d5'),
        ('r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'e1g1'),
        ('8/P7/8/8/8/8/8/4K2k w - - 0 1', 'a7a8q'),
      ];

      for (final (fen, uci) in testCases) {
        final pos = Position.fromFen(fen)!;
        final originalMove = Move.parse(uci)!;
        final san = San.format(originalMove, pos);
        final parsedMove = San.parse(san, pos);
        expect(parsedMove, originalMove, reason: 'Round-trip failed for $uci (SAN: $san)');
      }
    });
  });
}
