import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:pangram/board.dart';
import 'package:pangram/manifest.dart';
import 'package:pangram/utils.dart';
import 'package:pangram/board_stats.dart';

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

void printWordCounts(List<WordCount> wordCounts, {bool asPercent = false}) {
  int totalCount = wordCounts.fold(0, (sum, count) => sum + count.count);
  for (var count in wordCounts) {
    if (asPercent) {
      var percent = (count.count / totalCount * 100).toStringAsFixed(2);
      print("${count.word} $percent%");
    } else {
      print("${count.word} : ${count.count}");
    }
  }
}

List<WordCount> toSortedWordCountList(CountedSet counts) {
  List<WordCount> wordCounts = counts.counts.entries
      .map((entry) => WordCount(entry.key, entry.value))
      .toList();
  wordCounts.sort((a, b) => a.word.compareTo(b.word));
  return wordCounts;
}

// Should this merge with WordCount?
class IntCount {
  final int value;
  final int count;
  IntCount({required this.value, required this.count});
}

Iterable<Bucket> bucketCounts(
    {required CountedSet data, required int bucketSize}) {
  List<IntCount> counts = data.counts.entries
      .map((entry) => IntCount(value: entry.key, count: entry.value))
      .toList();
  counts.sort((a, b) => a.value.compareTo(b.value));

  // TODO: This won't work as expected with sparse data.
  // Instead of bucket "0-50", it might "0-63" if 13 items under 50 are missing.
  return chunkList(counts, bucketSize).map((var chunk) {
    return Bucket(
      first: chunk.first.value,
      last: chunk.last.value,
      sum: chunk.fold(0, (sum, count) => sum + count.count),
    );
  });
}

void printBuckets(Iterable<Bucket> buckets) {
  for (var bucket in buckets) {
    print("${bucket.first}-${bucket.last} : ${bucket.sum}");
  }
}

void printStats(BoardStats stats) {
  // Max Score (bucketed by 50s)
  print("Max Score:");
  printBuckets(stats.maxScores);

  // Number of answers (bucketed by 5, starting at 20)
  print("Number of Answers:");
  printBuckets(stats.numberOfAnswers);

  // // Center Letter Frequency
  // print("Center Letters:");
  // printWordCounts(stats.centerLetters, asPercent: true);

  // Valid Letter Frequency
  print("Valid Letters:");
  printWordCounts(stats.validLetters, asPercent: true);

  // Most common words
  print("Most Common Words:");
  printWordCounts(stats.commonWords);
}

void main() async {
  final String directoryPath = p.join('web', 'boards');
  final List<Board> boards = await loadBoards(directoryPath);
  final Counters counters = Counters();
  for (Board board in boards) {
    counters.maxScores.count(board.computeMaxScore());
    counters.numberOfAnswers.count(board.validWords.length);
    counters.centerLetters.count(board.center);
    for (String letter in board.otherLetters) {
      counters.validLetters.count(letter);
    }
    for (String word in board.validWords) {
      counters.commonWords.count(word);
    }
  }

  List<WordCount> mostComonWords = counters.commonWords.counts.entries
      .map((entry) => WordCount(entry.key, entry.value))
      .toList();
  mostComonWords.sort((a, b) => -a.count.compareTo(b.count));

  // TODO: Perhaps a constructor which just takes Counters?
  BoardStats stats = BoardStats(
    maxScores: bucketCounts(data: counters.maxScores, bucketSize: 50).toList(),
    numberOfAnswers:
        bucketCounts(data: counters.numberOfAnswers, bucketSize: 5).toList(),
    // TODO: Missing letters are omitted instead of '0'.
    centerLetters: toSortedWordCountList(counters.centerLetters),
    validLetters: toSortedWordCountList(counters.validLetters),
    commonWords: mostComonWords.sublist(0, 50),
  );

  printStats(stats);

  String statsPath = p.join(directoryPath, "stats.json");
  print("Writing to $statsPath");
  var jsonString = json.encode(stats.toJson());
  File(statsPath).writeAsString(jsonString);
}
