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

## Part of OBIVERSE

beechess is the chess engine powering [beeverse](https://github.com/nicobao/beeverse), a sovereign gaming universe built on:
- [nine_s](https://github.com/nicobao/nine_s_dart) - Universal data protocol
- [wallet_core](https://github.com/nicobao/wallet_core) - Cryptographic identity & payments

## License

MIT
