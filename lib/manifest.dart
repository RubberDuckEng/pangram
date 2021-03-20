import 'package:json_annotation/json_annotation.dart';

import 'board.dart';
import 'package:intl/intl.dart';

part 'manifest.g.dart';

@JsonSerializable()
class ChunkHeader {
  int index;
  int boardCount;
  final String first;
  final String last;

  ChunkHeader(
      {required this.index,
      required this.boardCount,
      required this.first,
      required this.last});

  static List<ChunkHeader> headersForChunks(List<List<Board>> chunks) {
    List<ChunkHeader> chunkHeaders = [];
    for (int index = 0; index < chunks.length; index++) {
      List<Board> chunk = chunks[index];
      chunkHeaders.add(ChunkHeader(
        index: index,
        boardCount: chunk.length,
        first: chunk.first.id,
        last: chunk.last.id,
      ));
    }
    return chunkHeaders;
  }

  factory ChunkHeader.fromJson(Map<String, dynamic> json) =>
      _$ChunkHeaderFromJson(json);
  Map<String, dynamic> toJson() => _$ChunkHeaderToJson(this);
}

@JsonSerializable()
class Manifest {
  final int version = 2;
  final int chunkSize;
  final int totalBoards;
  final String numberPattern;
  final String prefix;
  final String suffix;
  final List<ChunkHeader> chunkHeaders;

  Manifest({
    required this.prefix,
    required this.suffix,
    required this.chunkHeaders,
    required this.numberPattern,
    required this.chunkSize,
    required this.totalBoards,
  });

  String chunkNameFromIndex(int index) {
    NumberFormat formatter = NumberFormat(numberPattern);
    return "$prefix${formatter.format(index)}$suffix";
  }

  String? findChunkNameForBoardId(String boardId) {
    // Assuming chunk headers are sorted?
    for (var header in chunkHeaders) {
      // boardId is after this chunk
      if (header.last.compareTo(boardId) < 0) continue;
      if (header.first.compareTo(boardId) <= 0)
        return chunkNameFromIndex(header.index);
    }
    return null;
  }

  factory Manifest.fromJson(Map<String, dynamic> json) =>
      _$ManifestFromJson(json);
  Map<String, dynamic> toJson() => _$ManifestToJson(this);
}
