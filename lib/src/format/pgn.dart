import 'package:meta/meta.dart';

import '../core/game.dart';
import '../core/position.dart';
import 'san.dart';

/// A parsed PGN game with headers and moves.
@immutable
class PgnGame {
  const PgnGame({
    required this.headers,
    required this.sanMoves,
    this.result,
  });

  /// PGN headers (tag pairs).
  final Map<String, String> headers;

  /// Moves in SAN notation.
  final List<String> sanMoves;

  /// Game result: "1-0", "0-1", "1/2-1/2", or "*".
  final String? result;

  /// Event name (required header).
  String get event => headers['Event'] ?? '?';

  /// Site/location (required header).
  String get site => headers['Site'] ?? '?';

  /// Date in YYYY.MM.DD format (required header).
  String get date => headers['Date'] ?? '????.??.??';

  /// Round number (required header).
  String get round => headers['Round'] ?? '?';

  /// White player name (required header).
  String get white => headers['White'] ?? '?';

  /// Black player name (required header).
  String get black => headers['Black'] ?? '?';

  /// Optional FEN for starting position.
  String? get fen => headers['FEN'];

  @override
  String toString() => 'PgnGame($white vs $black, ${sanMoves.length} moves)';
}

/// Portable Game Notation (PGN) parser and formatter.
///
/// PGN is the standard format for recording chess games:
/// ```pgn
/// [Event "World Championship"]
/// [White "Carlsen, Magnus"]
/// [Black "Nepomniachtchi, Ian"]
/// [Result "1-0"]
///
/// 1. e4 e5 2. Nf3 Nc6 3. Bb5 1-0
/// ```
class Pgn {
  Pgn._();

  static final _headerRegex = RegExp(r'\[(\w+)\s+"([^"]*)"\]');
  static final _moveNumberRegex = RegExp(r'^\d+\.+$');
  static final _resultRegex = RegExp(r'^(1-0|0-1|1/2-1/2|\*)$');

  /// Parse a PGN string into a PgnGame.
  ///
  /// Returns null if the PGN is malformed.
  static PgnGame? parse(String pgn) {
    final headers = <String, String>{};
    String? result;

    // Parse headers
    for (final match in _headerRegex.allMatches(pgn)) {
      headers[match.group(1)!] = match.group(2)!;
    }

    // Extract movetext (everything after headers)
    var movetext = pgn.replaceAll(_headerRegex, '');

    // Remove comments {like this}
    movetext = movetext.replaceAll(RegExp(r'\{[^}]*\}'), '');

    // Remove variations (like this)
    movetext = _removeVariations(movetext);

    // Remove NAGs ($1, $2, etc.)
    movetext = movetext.replaceAll(RegExp(r'\$\d+'), '');

    // Parse moves
    final sanMoves = <String>[];
    final tokens = movetext.split(RegExp(r'\s+'));

    for (final token in tokens) {
      if (token.isEmpty) continue;

      // Skip move numbers (1., 1..., etc.)
      if (_moveNumberRegex.hasMatch(token)) continue;

      // Check for result
      if (_resultRegex.hasMatch(token)) {
        result = token;
        continue;
      }

      // Must be a move
      sanMoves.add(token);
    }

    // Get result from header if not in movetext
    result ??= headers['Result'];

    return PgnGame(
      headers: headers,
      sanMoves: sanMoves,
      result: result,
    );
  }

  /// Parse multiple PGN games from a string.
  ///
  /// Games are separated by blank lines after the movetext.
  static List<PgnGame> parseMany(String pgn) {
    final games = <PgnGame>[];

    // Split on empty line followed by header
    final parts = pgn.split(RegExp(r'\n\s*\n(?=\[)'));

    for (final part in parts) {
      if (part.trim().isEmpty) continue;
      final game = parse(part);
      if (game != null) {
        games.add(game);
      }
    }

    return games;
  }

  /// Format a Game as PGN string.
  ///
  /// Provide headers to set the Seven Tag Roster and other metadata.
  static String format(
    Game game, {
    Map<String, String>? headers,
    int lineWidth = 80,
  }) {
    final sb = StringBuffer();
    final h = headers ?? {};

    // Seven Tag Roster (required headers)
    sb.writeln('[Event "${_escapeString(h['Event'] ?? '?')}"]');
    sb.writeln('[Site "${_escapeString(h['Site'] ?? '?')}"]');
    sb.writeln('[Date "${_escapeString(h['Date'] ?? '????.??.??')}"]');
    sb.writeln('[Round "${_escapeString(h['Round'] ?? '?')}"]');
    sb.writeln('[White "${_escapeString(h['White'] ?? '?')}"]');
    sb.writeln('[Black "${_escapeString(h['Black'] ?? '?')}"]');
    sb.writeln('[Result "${_resultString(game)}"]');

    // Additional headers
    for (final entry in h.entries) {
      if (!_sevenTagRoster.contains(entry.key)) {
        sb.writeln('[${entry.key} "${_escapeString(entry.value)}"]');
      }
    }

    sb.writeln();

    // Movetext
    final moveLine = StringBuffer();
    var position = Position.initial();
    var moveNum = 1;
    var isWhite = true;

    for (final move in game.moves) {
      // Move number
      if (isWhite) {
        moveLine.write('$moveNum. ');
      }

      // SAN move
      final san = San.format(move, position);
      moveLine.write(san);
      moveLine.write(' ');

      // Advance position
      position = position.makeMove(move)!;

      if (!isWhite) moveNum++;
      isWhite = !isWhite;

      // Line wrap
      if (moveLine.length >= lineWidth - 10) {
        sb.write(moveLine.toString().trimRight());
        sb.writeln();
        moveLine.clear();
      }
    }

    // Final moves and result
    sb.write(moveLine.toString().trimRight());
    if (moveLine.isNotEmpty) sb.write(' ');
    sb.write(_resultString(game));

    return sb.toString();
  }

  /// Replay a PgnGame to produce a Game object.
  ///
  /// Returns null if any move is invalid.
  static Game? replay(PgnGame pgn) {
    // Start from FEN if provided, otherwise initial position
    Game game;
    if (pgn.fen != null) {
      final fromFen = Game.fromFen(pgn.fen!);
      if (fromFen == null) return null;
      game = fromFen;
    } else {
      game = Game.initial();
    }

    // Apply each move
    for (final san in pgn.sanMoves) {
      final move = San.parse(san, game.position);
      if (move == null) return null;

      final newGame = game.makeMove(move);
      if (newGame == null) return null;

      game = newGame;
    }

    return game;
  }

  /// Remove nested variations from movetext.
  static String _removeVariations(String text) {
    // Handle nested parentheses
    var depth = 0;
    final sb = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == '(') {
        depth++;
      } else if (c == ')') {
        depth--;
      } else if (depth == 0) {
        sb.write(c);
      }
    }

    return sb.toString();
  }

  /// Get result string for a game.
  static String _resultString(Game game) {
    return switch (game.result) {
      GameResult.whiteWins => '1-0',
      GameResult.blackWins => '0-1',
      GameResult.draw => '1/2-1/2',
      GameResult.ongoing => '*',
    };
  }

  /// Escape special characters in PGN strings.
  static String _escapeString(String s) {
    return s.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
  }

  static const _sevenTagRoster = {
    'Event',
    'Site',
    'Date',
    'Round',
    'White',
    'Black',
    'Result',
  };
}
