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
import 'package:pangram/utils.dart';

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

void printTopN(CountedSet counts, int topNCount) {
  List<WordCount> wordCounts = counts.counts.entries
      .map((entry) => WordCount(entry.key, entry.value))
      .toList();
  wordCounts.sort((a, b) => -a.count.compareTo(b.count));
  wordCounts = wordCounts.sublist(0, topNCount);
  for (var count in wordCounts) {
    print("${count.word} : ${count.count}");
  }
}

void printLetterFrequency(CountedSet letterCounts) {
  List<WordCount> wordCounts = letterCounts.counts.entries
      .map((entry) => WordCount(entry.key, entry.value))
      .toList();
  wordCounts.sort((a, b) => a.word.compareTo(b.word));
  int totalCount = wordCounts.fold(0, (sum, count) => sum + count.count);
  for (var count in wordCounts) {
    var percent = (count.count / totalCount * 100).toStringAsFixed(2);
    print("${count.word} $percent%");
  }
}

class Bucket {
  final int first;
  final int last;
  final int sum;

  Bucket({required this.first, required this.last, required this.sum});
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

  // Max Score (bucketed by 50s)
  print("Max Score:");
  printBuckets(bucketCounts(data: stats.maxScores, bucketSize: 50));

  // Number of answers (bucketed by 5, starting at 20)
  print("Number of Answers:");
  printBuckets(bucketCounts(data: stats.numberOfAnswers, bucketSize: 5));

  // // Center Letter Frequency
  // print("Center Letters:");
  // printLetterFrequency(stats.centerLetters);

  // Valid Letter Frequency
  // print("Valid Letters:");
  // printLetterFrequency(stats.validLetters);

  // Most common words
  // print("Most Common Words:");
  // printTopN(stats.commonWords, 50);
}
