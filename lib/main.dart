import 'dart:convert';
import 'dart:math';

import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'pangram.dart';
import 'board.dart';
import 'game_state.dart';
import 'manifest.dart';
import 'stats.dart';

void main() {
  final Server server = Server();
  runApp(MyApp(server: server));
}

class MyApp extends StatelessWidget {
  final Server server;
  MyApp({required this.server});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pangram Game',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      initialRoute: '/',
      routes: {
        // When navigating to the "/" route, build the FirstScreen widget.
        '/': (context) => MainPage(title: 'Pangram', server: server),
        // When navigating to the "/second" route, build the SecondScreen widget.
        '/stats': (context) => StatsPage(),
      },
    );
  }
}

class FoundWords extends StatefulWidget {
  final List<String> foundWords;
  final Board board;
  FoundWords({Key? key, required this.foundWords, required this.board})
      : super(key: key);

  @override
  _FoundWordsState createState() => _FoundWordsState();
}

class _FoundWordsState extends State<FoundWords> {
  bool expanded = false;

  void _expansionChanged(bool newValue) {
    setState(() {
      expanded = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    String capitalize(String string) {
      return "${string[0].toUpperCase()}${string.substring(1)}";
    }

    widget.foundWords.sort(); // Does this sort the caller's list too?
    List<String> capitalizedWords = widget.foundWords.map(capitalize).toList();

    return ExpansionTileCard(
      title: expanded
          ? Text("Found")
          : Text(capitalizedWords.join(", "), overflow: TextOverflow.ellipsis),
      onExpansionChanged: _expansionChanged,
      subtitle: expanded
          ? null
          : Align(
              alignment: Alignment.bottomRight,
              child: Text(
                "${widget.foundWords.length} of ${widget.board.validWords.length}",
                style: TextStyle(fontSize: 10),
              ),
            ),
      children: <Widget>[
        Divider(thickness: 1.0, height: 1.0),
        SizedBox(
          height: 200,
          child: ListView(
            children: capitalizedWords
                .map((word) => ListTile(title: Text(word)))
                .toList(),
          ),
        )
      ],
    );
  }
}

class PangramGame extends StatefulWidget {
  final GameState game;
  final VoidCallback onWin;

  PangramGame({required this.game, required this.onWin})
      // Make the board Key so when the game changes State is dropped.
      : super(key: ObjectKey(game));

  @override
  _PangramGameState createState() => _PangramGameState();
}

class Breakdown extends StatelessWidget {
  final List<String> validWords;
  final List<String> foundWords;
  Breakdown({required this.validWords, required this.foundWords});

  @override
  Widget build(BuildContext context) {
    // Iterate over word lengths.  List X of X.
    Map<int, int> validCounts = <int, int>{};
    for (String word in validWords) {
      int count = validCounts[word.length] ?? 0;
      validCounts[word.length] = count + 1;
    }
    Map<int, int> foundCounts = <int, int>{};
    for (String word in foundWords) {
      int count = foundCounts[word.length] ?? 0;
      foundCounts[word.length] = count + 1;
    }

    List<int> lengths = validCounts.keys.toList();
    lengths.sort();

    return Column(
      children: [
        for (int length in lengths)
          Text(
              "$length : ${foundCounts[length] ?? 0} of ${validCounts[length]}")
      ],
    );
  }
}

class Difficulty extends StatelessWidget {
  final double? difficultyPercentile;
  Difficulty(this.difficultyPercentile);

  String difficultyText(double percentile) {
    if (percentile < 0.05) return "Very Easy";
    if (percentile < 0.15) return "Easy";
    if (percentile < 0.25) return "Medium";
    if (percentile < 0.50) return "Hard";
    return "Insane!";
  }

  @override
  Widget build(BuildContext context) {
    if (difficultyPercentile == null) return Text("Difficulty: Unknown");
    // FIXME: Why is this needed?  Null safety should see the early return above?
    double percentile = difficultyPercentile ?? 0.0;
    return Text(
        "Difficulty: ${difficultyText(percentile)} (${(100 * percentile).toInt()}%)");
  }
}

class Score extends StatelessWidget {
  final List<String> foundWords;
  Score({required this.foundWords});

  int computeScore(List<String> words) {
    return words.fold(0, (sum, word) => sum + Board.scoreForWord(word));
  }

  @override
  Widget build(BuildContext context) {
    return Text("Score: ${computeScore(foundWords)}");
  }
}

class Progress extends StatefulWidget {
  final List<String> validWords;
  final List<String> foundWords;
  Progress({required this.validWords, required this.foundWords});

  @override
  _ProgressState createState() => _ProgressState();
}

class _ProgressState extends State<Progress> {
  @override
  Widget build(BuildContext context) {
    return ExpansionTileCard(
      title: Score(foundWords: widget.foundWords),
      children: <Widget>[
        Divider(thickness: 1.0, height: 1.0),
        Breakdown(
          validWords: widget.validWords,
          foundWords: widget.foundWords,
        )
      ],
    );
  }
}

class _PangramGameState extends State<PangramGame> {
  String typedWord = "";
  List<int> otherLettersOrder = List<int>.generate(6, (i) => i);

  void typeLetter(String letter) {
    setState(() {
      typedWord += letter;
    });
  }

  void scramblePressed() {
    setState(() {
      otherLettersOrder.shuffle();
    });
  }

  void deletePressed() {
    setState(() {
      typedWord = typedWord.substring(0, typedWord.length - 1);
    });
  }

  String? _validateGuessedWord(String guessedWord) {
    if (guessedWord.length < 4) {
      return 'Words must be at least 4 letters.';
    }

    if (widget.game.foundWords.contains(guessedWord)) {
      return 'Already found "$guessedWord"';
    }

    if (!guessedWord.contains(widget.game.board.center)) {
      return '"$guessedWord" does not contain the center letter "${widget.game.board.center}"';
    }

    if (!widget.game.board.validWords.contains(guessedWord)) {
      return '"$guessedWord" is not a valid word';
    }
    return null;
  }

  // TODO: This likely belongs outside of this object.
  void enterPressed() {
    setState(() {
      var guessedWord = typedWord;
      typedWord = "";

      String? errorMessage = _validateGuessedWord(guessedWord);
      if (errorMessage != null) {
        final snackBar = SnackBar(content: Text(errorMessage));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return;
      }
      // TODO(eseidel): Having to manually call save here doesn't seem right.
      widget.game.foundWords.add(guessedWord);
      widget.game.save();
    });

    if (widget.game.foundWords.length == widget.game.board.validWords.length) {
      widget.onWin();
    }
  }

  List<String> scrambledOtherLetters() {
    List<String> otherLetters = widget.game.board.otherLetters;
    List<String> scrambledLetters = <String>[];
    for (int i = 0; i < otherLetters.length; i++) {
      scrambledLetters.add(otherLetters[otherLettersOrder[i]]);
    }
    return scrambledLetters;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // FIXME: This sized box is a hack to make things not expand too wide.
      width: 300,
      child: Column(
        children: [
          Difficulty(widget.game.board.difficultyPercentile),
          SizedBox(height: 10),
          // TODO(eseidel): SizedBox is a hack!
          Progress(
            validWords: widget.game.board.validWords,
            foundWords: widget.game.foundWords,
          ),
          SizedBox(height: 10),
          FoundWords(
            foundWords: widget.game.foundWords,
            board: widget.game.board,
          ),
          SizedBox(height: 20),
          Text(typedWord.toUpperCase()),
          SizedBox(height: 20),
          PangramButtons(
            center: widget.game.board.center,
            otherLetters: scrambledOtherLetters(),
            typeLetter: typeLetter,
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: typedWord == "" ? null : deletePressed,
                child: Text("DELETE"),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                  onPressed: scramblePressed, child: Text("SCRAMBLE")),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: typedWord == "" ? null : enterPressed,
                child: Text("ENTER"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key? key, this.title, required this.server}) : super(key: key);
  final String? title;
  final Server server;

  @override
  _MainPageState createState() => _MainPageState();
}

class Server {
  Manifest? _cachedManifest;
  static const String boardsDirectory = 'boards';

  Future<dynamic> _fetchJson(String url) async {
    print("Loading $url");
    http.Response response = await http.get(Uri.parse(url));
    return json.decode(response.body);
  }

  Future<Manifest> ensureManifest() async {
    if (_cachedManifest != null) return Future.value(_cachedManifest);
    var jsonManifest = await _fetchJson("$boardsDirectory/manifest.json");
    Manifest manifest = Manifest.fromJson(jsonManifest);
    _cachedManifest = manifest;
    return manifest;
  }

  Future<Board> nextBoard() async {
    Manifest manifest = await ensureManifest();
    int boardIndex = Random().nextInt(manifest.totalBoards);
    int chunkIndex = boardIndex ~/ manifest.chunkSize;
    String chunkName = manifest.chunkNameFromIndex(chunkIndex);
    List<dynamic> chunkJson = await _fetchJson("$boardsDirectory/$chunkName");
    List<Board> chunk =
        chunkJson.map((boardJson) => Board.fromJson(boardJson)).toList();
    int chunkLocalBoardIndex = boardIndex % manifest.chunkSize;
    return chunk[chunkLocalBoardIndex];
  }
}

class _MainPageState extends State<MainPage> {
  GameState? _game;

  // TODO: This belongs outside of this widget.
  @override
  void initState() {
    super.initState();
    initialLoad();
  }

  Future initialLoad() async {
    print("initialLoad");
    GameState? savedGame = await GameState.loadSaved();
    if (savedGame == null) {
      getNextBoard();
      return;
    }

    setState(() {
      _game = savedGame;
    });
  }

  Future getNextBoard() async {
    print("getNextBoard");
    Board board = await widget.server.nextBoard();
    if (!mounted) {
      return;
    }
    setState(() {
      GameState newGame = GameState(board);
      _game = newGame;
      newGame.save();
    });
  }

  void onWin() {
    if (_game == null) {
      return;
    }

    final snackBar = SnackBar(content: Text('A winner is you 🎉'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void onNextGame() {
    setState(() {
      _game = null;
    });
    getNextBoard();
  }

  @override
  Widget build(BuildContext context) {
    GameState? game = _game;
    var body = (game == null)
        ? Text("Loading...")
        : PangramGame(game: game, onWin: onWin);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            body,
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onNextGame,
        tooltip: 'New Game',
        child: Icon(Icons.refresh_outlined),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
