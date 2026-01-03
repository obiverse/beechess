import 'package:beechess/beechess.dart';
import 'package:test/test.dart';

void main() {
  group('Scroll', () {
    test('Position toScroll contains correct data', () {
      final pos = Position.initial();
      final scroll = pos.toScroll('game123');

      expect(scroll.key, '/arena/games/game123/position');
      expect(scroll.type, 'chess/position@v1');
      expect(scroll.data['fen'], pos.toFen());
      expect(scroll.data['turn'], 'w');
      expect(scroll.data['moveNumber'], 1);
      expect(scroll.data['isCheck'], false);
      expect(scroll.data['isCheckmate'], false);
    });

    test('Position fromScroll reconstructs position', () {
      final original = Position.initial();
      final scroll = original.toScroll('test');
      final reconstructed = PositionScroll.fromScroll(scroll);

      expect(reconstructed, isNotNull);
      expect(reconstructed!.toFen(), original.toFen());
    });

    test('Move toScrollData contains UCI', () {
      final move = Move.parse('e2e4')!;
      final data = move.toScrollData();

      expect(data['uci'], 'e2e4');
      expect(data['from'], 'e2');
      expect(data['to'], 'e4');
    });

    test('Move fromScrollData parses correctly', () {
      final data = {'uci': 'g1f3', 'from': 'g1', 'to': 'f3'};
      final move = MoveScroll.fromScrollData(data);

      expect(move, isNotNull);
      expect(move!.toUci(), 'g1f3');
    });

    test('Game toScroll contains moves and result', () {
      var game = Game.initial();
      game = game.makeMoveUci('e2e4')!;
      game = game.makeMoveUci('e7e5')!;

      final scroll = game.toScroll('game456');

      expect(scroll.key, '/arena/games/game456');
      expect(scroll.type, 'chess/game@v1');
      expect(scroll.data['moves'], ['e2e4', 'e7e5']);
      expect(scroll.data['plyCount'], 2);
      expect(scroll.data['result'], 'ongoing');
    });
  });

  group('ChessGameNamespace', () {
    late ChessGameNamespace ns;

    setUp(() {
      ns = ChessGameNamespace(
        gameId: 'test-game',
        whitePubkey: 'npub1white...',
        blackPubkey: 'npub1black...',
      );
    });

    test('read /position returns current position', () {
      final result = ns.read('/position');
      expect(result, isA<Ok<Scroll?>>());

      final scroll = (result as Ok<Scroll?>).value!;
      expect(scroll.data['turn'], 'w');
      expect(scroll.data['moveNumber'], 1);
    });

    test('read /fen returns FEN string', () {
      final result = ns.read('/fen');
      expect(result, isA<Ok<Scroll?>>());

      final scroll = (result as Ok<Scroll?>).value!;
      expect(scroll.data['fen'], contains('rnbqkbnr'));
    });

    test('write /move makes a move', () {
      final result = ns.write('/move', {'uci': 'e2e4'});
      expect(result, isA<Ok<Scroll>>());

      final scroll = (result as Ok<Scroll>).value;
      expect(scroll.data['turn'], 'b'); // Now black's turn
    });

    test('write /move rejects illegal move', () {
      final result = ns.write('/move', {'uci': 'e1e3'});
      expect(result, isA<Err<Scroll>>());
      expect((result as Err<Scroll>).error, isA<IllegalMoveError>());
    });

    test('write /reset resets game', () {
      ns.write('/move', {'uci': 'e2e4'});
      ns.write('/reset', {});

      final result = ns.read('/position');
      final scroll = (result as Ok<Scroll?>).value!;
      expect(scroll.data['turn'], 'w');
      expect(ns.game.plyCount, 0);
    });

    test('write /fen sets position', () {
      ns.write('/fen', {'fen': 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1'});

      final result = ns.read('/position');
      final scroll = (result as Ok<Scroll?>).value!;
      expect(scroll.data['turn'], 'b');
    });

    test('read /pgn returns PGN format', () {
      ns.write('/move', {'uci': 'e2e4'});
      ns.write('/move', {'uci': 'e7e5'});

      final result = ns.read('/pgn');
      final scroll = (result as Ok<Scroll?>).value!;
      expect(scroll.data['pgn'], contains('1. e4 e5'));
    });

    test('read /meta returns game metadata', () {
      final result = ns.read('/meta');
      final scroll = (result as Ok<Scroll?>).value!;
      expect(scroll.data['gameId'], 'test-game');
      expect(scroll.data['white'], 'npub1white...');
      expect(scroll.data['black'], 'npub1black...');
    });

    test('list / returns all paths', () {
      final result = ns.list('/');
      expect(result, isA<Ok<List<String>>>());

      final paths = (result as Ok<List<String>>).value;
      expect(paths, contains('/position'));
      expect(paths, contains('/moves'));
      expect(paths, contains('/fen'));
      expect(paths, contains('/pgn'));
    });

    test('read unknown path returns NotFoundError', () {
      final result = ns.read('/unknown');
      expect(result, isA<Err<Scroll?>>());
      expect((result as Err<Scroll?>).error, isA<NotFoundError>());
    });
  });

  group('TimeControl', () {
    test('preset time controls have correct values', () {
      expect(TimeControl.bullet1_0.initialSecs, 60);
      expect(TimeControl.bullet1_0.incrementSecs, 0);
      expect(TimeControl.blitz5_3.initialSecs, 300);
      expect(TimeControl.blitz5_3.incrementSecs, 3);
    });

    test('name format is correct', () {
      expect(TimeControl.bullet1_0.name, '1+0');
      expect(TimeControl.blitz5_3.name, '5+3');
      expect(TimeControl.rapid15_10.name, '15+10');
    });

    test('category is correct', () {
      expect(TimeControl.bullet1_0.category, 'bullet');
      expect(TimeControl.blitz5_0.category, 'blitz');
      expect(TimeControl.rapid10_0.category, 'rapid');
      expect(TimeControl.classical30_0.category, 'classical');
    });
  });

  group('GameClock', () {
    late GameClock clock;

    setUp(() {
      clock = GameClock(TimeControl.blitz5_0);
    });

    test('initial time is correct', () {
      expect(clock.whiteTimeMs, 300000);
      expect(clock.blackTimeMs, 300000);
      expect(clock.isRunning, false);
    });

    test('start sets running clock', () {
      clock.start(Color.white);
      expect(clock.isRunning, true);
      expect(clock.running, Color.white);
    });

    test('stop halts clock', () {
      clock.start(Color.white);
      clock.stop();
      expect(clock.isRunning, false);
      expect(clock.running, isNull);
    });

    test('switchClock changes side and adds increment', () {
      final clockWithIncrement = GameClock(TimeControl.blitz5_3);
      clockWithIncrement.start(Color.white);

      // Simulate some time passing (not actually waiting)
      clockWithIncrement.switchClock();

      expect(clockWithIncrement.running, Color.black);
      // White got increment
      expect(clockWithIncrement.whiteTimeMs, greaterThanOrEqualTo(300000));
    });

    test('formatTime shows correct format', () {
      expect(clock.formatTime(Color.white), '5:00');

      clock.whiteTimeMs = 65000; // 1:05
      expect(clock.formatTime(Color.white), '1:05');

      clock.whiteTimeMs = 5500; // 5.5 seconds (low time format)
      expect(clock.formatTime(Color.white), '0:05.5');
    });

    test('isFlagged detects timeout', () {
      expect(clock.isFlagged(Color.white), false);

      clock.whiteTimeMs = 0;
      expect(clock.isFlagged(Color.white), true);
    });

    test('reset restores initial time', () {
      clock.whiteTimeMs = 1000;
      clock.blackTimeMs = 2000;
      clock.start(Color.white);

      clock.reset();

      expect(clock.whiteTimeMs, 300000);
      expect(clock.blackTimeMs, 300000);
      expect(clock.isRunning, false);
    });

    test('addTime adjusts time', () {
      clock.addTime(Color.white, 10000);
      expect(clock.whiteTimeMs, 310000);

      clock.addTime(Color.black, -5000);
      expect(clock.blackTimeMs, 295000);
    });
  });
}
