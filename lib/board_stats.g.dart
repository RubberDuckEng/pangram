// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WordCount _$WordCountFromJson(Map<String, dynamic> json) {
  return WordCount(
    json['word'] as String,
    json['count'] as int,
  );
}

Map<String, dynamic> _$WordCountToJson(WordCount instance) => <String, dynamic>{
      'word': instance.word,
      'count': instance.count,
    };

Bucket _$BucketFromJson(Map<String, dynamic> json) {
  return Bucket(
    first: json['first'] as int,
    last: json['last'] as int,
    sum: json['sum'] as int,
  );
}

Map<String, dynamic> _$BucketToJson(Bucket instance) => <String, dynamic>{
      'first': instance.first,
      'last': instance.last,
      'sum': instance.sum,
    };

BoardStats _$BoardStatsFromJson(Map<String, dynamic> json) {
  return BoardStats(
    maxScores: (json['maxScores'] as List<dynamic>)
        .map((e) => Bucket.fromJson(e as Map<String, dynamic>))
        .toList(),
    numberOfAnswers: (json['numberOfAnswers'] as List<dynamic>)
        .map((e) => Bucket.fromJson(e as Map<String, dynamic>))
        .toList(),
    centerLetters: (json['centerLetters'] as List<dynamic>)
        .map((e) => WordCount.fromJson(e as Map<String, dynamic>))
        .toList(),
    validLetters: (json['validLetters'] as List<dynamic>)
        .map((e) => WordCount.fromJson(e as Map<String, dynamic>))
        .toList(),
    commonWords: (json['commonWords'] as List<dynamic>)
        .map((e) => WordCount.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$BoardStatsToJson(BoardStats instance) =>
    <String, dynamic>{
      'maxScores': instance.maxScores,
      'numberOfAnswers': instance.numberOfAnswers,
      'centerLetters': instance.centerLetters,
      'validLetters': instance.validLetters,
      'commonWords': instance.commonWords,
    };
