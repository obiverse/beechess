import 'dart:math';

import 'piece.dart';
import 'square.dart';

/// Zobrist hashing for position identification.
///
/// Generates unique 64-bit hash keys for chess positions.
/// Used for transposition tables and threefold repetition detection.
class Zobrist {
  Zobrist._();

  /// Random number generator with fixed seed for reproducibility.
  static final _random = Random(0x1234567890ABCDEF);

  /// Piece-square hash keys [pieceIndex][squareIndex].
  /// pieceIndex = pieceType.index * 2 + colorIndex (0-11)
  static final List<List<int>> _pieceSquare = _initPieceSquare();

  /// Castling rights hash keys [0-15] for each combination.
  static final List<int> _castling = _initArray(16);

  /// En passant file hash keys [0-7] for files a-h.
  static final List<int> _enPassantFile = _initArray(8);

  /// Side to move hash key (XOR when black to move).
  static final int sideToMove = _randomInt64();

  /// Generate a random 64-bit integer.
  static int _randomInt64() {
    // Dart's Random.nextInt only gives 32 bits, combine two
    return (_random.nextInt(1 << 32) << 32) | _random.nextInt(1 << 32);
  }

  /// Initialize an array of random 64-bit integers.
  static List<int> _initArray(int size) {
    return List.generate(size, (_) => _randomInt64());
  }

  /// Initialize piece-square table.
  static List<List<int>> _initPieceSquare() {
    return List.generate(12, (_) => _initArray(64));
  }

  /// Get piece index for hash table (0-11).
  static int _pieceIndex(Piece piece) {
    return piece.type.index * 2 + piece.color.index;
  }

  /// Get hash key for a piece on a square.
  static int pieceSquareKey(Piece piece, Square square) {
    return _pieceSquare[_pieceIndex(piece)][square.index];
  }

  /// Get hash key for castling rights.
  static int castlingKey(int castlingBits) {
    return _castling[castlingBits & 0xF];
  }

  /// Get hash key for en passant file.
  static int enPassantKey(int file) {
    return _enPassantFile[file];
  }
}

/// Extension to compute Zobrist hash from a position.
extension ZobristHash on Object {
  /// Compute the Zobrist hash key incrementally.
  ///
  /// Starting from [baseKey], XOR in the changes.
  static int updatePiece(int key, Piece piece, Square square) {
    return key ^ Zobrist.pieceSquareKey(piece, square);
  }

  static int updateSideToMove(int key) {
    return key ^ Zobrist.sideToMove;
  }

  static int updateCastling(int key, int oldBits, int newBits) {
    return key ^ Zobrist.castlingKey(oldBits) ^ Zobrist.castlingKey(newBits);
  }

  static int updateEnPassant(int key, int? oldFile, int? newFile) {
    if (oldFile != null) key ^= Zobrist.enPassantKey(oldFile);
    if (newFile != null) key ^= Zobrist.enPassantKey(newFile);
    return key;
  }
}
