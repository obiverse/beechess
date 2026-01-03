# beechess

A pure Dart chess engine - the platonic form of [mchess-reforged](https://github.com/mesb/mchess-reforged).

## Philosophy

- **Immutability over mutation** - Board states are immutable, enabling safe history and parallelism
- **Sealed types over int constants** - Exhaustive pattern matching for colors, pieces, results
- **Result types over exceptions** - Explicit error handling, no surprise exceptions
- **Composition over inheritance** - Clean separation of concerns

## Architecture

```
beechess/
├── lib/src/
│   ├── core/           # Pure chess primitives
│   │   ├── square.dart     # Extension type (0-63)
│   │   ├── color.dart      # Sealed: White | Black
│   │   ├── piece.dart      # Sealed piece types
│   │   ├── move.dart       # Move representation
│   │   ├── board.dart      # Immutable board
│   │   ├── state.dart      # Game state
│   │   └── position.dart   # Board + State + rules
│   │
│   ├── rules/          # Move validation
│   ├── format/         # FEN, PGN, SAN
│   ├── engine/         # AI (eval, search)
│   └── game/           # Game management
│
└── test/               # Comprehensive tests including perft
```

## Usage

```dart
import 'package:beechess/beechess.dart';

// Create initial position
final position = Position.initial();

// Make a move
final result = position.makeMove(Move.parse('e2e4')!);
switch (result) {
  case MoveOk(:final position): print(position.toFen());
  case MoveErr(:final error): print('Illegal: $error');
}

// Get all legal moves
for (final move in position.legalMoves()) {
  print(move.toUci());
}
```

## Roadmap

Development is tracked via [GitHub Issues](https://github.com/obiverse/beechess/issues) organized into milestones:

| Milestone | Description |
|-----------|-------------|
| [M1: Core Types](https://github.com/obiverse/beechess/milestone/1) | Square, Color, Piece, Direction, Move |
| [M2: Board & State](https://github.com/obiverse/beechess/milestone/2) | Immutable Board, GameState, FEN |
| [M3: Move Generation](https://github.com/obiverse/beechess/milestone/3) | Pseudo-legal, check detection, legal filtering |
| [M4: Special Moves](https://github.com/obiverse/beechess/milestone/4) | Castling, en passant, promotion, game end |
| [M5: Position & Game](https://github.com/obiverse/beechess/milestone/5) | Position class, Game history, Zobrist |
| [M6: Perft](https://github.com/obiverse/beechess/milestone/6) | Move generation validation |
| [M7: Engine](https://github.com/obiverse/beechess/milestone/7) | Evaluation, search, transposition table |
| [M8: Serialization](https://github.com/obiverse/beechess/milestone/8) | SAN, PGN formats |
| [M9: Integration](https://github.com/obiverse/beechess/milestone/9) | 9S protocol, Beeverse arena |

## Part of OBIVERSE

beechess is the chess engine powering [beeverse](https://github.com/obiverse/beeverse), a sovereign gaming universe built on:
- [nine_s](https://github.com/obiverse/nine_s_dart) - Universal data protocol
- [wallet_core](https://github.com/obiverse/wallet_core) - Cryptographic identity & payments

## References

- Original inspiration: [mchess-reforged](https://github.com/mesb/mchess-reforged) (Go)
- Design wiki: `9s read /wiki/beeverse/beechess-architecture`

## License

MIT
