// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Board _$BoardFromJson(Map<String, dynamic> json) {
  return Board(
    center: json['center'] as String,
    otherLetters: (json['otherLetters'] as List<dynamic>)
        .map((e) => e as String)
        .toList(),
    validWords:
        (json['validWords'] as List<dynamic>).map((e) => e as String).toList(),
    difficultyScore: json['difficultyScore'] as int,
  )..difficultyPercentile = (json['difficultyPercentile'] as num?)?.toDouble();
}

Map<String, dynamic> _$BoardToJson(Board instance) => <String, dynamic>{
      'center': instance.center,
      'otherLetters': instance.otherLetters,
      'validWords': instance.validWords,
      'difficultyScore': instance.difficultyScore,
      'difficultyPercentile': instance.difficultyPercentile,
    };
