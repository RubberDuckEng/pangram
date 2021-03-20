// For a given list of words
// Find all the words composed of exactly 7 letters
// Unique those into clusters
// For each cluster, pick a "middle letter"
// cluster + middle letter = board.
// Score each board.
// Score = 1 per word +

// For a given list of word commonality.
// Compute "hardness score" where hardness is bucketed commonality.

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pangram/board.dart';
import 'package:pangram/utils.dart';
import 'package:pangram/manifest.dart';
import 'package:path/path.dart' as p;

class DiskCache {
  Directory cacheDirectory;
  DiskCache(this.cacheDirectory);

  File _cacheFileForRemoteUri(Uri remoteUri) {
    String cacheName = remoteUri.pathSegments.last;
    String cachedPath = p.join(cacheDirectory.path, cacheName);
    return File(cachedPath);
  }

  Future<File> ensureCached(Uri remoteUri) async {
    File cacheFile = _cacheFileForRemoteUri(remoteUri);
    if (await cacheFile.exists()) {
      return cacheFile;
    }

    print("Downloading $remoteUri to ${cacheFile.path}");
    http.Response response = await http.get(remoteUri);
    await cacheFile.create(recursive: true);
    await cacheFile.writeAsBytes(response.bodyBytes);
    return cacheFile;
  }
}

class LetterCluster {
  String letters;
  Set<String> letterSet;
  List<String> words = [];

  LetterCluster(this.letters) : letterSet = Set<String>.from(letters.split(""));
}

class WordList {
  final List<String> allWords;
  final List<String> legalWords;

  late final List<LetterCluster> letterClusters = _computeLetterClusters();

  WordList(this.allWords) : legalWords = allWords.where(isLegalWord).toList();

  static bool isLegalWord(String word) {
    // Also exclude words with S in them?
    // https://nytbee.com/ suggests S is not allowed.
    // https://nytbee.com/ suggests NYT never goes above 80 words!
    return (word.length >= 4 && !word.contains('s'));
  }

  List<LetterCluster> _computeLetterClusters() {
    print("Creating clusters from ${legalWords.length} legal words");
    Set<String> letterSets = Set<String>();
    for (String word in legalWords) {
      List<String> letters = List.from(Set.from(word.split("")));
      if (letters.length != 7) continue;
      letters.sort();
      letterSets.add(letters.join(""));
    }

    List<LetterCluster> clusters = [];
    for (String letters in letterSets) {
      clusters.add(LetterCluster(letters));
    }

    print("Adding words to ${clusters.length} clusters");
    int index = 0;
    for (String word in legalWords) {
      // Print a dot every 1000
      if (index++ % 1000 == 0) stdout.write(".");

      // Could have cached this from first walk.
      List<String> wordLetters = word.split("");
      for (LetterCluster cluster in clusters) {
        // 63% of time is spent in containsAll
        // Perhaps a walk of two sorted strings would be faster?
        if (cluster.letterSet.containsAll(wordLetters)) {
          cluster.words.add(word);
        }
      }
    }
    stdout.write("\n"); // End the series of dots.

    return clusters;
  }
}

class DifficultyRater {
  // FIXME: Tune hardness approximation.
  // 10 = very hard (rarest 25% or not found)
  // 5 = hard (rarest 50%)
  // 3 = medium (rarest 75%)
  // 1 = easy
  int rarityScore(double rarityPercent) {
    if (rarityPercent < 0.25) return 1;
    if (rarityPercent < 0.5) return 3;
    if (rarityPercent < 0.75) return 5;
    return 10;
  }
}

class BoardGenerator {
  WordList wordList;
  WordFrequencies frequencies;
  BoardGenerator(this.wordList, this.frequencies);

  List<Board> generateBoards() {
    DifficultyRater rater = DifficultyRater();
    // Reads the all-boards cache and returns if exist.
    // Otherwise generates from word list.
    List<Board> allBoards = [];
    int maxDifficulty = 0;
    List<LetterCluster> clusters = wordList.letterClusters;
    clusters.sort((a, b) => a.letters.compareTo(b.letters));

    // maxWordCount 269 for the norvig list
    // int maxWordCount =
    //     clusters.fold(0, (maxWords, cluster) => cluster.words.length);
    // print("Clusters maxWordCount: $maxWordCount");

    for (LetterCluster cluster in clusters) {
      for (String center in cluster.letterSet) {
        List<String> validWords =
            cluster.words.where((word) => word.contains(center)).toList();

        // FIXME: This lookup should be done at Cluster construction time
        // rather than at least 7x as common during *board* construction.
        int difficulty = validWords.fold(
            0,
            (previous, word) =>
                previous +
                rater.rarityScore(frequencies.rarityPercentile(word)));
        if (difficulty > maxDifficulty) maxDifficulty = difficulty;

        allBoards.add(
          Board(
            center: center,
            otherLetters:
                cluster.letterSet.where((letter) => letter != center).toList(),
            validWords: validWords,
            difficultyScore: difficulty,
          ),
        );
      }
    }

    // Normalize difficulty scores:
    print("Normalizing board difficulties from max $maxDifficulty");
    // FIXME: Max is 11790!? So presumably this should be weighted somehow?
    // Or outlier boards e.g. exceptionally large numbers of words, should
    // just be discarded?
    for (Board board in allBoards) {
      board.difficultyPercentile = board.difficultyScore / maxDifficulty;
    }

    return allBoards;
  }
}

class WordFrequencies {
  Map<String, int> wordToFrequency = <String, int>{};
  int maxFrequency = 0;
  int minFrequency = 999999999999;

  WordFrequencies(List<String> lines) {
    for (String line in lines) {
      // Format: word length frequency article_count
      List<String> parts = line.split(" ");
      String word = parts[0];
      int frequency = int.parse(parts[2]);
      wordToFrequency[word] = frequency;
      if (frequency > maxFrequency) maxFrequency = frequency;
      if (frequency < minFrequency) minFrequency = frequency;
    }
  }

  double rarityPercentile(String word) {
    // FIXME: Should this use minFrequency somewhere?
    int frequency = wordToFrequency[word] ?? 0;
    return 1.0 - (frequency / maxFrequency);
  }
}

void printLongestWords(WordList wordList) {
  int longestWordLength = wordList.legalWords.fold(
      0,
      (previous, element) =>
          previous > element.length ? previous : element.length);
  print("Longest word length: $longestWordLength");
  List<String> longestWords = [];
  for (String word in wordList.legalWords) {
    if (word.length > 15) {
      longestWords.add(word);
    }
  }
  print(longestWords);
}

void main() async {
  final Directory cacheDirectory = Directory(".cache");
  final Uri wordListUri = Uri.parse("https://norvig.com/ngrams/enable1.txt");
  // This only includes 4-28, since 28 is the largest legal word in the norvig sample.
  // This is about 50 mb.
  // Format: word length frequency article_count
  final Uri wordsByFrequencyUri =
      Uri.parse("https://en.lexipedia.org/download.php?freq=1&range=4+-+28");

  DiskCache cache = DiskCache(cacheDirectory);

  File wordListFile = await cache.ensureCached(wordListUri);
  List<String> words = await wordListFile.readAsLines();
  WordList wordList = WordList(words);
  // return printLongestWords(wordList);

  File frequencyFile = await cache.ensureCached(wordsByFrequencyUri);
  WordFrequencies frequencies =
      WordFrequencies(await frequencyFile.readAsLines());

  BoardGenerator boardGenerator = BoardGenerator(wordList, frequencies);
  List<Board> boards = boardGenerator.generateBoards();
  boards.sort();

  const String directory = 'web/boards';
  const String prefix = 'boards';
  const String suffix = '.json';
  const int chunkSize = 100;
  const String numberPattern = "0000";

  List<List<Board>> chunks = chunkList(boards, chunkSize);
  List<ChunkHeader> headers = ChunkHeader.headersForChunks(chunks);
  Manifest manifest = Manifest(
    prefix: prefix,
    suffix: suffix,
    chunkHeaders: headers,
    numberPattern: numberPattern,
    totalBoards: boards.length,
    chunkSize: chunkSize,
  );

  print("Writing ${boards.length} boards to: $directory");
  Directory(directory).createSync(recursive: true);
  for (int index = 0; index < chunks.length; index++) {
    List<Board> chunk = chunks[index];
    String chunkName = manifest.chunkNameFromIndex(index);
    File file = File("$directory/$chunkName");
    file.writeAsStringSync(json.encode(chunk));
  }

  File("$directory/manifest.json")
      .writeAsStringSync(json.encode(manifest.toJson()));
}
