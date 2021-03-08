// Max Score (bucketed by 50s)
// Number of answers (bucketed by 5, starting at 20)
// Center Letter Frequency
// Valid Letter Frequency
// Most common words

import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:pangram/board.dart';
import 'package:pangram/manifest.dart';

class CountedSet<T> {
  final Map<T, int> counts = <T, int>{};

  CountedSet();

  void count(T value) {
    int count = counts[value] ?? 0;
    counts[value] = count + 1;
  }
}

// Is this what motivates asks for Data classes in Dart?
class Counters {
  CountedSet<int> maxScores = CountedSet<int>();
  CountedSet<int> numberOfAnswers = CountedSet<int>();
  CountedSet<String> centerLetters = CountedSet<String>();
  CountedSet<String> validLetters = CountedSet<String>();
  CountedSet<String> commonWords = CountedSet<String>();
}

Future<dynamic> loadJson(String path) async {
  return json.decode(await File(path).readAsString());
}

Future<List<Board>> loadBoards(String directoryPath) async {
  String manifestPath = p.join(directoryPath, 'manifest.json');
  Manifest manifest = Manifest.fromJson(await loadJson(manifestPath));
  List<Board> boards = <Board>[];
  for (ChunkHeader header in manifest.chunkHeaders) {
    String chunkName = manifest.chunkNameFromIndex(header.index);
    String chunkPath = p.join(directoryPath, chunkName);
    var boardsJson = await loadJson(chunkPath);
    boards.addAll(
        boardsJson.map<Board>((boardJson) => Board.fromJson(boardJson)));
  }
  return boards;
}

class WordCount {
  final String word;
  final int count;
  WordCount(this.word, this.count);
}

void main() async {
  final String directoryPath = p.join('web', 'boards');
  final List<Board> boards = await loadBoards(directoryPath);
  final Counters stats = Counters();
  for (Board board in boards) {
    stats.maxScores.count(board.computeMaxScore());
    stats.numberOfAnswers.count(board.validWords.length);
    stats.centerLetters.count(board.center);
    for (String letter in board.otherLetters) {
      stats.validLetters.count(letter);
    }
    for (String word in board.validWords) {
      stats.commonWords.count(word);
    }
  }

  List<WordCount> wordCounts = stats.commonWords.counts.entries
      .map((entry) => WordCount(entry.key, entry.value))
      .toList();
  wordCounts.sort((a, b) => -a.count.compareTo(b.count));
  wordCounts = wordCounts.sublist(0, 50);
  for (var count in wordCounts) {
    print("${count.word} : ${count.count}");
  }

// Max Score (bucketed by 50s)
// Number of answers (bucketed by 5, starting at 20)
// Center Letter Frequency
// Valid Letter Frequency
// Most common words
}
