import 'package:json_annotation/json_annotation.dart';

part 'board.g.dart';

@JsonSerializable()
class Board {
  final String center;
  final List<String> otherLetters;
  final List<String> validWords;

  Board(
      {required this.center,
      required this.otherLetters,
      required this.validWords});

  factory Board.fromJson(Map<String, dynamic> json) => _$BoardFromJson(json);
  Map<String, dynamic> toJson() => _$BoardToJson(this);
}
