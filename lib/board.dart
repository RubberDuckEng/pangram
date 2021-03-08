import 'package:json_annotation/json_annotation.dart';

part 'board.g.dart';

@JsonSerializable()
class Board {
  final String center;
  final List<String> otherLetters;
  final List<String> validWords;

  // TODO: Only used during construction, probably should not be here?
  final int difficultyScore;

  double? difficultyPercentile;

  // TODO: Not sure where to put scoreForWord logic?
  static int scoreForWord(String word) {
    // Quoting http://varianceexplained.org/r/honeycomb-puzzle/
    // Four-letter words are worth 1 point each, while five-letter words are
    // worth 5 points, six-letter words are worth 6 points, seven-letter words
    // are worth 7 points, etc. Words that use all of the seven letters in the
    // honeycomb are known as “pangrams” and earn 7 bonus points (in addition
    // to the points for the length of the word). So in the above example,
    // MEGAPLEX is worth 15 points.

    int length = word.length;
    if (length < 4) {
      throw ArgumentError("Only know how to score words above 4 letters");
    }

    if (length == 4) return 1;
    int uniqueLetterCount = Set.from(word.split('')).length;
    // Assuming reasonable inputs (not checking for > 7).
    int pangramBonus = (uniqueLetterCount == 7) ? 7 : 0;
    return pangramBonus + length;
  }

  Board({
    required this.center,
    required this.otherLetters,
    required this.validWords,
    this.difficultyScore = 0,
  }) {
    // Not sure if modifying the passed letter List is safe?
    otherLetters.sort();
  }

  int computeMaxScore() => validWords.fold(
      0, (previous, word) => previous + Board.scoreForWord(word));

  // Assumes otherLetters is sorted (as it is in constructor);
  String get id => "$center:${otherLetters.join('')}";

  factory Board.fromJson(Map<String, dynamic> json) => _$BoardFromJson(json);
  Map<String, dynamic> toJson() => _$BoardToJson(this);
}
