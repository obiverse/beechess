import 'dart:math';

import '../core/color.dart';
import '../core/move.dart';
import '../core/position.dart';
import '../core/zobrist.dart';
import 'eval.dart';
import 'tt.dart';

/// Search result containing the best move and score.
class SearchResult {
  const SearchResult(this.bestMove, this.score, this.nodesSearched);

  /// The best move found.
  final Move? bestMove;

  /// Evaluation score in centipawns.
  final int score;

  /// Number of nodes searched.
  final int nodesSearched;

  @override
  String toString() =>
      'SearchResult($bestMove, score: $score, nodes: $nodesSearched)';
}

/// Chess engine search using alpha-beta pruning with transposition table.
class Search {
  Search._();

  /// Shared transposition table (64 MB default).
  static final TranspositionTable _tt = TranspositionTable(sizeMB: 64);

  /// Get the transposition table for inspection/clearing.
  static TranspositionTable get transpositionTable => _tt;

  /// Evaluate position from side-to-move perspective (for negamax).
  static int _evaluate(Position position) {
    final score = Evaluator.evaluate(position);
    return position.turn == Color.white ? score : -score;
  }

  /// Search for the best move using alpha-beta with transposition table.
  ///
  /// Returns the best move found within the given depth.
  static SearchResult search(Position position, int depth) {
    if (depth <= 0) {
      return SearchResult(null, _evaluate(position), 1);
    }

    final hash = Zobrist.hashPosition(position);
    int nodesSearched = 0;
    Move? bestMove;
    int bestScore = -Evaluator.mateScore - 1;
    const origAlpha = -Evaluator.mateScore;
    var alpha = origAlpha;
    const beta = Evaluator.mateScore;

    final moves = position.legalMoves;
    if (moves.isEmpty) {
      return SearchResult(null, _evaluate(position), 1);
    }

    // Order moves with TT move first
    final orderedMoves = _orderMoves(position, moves, hash);

    for (final move in orderedMoves) {
      final newPos = position.makeMove(move);
      if (newPos == null) continue;

      final result = _alphaBeta(
        newPos,
        depth - 1,
        -beta,
        -alpha,
      );

      nodesSearched += result.nodesSearched;
      final score = -result.score;

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }

      if (score > alpha) {
        alpha = score;
      }
    }

    // Store in TT
    final scoreType = bestScore <= origAlpha
        ? ScoreType.upperBound
        : (bestScore >= beta ? ScoreType.lowerBound : ScoreType.exact);

    _tt.store(
      hash: hash,
      move: bestMove,
      score: bestScore,
      depth: depth,
      type: scoreType,
    );

    return SearchResult(bestMove, bestScore, nodesSearched);
  }

  /// Alpha-beta search with negamax framework and TT.
  static SearchResult _alphaBeta(
    Position position,
    int depth,
    int alpha,
    int beta,
  ) {
    final hash = Zobrist.hashPosition(position);
    final origAlpha = alpha;

    // Probe transposition table
    final ttEntry = _tt.probe(hash);
    if (ttEntry != null && ttEntry.depth >= depth) {
      switch (ttEntry.type) {
        case ScoreType.exact:
          return SearchResult(ttEntry.move, ttEntry.score, 1);
        case ScoreType.lowerBound:
          alpha = max(alpha, ttEntry.score);
        case ScoreType.upperBound:
          beta = min(beta, ttEntry.score);
      }
      if (alpha >= beta) {
        return SearchResult(ttEntry.move, ttEntry.score, 1);
      }
    }

    // Terminal node or depth limit
    if (depth == 0 || position.isGameOver) {
      return SearchResult(null, _evaluate(position), 1);
    }

    int nodesSearched = 0;
    Move? bestMove;
    int bestScore = -Evaluator.mateScore - 1;

    final moves = position.legalMoves;
    if (moves.isEmpty) {
      return SearchResult(null, _evaluate(position), 1);
    }

    final orderedMoves = _orderMoves(position, moves, hash);

    for (final move in orderedMoves) {
      final newPos = position.makeMove(move);
      if (newPos == null) continue;

      final result = _alphaBeta(newPos, depth - 1, -beta, -alpha);
      nodesSearched += result.nodesSearched;
      final score = -result.score;

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }

      if (score > alpha) {
        alpha = score;
      }

      // Beta cutoff
      if (alpha >= beta) {
        break;
      }
    }

    // Store in TT
    final scoreType = bestScore <= origAlpha
        ? ScoreType.upperBound
        : (bestScore >= beta ? ScoreType.lowerBound : ScoreType.exact);

    _tt.store(
      hash: hash,
      move: bestMove,
      score: bestScore,
      depth: depth,
      type: scoreType,
    );

    return SearchResult(bestMove, bestScore, nodesSearched);
  }

  /// Order moves for better pruning.
  ///
  /// TT move is tried first, then captures (MVV-LVA), promotions, center moves.
  static List<Move> _orderMoves(Position position, List<Move> moves, int hash) {
    // Get TT move if available
    final ttMove = _tt.probe(hash)?.move;

    // Score each move for ordering
    final scored = moves.map((move) {
      int score = 0;

      // TT move gets highest priority
      if (ttMove != null && move == ttMove) {
        score += 100000;
      }

      // Prioritize captures (MVV-LVA)
      final capturedPiece = position.board[move.to];
      if (capturedPiece != null) {
        score += 10000 + capturedPiece.type.value;

        // Subtract attacker value for LVA
        final attacker = position.board[move.from];
        if (attacker != null) {
          score -= attacker.type.value ~/ 100;
        }
      }

      // Prioritize promotions
      if (move.promotion != null) {
        score += 9000 + move.promotion!.value;
      }

      // Center control bonus for non-captures
      if (capturedPiece == null) {
        final toRank = move.to.rank;
        final toFile = move.to.file;
        // Bonus for central squares (d4, d5, e4, e5)
        if (toRank >= 3 && toRank <= 4 && toFile >= 3 && toFile <= 4) {
          score += 50;
        }
      }

      return (move, score);
    }).toList();

    // Sort by score descending
    scored.sort((a, b) => b.$2.compareTo(a.$2));

    return scored.map((e) => e.$1).toList();
  }

  /// Find best move with iterative deepening.
  ///
  /// Searches progressively deeper, returning results for each depth.
  /// Uses transposition table to speed up deeper searches.
  static Iterable<SearchResult> iterativeDeepening(
    Position position, {
    int maxDepth = 10,
    Duration? timeLimit,
  }) sync* {
    final stopwatch = Stopwatch()..start();

    for (int depth = 1; depth <= maxDepth; depth++) {
      if (timeLimit != null && stopwatch.elapsed >= timeLimit) {
        break;
      }

      final result = search(position, depth);
      yield result;

      // If we found a mate, no need to search deeper
      if (result.score.abs() > Evaluator.mateScore - 100) {
        break;
      }
    }
  }

  /// Clear the transposition table.
  static void clearTT() => _tt.clear();
}
