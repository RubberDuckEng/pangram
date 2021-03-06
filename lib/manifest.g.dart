// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChunkHeader _$ChunkHeaderFromJson(Map<String, dynamic> json) {
  return ChunkHeader(
    index: json['index'] as int,
    boardCount: json['boardCount'] as int,
    first: json['first'] as String,
    last: json['last'] as String,
  );
}

Map<String, dynamic> _$ChunkHeaderToJson(ChunkHeader instance) =>
    <String, dynamic>{
      'index': instance.index,
      'boardCount': instance.boardCount,
      'first': instance.first,
      'last': instance.last,
    };

Manifest _$ManifestFromJson(Map<String, dynamic> json) {
  return Manifest(
    prefix: json['prefix'] as String,
    suffix: json['suffix'] as String,
    chunkHeaders: (json['chunkHeaders'] as List<dynamic>)
        .map((e) => ChunkHeader.fromJson(e as Map<String, dynamic>))
        .toList(),
    numberPattern: json['numberPattern'] as String,
    chunkSize: json['chunkSize'] as int,
    totalBoards: json['totalBoards'] as int,
  );
}

Map<String, dynamic> _$ManifestToJson(Manifest instance) => <String, dynamic>{
      'chunkSize': instance.chunkSize,
      'totalBoards': instance.totalBoards,
      'numberPattern': instance.numberPattern,
      'prefix': instance.prefix,
      'suffix': instance.suffix,
      'chunkHeaders': instance.chunkHeaders,
    };
