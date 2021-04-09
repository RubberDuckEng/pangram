import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';

import 'pangram.dart';
import 'board.dart';
import 'game_state.dart';
import 'stats.dart';
import 'server.dart';
import 'router.dart';

void main() {
  final Server server = Server();
  runApp(PangramApp(server: server));
  // runApp(MyApp(server: server));
}

class UnknownPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text("UNKNOWN");
  }
}

class MainPage extends StatefulWidget {
  final Server server;
  MainPage({required this.server});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
    initialLoad();
  }

  Future initialLoad() async {
    Board board = await widget.server.nextBoard();
    if (!mounted) {
      return;
    }
    return Navigator.pushNamed(context, '/board/${board.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Text('LOADING');
  }
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
      onGenerateRoute: (settings) {
        String? name = settings.name;
        if (name != null) {
          if (name == '/') {
            return MaterialPageRoute(
                builder: (context) => MainPage(server: server));
          }
          if (name == '/stats') {
            return MaterialPageRoute(builder: (context) => StatsPage());
          }

          // Handle '/board/:id'
          var uri = Uri.parse(name);
          if (uri.pathSegments.length == 2 &&
              uri.pathSegments.first == 'board') {
            var id = uri.pathSegments[1];
            return MaterialPageRoute(
                builder: (context) => BoardPage(id: id, server: server));
          }
        }

        return MaterialPageRoute(builder: (context) => UnknownPage());
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

class BoardPage extends StatefulWidget {
  BoardPage({Key? key, required this.server, required this.id})
      : super(key: key);
  final Server server;
  final String id;

  @override
  _BoardPageState createState() => _BoardPageState();
}

enum BoardPageStatus {
  loading,
  playing,
  notFound,
}

class _BoardPageState extends State<BoardPage> {
  BoardPageStatus _status = BoardPageStatus.loading;
  GameState? _game;

  // TODO: This belongs outside of this widget.
  @override
  void initState() {
    super.initState();
    initialLoad();
  }

  Future initialLoad() async {
    print("BoardPage ${widget.id}");
    // if widget id
    // attempt to get that board.
    // If you got that board, load it, clear existing state.
    // If you failed to get that board, show as message, load new board?

    GameState? savedGame = await GameState.loadSaved();
    if (savedGame != null && savedGame.board.id == widget.id) {
      setState(() {
        _status = BoardPageStatus.playing;
        _game = savedGame;
      });
      return;
    }

    Board? board = await widget.server.getBoard(widget.id);
    if (board == null) {
      setState(() {
        _status = BoardPageStatus.notFound;
      });
      return;
    }

    GameState newGame = GameState(board);
    setState(() {
      _status = BoardPageStatus.playing;
      _game = newGame;
    });
    return newGame.save();
  }

  Future getNextBoard() async {
    Board board = await widget.server.nextBoard();
    if (!mounted) {
      return;
    }
    return Navigator.pushNamed(context, '/board/${board.id}');
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
      _status = BoardPageStatus.loading;
    });
    getNextBoard();
  }

  Widget getBody() {
    switch (_status) {
      case BoardPageStatus.loading:
        return Text("Status: Loading....");
      case BoardPageStatus.playing:
        {
          GameState? game = _game;
          if (game != null) return PangramGame(game: game, onWin: onWin);
          return Text("Error: null game object.");
        }
      case BoardPageStatus.notFound:
        return Text("Status: Not Found....");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pangram"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            getBody(),
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
