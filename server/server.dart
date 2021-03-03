// For a given list of words
// Find all the words composed of exactly 7 letters
// Unique those into clusters
// For each cluster, pick a "middle letter"
// cluster + middle letter = board.
// Score each board.
// Score = 1 per word +

// For a given list of word commonality.
// Compute "hardness score" where hardness is bucketed commonality.

import 'package:http/http.dart' as http;
import 'package:pangram/board.dart';

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
    return word.length > 4;
  }

  List<LetterCluster> _computeLetterClusters() {
    print("Creating clusters from words");
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

    print("Adding words to clusters");
    for (String word in legalWords) {
      // Could have cached this from first walk.
      List<String> wordLetters = word.split("");
      for (LetterCluster cluster in clusters) {
        if (cluster.letterSet.containsAll(wordLetters)) {
          cluster.words.add(word);
        }
      }
    }

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
    print("LetterClusters: ${clusters.length}");
    for (LetterCluster cluster in clusters) {
      // FIXME: Unordered.
      for (String center in cluster.letterSet) {
        allBoards.add(Board(
          center: center,
          otherLetters:
              cluster.letterSet.where((letter) => letter != center).toList(),
          validWords: [],
        ));
      }
    }
    return Future.value(allBoards);
  }

  // Future<Board> nextBoard() async {
  //   // Is this random?
  //   // Do we have a curated list?
  //   // What makes a good board?
  // }
}

Future<List<String>> loadWordList(Uri uri) async {
  http.Response response = await http.get(uri);
  String wordsString = response.body;
  return wordsString.split("\n");
}

void main() async {
  final Uri wordListUri = Uri.parse("https://norvig.com/ngrams/enable1.txt");
  WordList wordList = WordList(await loadWordList(wordListUri));
  Server server = Server(wordList);
  List<Board> boards = await server.allBoards();
  print("Boards: ${boards.length}");
  print(boards[0].toJson());
}
