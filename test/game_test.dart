import 'package:beechess/beechess.dart';
import 'package:test/test.dart';

void main() {
  group('Game', () {
    test('initial game has correct state', () {
      final game = Game.initial();
      expect(game.plyCount, 0);
      expect(game.moveNumber, 1);
      expect(game.position.turn, Color.white);
      expect(game.lastMove, null);
    });

    test('makeMove updates state', () {
      final game = Game.initial();
      final newGame = game.makeMoveUci('e2e4')!;

      expect(newGame.plyCount, 1);
      expect(newGame.position.turn, Color.black);
      expect(newGame.lastMove?.toUci(), 'e2e4');
      expect(game.plyCount, 0); // Original unchanged
    });

    test('makeMove returns null for illegal move', () {
      final game = Game.initial();
      expect(game.makeMoveUci('e1e3'), null);
    });

    test('fromFen creates game from position', () {
      final game = Game.fromFen('rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2');
      expect(game, isNotNull);
      expect(game!.position.turn, Color.white);
      expect(game.moveNumber, 2);
    });

    test('fromFen returns null for invalid FEN', () {
      expect(Game.fromFen('invalid'), null);
    });

    test('game result is ongoing for new game', () {
      final game = Game.initial();
      expect(game.result, GameResult.ongoing);
      expect(game.isGameOver, false);
    });

    test('game result is whiteWins for black checkmate', () {
      // Scholar's mate position - black is checkmated, white wins
      final game = Game.fromFen('r1bqkb1r/pppp1Qpp/2n2n2/4p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4')!;
      expect(game.position.isCheckmate, true);
      expect(game.result, GameResult.whiteWins); // Black is checkmated = white wins
    });

    test('game result is draw for stalemate', () {
      final game = Game.fromFen('k7/2Q5/1K6/8/8/8/8/8 b - - 0 1')!;
      expect(game.position.isStalemate, true);
      expect(game.result, GameResult.draw);
    });
  });

  group('Threefold repetition', () {
    test('not threefold with fresh game', () {
      final game = Game.initial();
      expect(game.isThreefoldRepetition, false);
    });

    test('detects threefold repetition', () {
      // Move knights back and forth to repeat position
      var game = Game.initial();

      // Position 1 (initial)
      // 1. Nf3 Nf6
      game = game.makeMoveUci('g1f3')!;
      game = game.makeMoveUci('g8f6')!;
      // 2. Ng1 Ng8 (back to initial-like position, but with different move rights)
      game = game.makeMoveUci('f3g1')!;
      game = game.makeMoveUci('f6g8')!;
      // Position 2

      // 3. Nf3 Nf6
      game = game.makeMoveUci('g1f3')!;
      game = game.makeMoveUci('g8f6')!;
      // 4. Ng1 Ng8
      game = game.makeMoveUci('f3g1')!;
      game = game.makeMoveUci('f6g8')!;
      // Position 3 - threefold!

      expect(game.isThreefoldRepetition, true);
    });
  });

  group('Fifty move rule', () {
    test('not fifty moves at start', () {
      final game = Game.initial();
      expect(game.isFiftyMoveRule, false);
    });

    test('detects fifty move rule', () {
      // Create position with halfmove clock at 100
      final game = Game.fromFen('8/8/8/8/8/8/8/4K2k w - - 100 50')!;
      expect(game.isFiftyMoveRule, true);
    });
  });

  group('Zobrist', () {
    test('same position has same hash', () {
      final game1 = Game.initial();
      final game2 = Game.initial();

      expect(game1.positionHashes.last, game2.positionHashes.last);
    });

    test('different positions have different hashes', () {
      final game1 = Game.initial();
      final game2 = game1.makeMoveUci('e2e4')!;

      expect(game1.positionHashes.last, isNot(game2.positionHashes.last));
    });

    test('transposition has same hash', () {
      // Use a sequence where no en passant is involved
      // 1. Nc3 Nc6 2. Nf3
      final game1 = Game.initial()
          .makeMoveUci('b1c3')!
          .makeMoveUci('b8c6')!
          .makeMoveUci('g1f3')!;

      // 1. Nf3 Nc6 2. Nc3
      final game2 = Game.initial()
          .makeMoveUci('g1f3')!
          .makeMoveUci('b8c6')!
          .makeMoveUci('b1c3')!;

      // Same position reached via different move orders (no ep differences)
      expect(game1.positionHashes.last, game2.positionHashes.last);
    });
  });

  group('Search', () {
    test('finds mate in 1', () {
      // White to move, Qh7# is mate
      final pos = Position.fromFen('r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 0 4')!;
      final result = Search.search(pos, 2);

      expect(result.bestMove, isNotNull);
      // The move should be a winning move (high positive score)
      expect(result.score, greaterThan(Evaluator.mateScore - 100));
    });

    test('finds capture of hanging piece', () {
      // White knight can take undefended black rook
      // Simple position with no tricks
      final pos = Position.fromFen('8/8/3r4/8/4N3/8/8/K6k w - - 0 1')!;
      final result = Search.search(pos, 1);

      expect(result.bestMove?.toUci(), 'e4d6'); // Take the rook
    });

    test('search returns valid move from initial position', () {
      final pos = Position.initial();
      final result = Search.search(pos, 2);

      expect(result.bestMove, isNotNull);
      expect(pos.legalMoves.contains(result.bestMove), true);
    });

    test('iterative deepening yields results', () {
      final pos = Position.initial();
      final results = Search.iterativeDeepening(pos, maxDepth: 3).toList();

      expect(results.length, greaterThanOrEqualTo(1));
      expect(results.last.bestMove, isNotNull);
    });

    test('move ordering prioritizes captures', () {
      // Position where there's a capture available (no mate)
      final pos = Position.fromFen('8/8/8/3p4/4P3/8/4K3/7k w - - 0 1')!;
      final result = Search.search(pos, 1);

      // Should find the capture
      expect(result.bestMove?.toUci(), 'e4d5');
    });
  });
}
