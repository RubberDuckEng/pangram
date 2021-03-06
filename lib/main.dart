import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pangram/manifest.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';

import 'board.dart';

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
      home: MainPage(title: 'Pangram', server: server),
    );
  }
}

class HexagonPainter extends CustomPainter {
  final Color color;
  Path? _lastDrawnPath;

  HexagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var radius = size.shortestSide / 2.0;
    var center = size.center(Offset.zero);

    const angleIncrement = pi / 3.0;
    const count = 6;
    List<Offset> points = [];
    for (int i = 0; i < count; ++i) {
      var angle = i * angleIncrement;
      points.add(center + Offset(cos(angle), sin(angle)) * radius);
    }

    var path = Path();
    path.addPolygon(points, true);
    var paint = Paint();
    paint.color = color;
    canvas.drawPath(path, paint);

    _lastDrawnPath = path;
  }

  @override
  bool? hitTest(Offset position) {
    return _lastDrawnPath?.contains(position);
  }

  @override
  bool shouldRepaint(covariant HexagonPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class PangramTile extends StatelessWidget {
  final String letter;
  final bool isCenter;
  final ValueChanged<String> onPressed;

  PangramTile(
      {Key? key,
      required this.letter,
      required this.onPressed,
      required this.isCenter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color =
        isCenter ? Colors.deepOrange.shade500 : Colors.yellow.shade800;
    return GestureDetector(
      onTap: () {
        onPressed(letter);
      },
      child: Stack(alignment: AlignmentDirectional.center, children: [
        SizedBox(
          height: 75.0,
          width: 75.0,
          child: CustomPaint(painter: HexagonPainter(color: color)),
        ),
        Text(letter.toUpperCase(), style: TextStyle(fontSize: 24)),
      ]),
    );
  }
}

enum _PangramSlot {
  center,
  first,
  second,
  third,
  fourth,
  fifth,
  sixth,
}

class PangramLayout extends MultiChildLayoutDelegate {
  @override
  void performLayout(Size size) {
    var centerSize =
        layoutChild(_PangramSlot.center, BoxConstraints.loose(size));
    positionChild(_PangramSlot.center,
        size.center(Offset.zero) - centerSize.center(Offset.zero));

    var radius = size.shortestSide / 3.0;
    const angleIncrement = pi / 3.0;
    const satelliteCount = 6;
    for (int i = 0; i < satelliteCount; ++i) {
      var slot = _PangramSlot.values[i + 1]; // The center slot is index 0.
      var satelliteSize = layoutChild(slot, BoxConstraints.loose(size));
      var angle = i * angleIncrement + pi / 6.0;
      var satelliteOffset = size.center(Offset.zero) +
          Offset(cos(angle), sin(angle)) * radius -
          satelliteSize.center(Offset.zero);
      positionChild(slot, satelliteOffset);
    }
  }

  Size getSize(BoxConstraints constraints) => Size(200, 200);

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) => false;
}

class FoundWords extends StatelessWidget {
  final List<String> foundWords;
  final Board board;
  FoundWords({Key? key, required this.foundWords, required this.board})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String capitalize(String string) {
      return "${string[0].toUpperCase()}${string.substring(1)}";
    }

    foundWords.sort(); // Does this sort the caller's list too?

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.lightBlue.shade200,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      constraints: BoxConstraints(minWidth: 200, minHeight: 100),
      child: Text(
          "Found ${foundWords.length} of ${board.validWords.length}:\n${foundWords.map(capitalize).join('\n')}"),
    );
  }
}

class PangramGame extends StatefulWidget {
  final Board board;
  final VoidCallback onWin;

  PangramGame({required this.board, required this.onWin})
      // Make the board Key so when the board changes State is dropped.
      : super(key: ObjectKey(board));

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

  int scoreForWord(String word) {
    // Quoting http://varianceexplained.org/r/honeycomb-puzzle/
    // Four-letter words are worth 1 point each, while five-letter words are
    // worth 5 points, six-letter words are worth 6 points, seven-letter words
    // are worth 7 points, etc. Words that use all of the seven letters in the
    // honeycomb are known as “pangrams” and earn 7 bonus points (in addition
    // to the points for the length of the word). So in the above example,
    // MEGAPLEX is worth 15 points.

    int length = word.length;
    if (length < 4) {
      throw ArgumentError("Only know how to score words above 4 letters");
    }

    if (length == 4) return 1;
    int uniqueLetterCount = Set.from(word.split('')).length;
    // Assuming reasonable inputs (not checking for > 7).
    int pangramBonus = (uniqueLetterCount == 7) ? 7 : 0;
    return pangramBonus + length;
  }

  int computeScore(List<String> words) {
    return words.fold(0, (sum, word) => sum + scoreForWord(word));
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

  // TODO: This is really business logic state rather than UI state.
  List<String> foundWords = <String>[];

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
    if (foundWords.contains(guessedWord)) {
      return 'Already found "$guessedWord"';
    }

    if (!guessedWord.contains(widget.board.center)) {
      return '"$guessedWord" does not contain the center letter "${widget.board.center}"';
    }

    if (!widget.board.validWords.contains(guessedWord)) {
      return '"$guessedWord" is not a valid word';
    }
    return null;
  }

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
      foundWords.add(guessedWord);
    });

    if (foundWords.length == widget.board.validWords.length) {
      widget.onWin();
    }
  }

  @override
  Widget build(BuildContext context) {
    var children = [
      LayoutId(
          id: _PangramSlot.center,
          child: PangramTile(
            letter: widget.board.center,
            onPressed: typeLetter,
            isCenter: true,
          ))
    ];
    for (var i = 0; i < widget.board.otherLetters.length; ++i) {
      var letter = widget.board.otherLetters[otherLettersOrder[i]];
      children.add(LayoutId(
          id: _PangramSlot.values[i + 1],
          child: PangramTile(
            letter: letter,
            onPressed: typeLetter,
            isCenter: false,
          )));
    }
    return SizedBox(
      // FIXME: This sized box is a hack to make things not expand too wide.
      width: 300,
      child: Column(
        children: [
          Difficulty(widget.board.difficultyPercentile),
          SizedBox(height: 10),
          // TODO(eseidel): SizedBox is a hack!
          Progress(validWords: widget.board.validWords, foundWords: foundWords),
          SizedBox(height: 10),
          FoundWords(foundWords: foundWords, board: widget.board),
          SizedBox(height: 20),
          Text(typedWord.toUpperCase()),
          SizedBox(height: 20),
          CustomMultiChildLayout(delegate: PangramLayout(), children: children),
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
  Board? _board;

  // TODO: This belongs outside of this widget.
  @override
  void initState() {
    super.initState();
    getNextBoard();
  }

  Future getNextBoard() async {
    Board board = await widget.server.nextBoard();
    if (!mounted) {
      return;
    }
    setState(() {
      _board = board;
    });
  }

  void onWin() {
    if (_board == null) {
      return;
    }

    final snackBar = SnackBar(content: Text('A winner is you 🎉'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    setState(() {
      _board = null;
    });
    getNextBoard();
  }

  void onNextGame() {
    if (_board == null) {
      return;
    }

    setState(() {
      _board = null;
    });
    getNextBoard();
  }

  @override
  Widget build(BuildContext context) {
    Board? board = _board;
    var body = (board == null)
        ? Text("Loading...")
        : PangramGame(board: board, onWin: onWin);

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
