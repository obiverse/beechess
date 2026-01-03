import 'package:beechess/beechess.dart';
import 'package:test/test.dart';

void main() {
  group('PGN parse', () {
    test('parses simple game', () {
      const pgn = '''
[Event "Test Game"]
[Site "Test Site"]
[Date "2024.01.01"]
[Round "1"]
[White "Player 1"]
[Black "Player 2"]
[Result "1-0"]

1. e4 e5 2. Nf3 Nc6 3. Bb5 1-0
''';

      final game = Pgn.parse(pgn);
      expect(game, isNotNull);
      expect(game!.event, 'Test Game');
      expect(game.site, 'Test Site');
      expect(game.date, '2024.01.01');
      expect(game.round, '1');
      expect(game.white, 'Player 1');
      expect(game.black, 'Player 2');
      expect(game.result, '1-0');
      expect(game.sanMoves, ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5']);
    });

    test('parses game with comments', () {
      const pgn = '''
[Event "Commented Game"]
[White "A"]
[Black "B"]
[Result "*"]

1. e4 {Best by test} e5 2. Nf3 Nc6 {Developing} *
''';

      final game = Pgn.parse(pgn);
      expect(game, isNotNull);
      expect(game!.sanMoves, ['e4', 'e5', 'Nf3', 'Nc6']);
    });

    test('parses game with variations', () {
      const pgn = '''
[Event "Variation Game"]
[White "A"]
[Black "B"]
[Result "*"]

1. e4 e5 (1... c5 2. Nf3 d6) 2. Nf3 *
''';

      final game = Pgn.parse(pgn);
      expect(game, isNotNull);
      expect(game!.sanMoves, ['e4', 'e5', 'Nf3']);
    });

    test('parses game with NAGs', () {
      const pgn = '''
[Event "NAG Game"]
[White "A"]
[Black "B"]
[Result "*"]

1. e4! e5? 2. Nf3!! Nc6?! *
''';

      final game = Pgn.parse(pgn);
      expect(game, isNotNull);
      // NAGs like ! and ? are part of the move token
      expect(game!.sanMoves.length, 4);
    });

    test('parses famous game - Immortal Game', () {
      const pgn = '''
[Event "London"]
[Site "London"]
[Date "1851.??.??"]
[Round "?"]
[White "Anderssen, Adolf"]
[Black "Kieseritzky, Lionel"]
[Result "1-0"]

1. e4 e5 2. f4 exf4 3. Bc4 Qh4+ 4. Kf1 b5 5. Bxb5 Nf6 6. Nf3 Qh6 7. d3 Nh5
8. Nh4 Qg5 9. Nf5 c6 10. g4 Nf6 11. Rg1 cxb5 12. h4 Qg6 13. h5 Qg5 14. Qf3
Ng8 15. Bxf4 Qf6 16. Nc3 Bc5 17. Nd5 Qxb2 18. Bd6 Bxg1 19. e5 Qxa1+ 20. Ke2
Na6 21. Nxg7+ Kd8 22. Qf6+ Nxf6 23. Be7# 1-0
''';

      final game = Pgn.parse(pgn);
      expect(game, isNotNull);
      expect(game!.white, 'Anderssen, Adolf');
      expect(game.black, 'Kieseritzky, Lionel');
      expect(game.result, '1-0');
      expect(game.sanMoves.length, 45);
    });

    test('handles missing headers gracefully', () {
      const pgn = '1. e4 e5 2. Nf3 *';

      final game = Pgn.parse(pgn);
      expect(game, isNotNull);
      expect(game!.event, '?');
      expect(game.white, '?');
      expect(game.sanMoves, ['e4', 'e5', 'Nf3']);
    });

    test('parses draw result', () {
      const pgn = '''
[Result "1/2-1/2"]

1. e4 e5 2. Nf3 Nf6 1/2-1/2
''';

      final game = Pgn.parse(pgn);
      expect(game, isNotNull);
      expect(game!.result, '1/2-1/2');
    });
  });

  group('PGN parseMany', () {
    test('parses multiple games', () {
      const pgn = '''
[Event "Game 1"]
[White "A"]
[Black "B"]
[Result "1-0"]

1. e4 1-0

[Event "Game 2"]
[White "C"]
[Black "D"]
[Result "0-1"]

1. d4 0-1
''';

      final games = Pgn.parseMany(pgn);
      expect(games.length, 2);
      expect(games[0].event, 'Game 1');
      expect(games[1].event, 'Game 2');
    });
  });

  group('PGN replay', () {
    test('replays simple game', () {
      const pgn = '''
[Event "Test"]
[White "A"]
[Black "B"]
[Result "*"]

1. e4 e5 2. Nf3 Nc6 *
''';

      final pgnGame = Pgn.parse(pgn)!;
      final game = Pgn.replay(pgnGame);

      expect(game, isNotNull);
      expect(game!.moves.length, 4);
      expect(game.position.turn, Color.white);
    });

    test('returns null for invalid move', () {
      const pgn = '''
[Event "Invalid"]
[Result "*"]

1. e4 Ke7 *
''';

      final pgnGame = Pgn.parse(pgn)!;
      final game = Pgn.replay(pgnGame);
      expect(game, isNull);
    });
  });

  group('PGN format', () {
    test('formats empty game', () {
      final game = Game.initial();
      final pgn = Pgn.format(game);

      expect(pgn, contains('[Event "?"]'));
      expect(pgn, contains('[White "?"]'));
      expect(pgn, contains('[Result "*"]'));
      expect(pgn, endsWith('*'));
    });

    test('formats game with moves', () {
      var game = Game.initial();
      game = game.makeMoveUci('e2e4')!;
      game = game.makeMoveUci('e7e5')!;
      game = game.makeMoveUci('g1f3')!;

      final pgn = Pgn.format(game, headers: {
        'Event': 'Test Event',
        'White': 'White Player',
        'Black': 'Black Player',
      });

      expect(pgn, contains('[Event "Test Event"]'));
      expect(pgn, contains('[White "White Player"]'));
      expect(pgn, contains('1. e4 e5 2. Nf3'));
    });

    test('formats game with custom headers', () {
      final game = Game.initial();
      final pgn = Pgn.format(game, headers: {
        'Event': 'World Championship',
        'Site': 'New York',
        'ECO': 'C00',
      });

      expect(pgn, contains('[Event "World Championship"]'));
      expect(pgn, contains('[Site "New York"]'));
      expect(pgn, contains('[ECO "C00"]'));
    });
  });

  group('PGN round-trip', () {
    test('format then parse preserves moves', () {
      var game = Game.initial();
      game = game.makeMoveUci('e2e4')!;
      game = game.makeMoveUci('e7e5')!;
      game = game.makeMoveUci('g1f3')!;
      game = game.makeMoveUci('b8c6')!;
      game = game.makeMoveUci('f1b5')!;

      final pgn = Pgn.format(game, headers: {'Event': 'Ruy Lopez'});
      final parsed = Pgn.parse(pgn)!;
      final replayed = Pgn.replay(parsed)!;

      expect(replayed.moves.length, game.moves.length);
      for (var i = 0; i < game.moves.length; i++) {
        expect(replayed.moves[i].toUci(), game.moves[i].toUci());
      }
    });
  });
}
