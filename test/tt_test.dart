import 'package:beechess/beechess.dart';
import 'package:test/test.dart';

void main() {
  group('TranspositionTable', () {
    late TranspositionTable tt;

    setUp(() {
      tt = TranspositionTable(sizeMB: 1); // Small table for testing
    });

    test('stores and retrieves entry', () {
      tt.store(
        hash: 12345,
        move: Move.parse('e2e4'),
        score: 100,
        depth: 5,
        type: ScoreType.exact,
      );

      final entry = tt.probe(12345);
      expect(entry, isNotNull);
      expect(entry!.hash, 12345);
      expect(entry.score, 100);
      expect(entry.depth, 5);
      expect(entry.type, ScoreType.exact);
      expect(entry.move?.toUci(), 'e2e4');
    });

    test('returns null for missing entry', () {
      final entry = tt.probe(99999);
      expect(entry, isNull);
    });

    test('deeper search replaces shallower', () {
      tt.store(
        hash: 12345,
        score: 50,
        depth: 3,
        type: ScoreType.exact,
      );

      tt.store(
        hash: 12345,
        score: 100,
        depth: 5,
        type: ScoreType.exact,
      );

      final entry = tt.probe(12345);
      expect(entry!.depth, 5);
      expect(entry.score, 100);
    });

    test('shallower search does not replace deeper', () {
      tt.store(
        hash: 12345,
        score: 100,
        depth: 5,
        type: ScoreType.exact,
      );

      tt.store(
        hash: 12345,
        score: 50,
        depth: 3,
        type: ScoreType.exact,
      );

      final entry = tt.probe(12345);
      expect(entry!.depth, 5);
      expect(entry.score, 100);
    });

    test('clear removes all entries', () {
      tt.store(hash: 1, score: 10, depth: 1, type: ScoreType.exact);
      tt.store(hash: 2, score: 20, depth: 2, type: ScoreType.exact);

      tt.clear();

      expect(tt.probe(1), isNull);
      expect(tt.probe(2), isNull);
    });

    test('tracks hit statistics', () {
      tt.store(hash: 12345, score: 100, depth: 5, type: ScoreType.exact);

      tt.probe(12345); // Hit
      tt.probe(12345); // Hit
      tt.probe(99999); // Miss

      expect(tt.hits, 2);
      expect(tt.misses, 1);
      expect(tt.hitRate, closeTo(66.67, 1));
    });

    test('handles all score types', () {
      tt.store(
        hash: 1,
        score: 100,
        depth: 3,
        type: ScoreType.lowerBound,
      );
      expect(tt.probe(1)!.type, ScoreType.lowerBound);

      tt.store(
        hash: 2,
        score: 50,
        depth: 3,
        type: ScoreType.upperBound,
      );
      expect(tt.probe(2)!.type, ScoreType.upperBound);

      tt.store(
        hash: 3,
        score: 75,
        depth: 3,
        type: ScoreType.exact,
      );
      expect(tt.probe(3)!.type, ScoreType.exact);
    });
  });

  group('Search with TT', () {
    setUp(() {
      Search.clearTT();
    });

    test('TT is accessible', () {
      expect(Search.transpositionTable, isNotNull);
      expect(Search.transpositionTable.size, greaterThan(0));
    });

    test('search populates TT', () {
      final pos = Position.initial();
      Search.clearTT();

      Search.search(pos, 2);

      // TT should have some entries now
      expect(Search.transpositionTable.stores, greaterThan(0));
    });

    test('iterative deepening benefits from TT', () {
      final pos = Position.initial();
      Search.clearTT();

      // First search at depth 3
      final result1 = Search.search(pos, 3);
      final nodes1 = result1.nodesSearched;

      // Second search should benefit from TT
      final result2 = Search.search(pos, 3);
      final nodes2 = result2.nodesSearched;

      // With TT, second search should be faster (fewer nodes or same)
      expect(nodes2, lessThanOrEqualTo(nodes1));
    });

    test('same position via transposition hits TT', () {
      Search.clearTT();

      // Play 1. Nc3 Nc6 2. Nf3 and 1. Nf3 Nc6 2. Nc3 (same position)
      var pos1 = Position.initial();
      pos1 = pos1.makeMoveUci('b1c3')!;
      pos1 = pos1.makeMoveUci('b8c6')!;
      pos1 = pos1.makeMoveUci('g1f3')!;

      var pos2 = Position.initial();
      pos2 = pos2.makeMoveUci('g1f3')!;
      pos2 = pos2.makeMoveUci('b8c6')!;
      pos2 = pos2.makeMoveUci('b1c3')!;

      // Search first position
      Search.search(pos1, 2);
      final hitsAfterFirst = Search.transpositionTable.hits;

      // Search second position (same via transposition)
      Search.search(pos2, 2);
      final hitsAfterSecond = Search.transpositionTable.hits;

      // Should have TT hits from the transposition
      expect(hitsAfterSecond, greaterThan(hitsAfterFirst));
    });
  });
}
