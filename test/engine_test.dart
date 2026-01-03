import 'package:beechess/beechess.dart';
import 'package:test/test.dart';

void main() {
  group('Evaluator', () {
    test('initial position is roughly equal', () {
      final pos = Position.initial();
      final score = Evaluator.evaluate(pos);
      // Initial position should be close to 0 (symmetric)
      expect(score.abs(), lessThan(50));
    });

    test('material advantage is detected', () {
      // White up a queen
      final pos = Position.fromFen('rnb1kbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')!;
      final score = Evaluator.evaluate(pos);
      // Should be positive (white advantage) and roughly a queen's value
      expect(score, greaterThan(800));
    });

    test('black advantage is negative', () {
      // Black up a queen
      final pos = Position.fromFen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNB1KBNR w KQkq - 0 1')!;
      final score = Evaluator.evaluate(pos);
      // Should be negative (black advantage)
      expect(score, lessThan(-800));
    });

    test('checkmate is detected', () {
      // Fool's mate position - white is checkmated
      final pos = Position.fromFen('rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 0 1')!;
      // This is white to move and white is in checkmate
      expect(pos.isCheckmate, true);
      final score = Evaluator.evaluate(pos);
      expect(score, equals(-Evaluator.mateScore));
    });

    test('stalemate is zero', () {
      final pos = Position.fromFen('k7/2Q5/1K6/8/8/8/8/8 b - - 0 1')!;
      expect(pos.isStalemate, true);
      final score = Evaluator.evaluate(pos);
      expect(score, 0);
    });

    test('center pawns are valued higher', () {
      // Pawn on e4 vs pawn on a4
      final centerPawn = Position.fromFen('8/8/8/8/4P3/8/8/4K2k w - - 0 1')!;
      final edgePawn = Position.fromFen('8/8/8/8/P7/8/8/4K2k w - - 0 1')!;

      final centerScore = Evaluator.evaluate(centerPawn);
      final edgeScore = Evaluator.evaluate(edgePawn);

      expect(centerScore, greaterThan(edgeScore));
    });

    test('knights prefer center', () {
      // Knight on e4 vs knight on a1
      final centerKnight = Position.fromFen('8/8/8/8/4N3/8/8/4K2k w - - 0 1')!;
      final cornerKnight = Position.fromFen('N7/8/8/8/8/8/8/4K2k w - - 0 1')!;

      final centerScore = Evaluator.evaluate(centerKnight);
      final cornerScore = Evaluator.evaluate(cornerKnight);

      expect(centerScore, greaterThan(cornerScore));
    });
  });

  group('Perft', () {
    test('initial position depth 0', () {
      final pos = Position.initial();
      expect(Perft.perft(pos, 0), 1);
    });

    test('initial position depth 1', () {
      final pos = Position.initial();
      expect(Perft.perft(pos, 1), 20);
    });

    test('initial position depth 2', () {
      final pos = Position.initial();
      expect(Perft.perft(pos, 2), 400);
    });

    test('initial position depth 3', () {
      final pos = Position.initial();
      expect(Perft.perft(pos, 3), 8902);
    });

    // Depth 4 takes ~1 second, good for CI
    test('initial position depth 4', () {
      final pos = Position.initial();
      expect(Perft.perft(pos, 4), 197281);
    }, timeout: Timeout(Duration(seconds: 10)));

    test('divide produces correct total', () {
      final pos = Position.initial();
      final divided = Perft.divide(pos, 2);

      // Should have 20 entries (one per first move)
      expect(divided.length, 20);

      // Sum should equal perft(2)
      final total = divided.values.fold(0, (a, b) => a + b);
      expect(total, 400);
    });

    test('kiwipete position depth 1', () {
      final pos = Position.fromFen(
        'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -',
      )!;
      expect(Perft.perft(pos, 1), 48);
    });

    test('kiwipete position depth 2', () {
      final pos = Position.fromFen(
        'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -',
      )!;
      expect(Perft.perft(pos, 2), 2039);
    });

    test('position 3 (en passant focus) depth 1', () {
      final pos = Position.fromFen('8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - -')!;
      expect(Perft.perft(pos, 1), 14);
    });

    test('position 3 depth 2', () {
      final pos = Position.fromFen('8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - -')!;
      expect(Perft.perft(pos, 2), 191);
    });

    test('position 3 depth 3', () {
      final pos = Position.fromFen('8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - -')!;
      expect(Perft.perft(pos, 3), 2812);
    });

    test('position 4 (castling focus) depth 1', () {
      final pos = Position.fromFen(
        'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq -',
      )!;
      expect(Perft.perft(pos, 1), 6);
    });

    test('position 4 depth 2', () {
      final pos = Position.fromFen(
        'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq -',
      )!;
      expect(Perft.perft(pos, 2), 264);
    });
  });
}
