import 'dart:math';

import 'package:meta/meta.dart';

import '../core/move.dart';

/// Score type for transposition table entries.
///
/// Indicates how the score should be interpreted:
/// - exact: The score is the exact evaluation
/// - lowerBound: The score is at least this (alpha cutoff)
/// - upperBound: The score is at most this (beta cutoff)
enum ScoreType {
  exact,
  lowerBound,
  upperBound,
}

/// Transposition table entry.
///
/// Stores cached search results for a position.
@immutable
class TTEntry {
  const TTEntry({
    required this.hash,
    this.move,
    required this.score,
    required this.depth,
    required this.type,
  });

  /// Zobrist hash of the position.
  final int hash;

  /// Best move found at this position.
  final Move? move;

  /// Evaluation score.
  final int score;

  /// Search depth when this entry was created.
  final int depth;

  /// Type of score (exact, lower bound, upper bound).
  final ScoreType type;

  @override
  String toString() =>
      'TTEntry(hash: $hash, move: $move, score: $score, depth: $depth, type: $type)';
}

/// Transposition table for caching search results.
///
/// Uses Zobrist hashing to identify positions. Entries are stored in a
/// fixed-size array with hash-based indexing.
class TranspositionTable {
  /// Create a transposition table with the given size in MB.
  ///
  /// Default is 64 MB (~2.7 million entries).
  TranspositionTable({int sizeMB = 64})
      : _size = max(1024, (sizeMB * 1024 * 1024) ~/ _entrySize),
        _table = List<TTEntry?>.filled(
          max(1024, (sizeMB * 1024 * 1024) ~/ _entrySize),
          null,
        );

  /// Approximate size of each entry in bytes.
  static const _entrySize = 24;

  final int _size;
  final List<TTEntry?> _table;

  int _hits = 0;
  int _misses = 0;
  int _stores = 0;

  /// Number of entries in the table.
  int get size => _size;

  /// Number of successful probes.
  int get hits => _hits;

  /// Number of failed probes.
  int get misses => _misses;

  /// Number of store operations.
  int get stores => _stores;

  /// Hit rate as a percentage.
  double get hitRate =>
      (_hits + _misses) > 0 ? _hits / (_hits + _misses) * 100 : 0;

  /// Compute table index from hash.
  int _index(int hash) => hash.abs() % _size;

  /// Store an entry in the table.
  ///
  /// Uses depth-preferred replacement: deeper searches replace shallower ones.
  void store({
    required int hash,
    Move? move,
    required int score,
    required int depth,
    required ScoreType type,
  }) {
    final idx = _index(hash);
    final existing = _table[idx];

    // Replacement strategy: prefer deeper searches, or same depth if exact
    if (existing == null ||
        depth > existing.depth ||
        (depth == existing.depth && type == ScoreType.exact)) {
      _table[idx] = TTEntry(
        hash: hash,
        move: move,
        score: score,
        depth: depth,
        type: type,
      );
    }

    _stores++;
  }

  /// Probe the table for an entry matching the hash.
  ///
  /// Returns null if no matching entry is found.
  TTEntry? probe(int hash) {
    final idx = _index(hash);
    final entry = _table[idx];

    if (entry != null && entry.hash == hash) {
      _hits++;
      return entry;
    }

    _misses++;
    return null;
  }

  /// Clear all entries from the table.
  void clear() {
    for (var i = 0; i < _size; i++) {
      _table[i] = null;
    }
    _hits = 0;
    _misses = 0;
    _stores = 0;
  }

  /// Reset statistics without clearing entries.
  void resetStats() {
    _hits = 0;
    _misses = 0;
    _stores = 0;
  }

  @override
  String toString() =>
      'TranspositionTable(size: $_size, hits: $_hits, misses: $_misses, hitRate: ${hitRate.toStringAsFixed(1)}%)';
}
