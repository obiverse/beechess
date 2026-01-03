/// A pure Dart chess engine - platonic form of mchess-reforged.
///
/// ## Philosophy
/// - Immutability over mutation
/// - Sealed types over int constants
/// - Result types over exceptions
/// - Composition over inheritance
library beechess;

// Core types
export 'src/core/square.dart';
export 'src/core/color.dart';
export 'src/core/direction.dart';
export 'src/core/piece.dart';
export 'src/core/move.dart';

// Board and state
export 'src/core/board.dart';
export 'src/core/castling.dart';
export 'src/core/game_state.dart';

// Move generation and attacks
export 'src/core/attacks.dart';
export 'src/core/move_gen.dart';
export 'src/core/position.dart';

// Engine
export 'src/engine/eval.dart';
export 'src/engine/perft.dart';
