import 'package:json_annotation/json_annotation.dart';

part 'board.g.dart';

@JsonSerializable()
class Board {
  final String center;
  final List<String> otherLetters;
  final List<String> validWords;

  // FIXME: Only used during construction, probably should not be here?
  final int difficultyScore;

  double? difficultyPercentile;

  Board({
    required this.center,
    required this.otherLetters,
    required this.validWords,
    this.difficultyScore = 0,
  }) {
    // Not sure if modifying the passed letter List is safe?
    otherLetters.sort();
  }

  // Assumes otherLetters is sorted (as it is in constructor);
  String get id => "$center:${otherLetters.join('')}";

  factory Board.fromJson(Map<String, dynamic> json) => _$BoardFromJson(json);
  Map<String, dynamic> toJson() => _$BoardToJson(this);
}
