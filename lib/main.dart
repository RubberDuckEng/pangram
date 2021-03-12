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
  final List<String> wordsInOrderFound;
  final Board board;
  FoundWords({Key? key, required this.wordsInOrderFound, required this.board})
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

    List<String> capitalizedWords =
        widget.wordsInOrderFound.map(capitalize).toList();

    List<String> alphabeticalOrder = List.from(capitalizedWords);
    alphabeticalOrder.sort();

    return ExpansionTileCard(
      title: expanded
          ? Text("Found")
          : Text(capitalizedWords.reversed.join(", "),
              overflow: TextOverflow.ellipsis),
      onExpansionChanged: _expansionChanged,
      subtitle: expanded
          ? null
          : Align(
              alignment: Alignment.bottomRight,
              child: Text(
                "${widget.wordsInOrderFound.length} of ${widget.board.validWords.length}",
                style: TextStyle(fontSize: 10),
              ),
            ),
      children: <Widget>[
        Divider(thickness: 1.0, height: 1.0),
        SizedBox(
          height: 200,
          child: ListView(
            children: alphabeticalOrder
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
  final List<String> wordsInOrderFound;
  Breakdown({required this.validWords, required this.wordsInOrderFound});

  @override
  Widget build(BuildContext context) {
    // Iterate over word lengths.  List X of X.
    Map<int, int> validCounts = <int, int>{};
    for (String word in validWords) {
      int count = validCounts[word.length] ?? 0;
      validCounts[word.length] = count + 1;
    }
    Map<int, int> foundCounts = <int, int>{};
    for (String word in wordsInOrderFound) {
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
  final List<String> wordsInOrderFound;
  Score({required this.wordsInOrderFound});

  int computeScore(List<String> words) {
    return words.fold(0, (sum, word) => sum + Board.scoreForWord(word));
  }

  @override
  Widget build(BuildContext context) {
    return Text("Score: ${computeScore(wordsInOrderFound)}");
  }
}

class Progress extends StatefulWidget {
  final List<String> validWords;
  final List<String> wordsInOrderFound;
  Progress({required this.validWords, required this.wordsInOrderFound});

  @override
  _ProgressState createState() => _ProgressState();
}

class _ProgressState extends State<Progress> {
  @override
  Widget build(BuildContext context) {
    return ExpansionTileCard(
      title: Score(wordsInOrderFound: widget.wordsInOrderFound),
      children: <Widget>[
        Divider(thickness: 1.0, height: 1.0),
        Breakdown(
          validWords: widget.validWords,
          wordsInOrderFound: widget.wordsInOrderFound,
        )
      ],
    );
  }
}

class _PangramGameState extends State<PangramGame> {
  List<int> otherLettersOrder = List<int>.generate(6, (i) => i);

  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    textController.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    final String text = textController.text.toUpperCase();
    textController.value = textController.value.copyWith(
      text: text,
      selection:
          TextSelection(baseOffset: text.length, extentOffset: text.length),
      composing: TextRange.empty,
    );

    // TODO: Move the buttons into their own widgets that listen to the text controller.
    setState(() {});
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the widget tree.
    // This also removes the _printLatestValue listener.
    textController.dispose();
    super.dispose();
  }

  void _handleLetterPressed(String letter) {
    textController.text += letter;
  }

  void _handleScamble() {
    setState(() {
      otherLettersOrder.shuffle();
    });
  }

  void _handleDelete() {
    textController.text =
        textController.text.substring(0, textController.text.length - 1);
  }

  String? _validateGuessedWord(String guessedWord) {
    if (guessedWord.length < 4) {
      return 'Words must be at least 4 letters.';
    }

    if (widget.game.wordsInOrderFound.contains(guessedWord)) {
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
  void _handleEnter() {
    setState(() {
      var guessedWord = textController.text.toLowerCase();
      textController.text = "";

      String? errorMessage = _validateGuessedWord(guessedWord);
      if (errorMessage != null) {
        final snackBar = SnackBar(content: Text(errorMessage));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return;
      }
      widget.game.foundWord(guessedWord);
    });

    if (widget.game.haveWon) {
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
            wordsInOrderFound: widget.game.wordsInOrderFound,
          ),
          SizedBox(height: 10),
          FoundWords(
            wordsInOrderFound: widget.game.wordsInOrderFound,
            board: widget.game.board,
          ),
          SizedBox(height: 20),
          TextField(
            autofocus: true,
            controller: textController,
            onEditingComplete: _handleEnter,
          ),
          SizedBox(height: 20),
          PangramButtons(
            center: widget.game.board.center,
            otherLetters: scrambledOtherLetters(),
            typeLetter: _handleLetterPressed,
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: textController.text == "" ? null : _handleDelete,
                child: Text("DELETE"),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                  onPressed: _handleScamble, child: Text("SCRAMBLE")),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: (textController.text == "" || widget.game.haveWon)
                    ? null
                    : _handleEnter,
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
