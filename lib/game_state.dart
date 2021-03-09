import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pangram/board.dart';

part 'game_state.g.dart';

@JsonSerializable()
class GameState {
  static const String gameStateKey = 'currentGame';

  final Board board;
  List<String> wordsInOrderFound = [];

  GameState(this.board);

  // Should we split this object into a GameController vs GameState?
  Future save() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(gameStateKey, json.encode(this.toJson()));
  }

  Iterable<String> foundWordsByMostRecent() => wordsInOrderFound.reversed;

  void foundWord(String word) {
    wordsInOrderFound.add(word);
    save();
  }

  bool get haveWon => wordsInOrderFound.length == board.validWords.length;

  static Future<GameState?> loadSaved() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? gameStateString = prefs.getString(gameStateKey);
    if (gameStateString == null) {
      return null;
    }

    try {
      return GameState.fromJson(json.decode(gameStateString));
    } catch (e) {
      print("Failed to load game: $e");
      // Clear any bad data to avoid hitting this every time.
      await prefs.remove(gameStateKey);
    }
    return null;
  }

  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);
  Map<String, dynamic> toJson() => _$GameStateToJson(this);
}
