import '../core/color.dart';
import '../core/move.dart';
import '../core/position.dart';
import 'eval.dart';

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
  String toString() => 'SearchResult($bestMove, score: $score, nodes: $nodesSearched)';
}

/// Chess engine search using alpha-beta pruning.
class Search {
  Search._();

  /// Evaluate position from side-to-move perspective (for negamax).
  static int _evaluate(Position position) {
    final score = Evaluator.evaluate(position);
    return position.turn == Color.white ? score : -score;
  }

  /// Search for the best move using iterative deepening.
  ///
  /// Returns the best move found within the given depth.
  static SearchResult search(Position position, int depth) {
    if (depth <= 0) {
      return SearchResult(null, _evaluate(position), 1);
    }

    int nodesSearched = 0;
    Move? bestMove;
    int bestScore = -Evaluator.mateScore - 1;

    final moves = position.legalMoves;
    if (moves.isEmpty) {
      // No legal moves - checkmate or stalemate
      return SearchResult(null, _evaluate(position), 1);
    }

    // Order moves for better pruning (captures first, etc.)
    final orderedMoves = _orderMoves(position, moves);

    for (final move in orderedMoves) {
      final newPos = position.makeMove(move);
      if (newPos == null) continue;

      final result = _alphaBeta(
        newPos,
        depth - 1,
        -Evaluator.mateScore,
        -bestScore,
      );

      nodesSearched += result.nodesSearched;
      final score = -result.score;

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return SearchResult(bestMove, bestScore, nodesSearched);
  }

  /// Alpha-beta search with negamax framework.
  static SearchResult _alphaBeta(
    Position position,
    int depth,
    int alpha,
    int beta,
  ) {
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

    final orderedMoves = _orderMoves(position, moves);

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

    return SearchResult(bestMove, bestScore, nodesSearched);
  }

  /// Order moves for better pruning.
  ///
  /// Good move ordering significantly improves alpha-beta efficiency.
  static List<Move> _orderMoves(Position position, List<Move> moves) {
    // Score each move for ordering
    final scored = moves.map((move) {
      int score = 0;

      // Prioritize captures (MVV-LVA: Most Valuable Victim - Least Valuable Attacker)
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
}
