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
import 'package:pangram/manifest.dart';

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
    return word.length >= 4;
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
        if (cluster.letterSet.containsAll(wordLetters)) {
          cluster.words.add(word);
        }
      }
    }
    stdout.write("\n"); // End the series of dots.

    return clusters;
  }
}

class Server {
  WordList wordList;
  Server(this.wordList);

  Future<List<Board>> allBoards() async {
    // Reads the all-boards cache and returns if exist.
    // Otherwise generates from word list.
    List<Board> allBoards = [];
    List<LetterCluster> clusters = wordList.letterClusters;
    clusters.sort((a, b) => a.letters.compareTo(b.letters));
    for (LetterCluster cluster in clusters) {
      for (String center in cluster.letterSet) {
        allBoards.add(Board(
          center: center,
          otherLetters:
              cluster.letterSet.where((letter) => letter != center).toList(),
          validWords:
              cluster.words.where((word) => word.contains(center)).toList(),
        ));
      }
    }
    return Future.value(allBoards);
  }
}

Future<List<String>> loadWordList(Uri uri) async {
  http.Response response = await http.get(uri);
  String wordsString = response.body;
  return wordsString.split("\n");
}

List<List<T>> chunkList<T>(List<T> list, int chunkSize) {
  int length = list.length;
  List<List<T>> chunks = <List<T>>[];

  for (int i = 0; i < length; i += chunkSize) {
    var end = (i + chunkSize < length) ? i + chunkSize : length;
    chunks.add(list.sublist(i, end));
  }
  return chunks;
}

void main() async {
  final Uri wordListUri = Uri.parse("https://norvig.com/ngrams/enable1.txt");
  WordList wordList = WordList(await loadWordList(wordListUri));
  Server server = Server(wordList);
  List<Board> boards = await server.allBoards();

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
