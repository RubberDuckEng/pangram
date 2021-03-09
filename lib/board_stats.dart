import 'package:json_annotation/json_annotation.dart';

part 'board_stats.g.dart';

@JsonSerializable()
class WordCount {
  final String word;
  final int count;
  WordCount(this.word, this.count);

  factory WordCount.fromJson(Map<String, dynamic> json) =>
      _$WordCountFromJson(json);
  Map<String, dynamic> toJson() => _$WordCountToJson(this);
}

@JsonSerializable()
class Bucket {
  final int first;
  final int last;
  final int sum;

  Bucket({required this.first, required this.last, required this.sum});

  factory Bucket.fromJson(Map<String, dynamic> json) => _$BucketFromJson(json);
  Map<String, dynamic> toJson() => _$BucketToJson(this);
}

@JsonSerializable()
class BoardStats {
  final List<Bucket> maxScores;
  final List<Bucket> numberOfAnswers;
  final List<WordCount> centerLetters;
  final List<WordCount> validLetters;
  final List<WordCount> commonWords;

  BoardStats({
    required this.maxScores,
    required this.numberOfAnswers,
    required this.centerLetters,
    required this.validLetters,
    required this.commonWords,
  });

  factory BoardStats.fromJson(Map<String, dynamic> json) =>
      _$BoardStatsFromJson(json);
  Map<String, dynamic> toJson() => _$BoardStatsToJson(this);
}
